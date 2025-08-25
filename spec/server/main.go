
package main

import (
	"bytes"
	"compress/gzip"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"net/textproto"
	"net/url"
	"os"
	"os/signal"
	"strconv"
	"strings"
	"sync"
	"syscall"
	"time"
)

const readyMsg = "Server ready"

var (
	failCountMu sync.Mutex
	failCount   int
)

func main() {
	port := getenv("PORT", "3001")
	verbose := os.Getenv("VERBOSE_SERVER") != ""

	mux := http.NewServeMux()

	// health
	mux.HandleFunc("/__identify__", func(w http.ResponseWriter, r *http.Request) {
		writeText(w, http.StatusOK, readyMsg)
	})

	// multipart file echo
	mux.HandleFunc("/file", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.NotFound(w, r)
			return
		}
		if err := r.ParseMultipartForm(64 << 20); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		f, fh, err := r.FormFile("file")
		if err != nil {
			http.Error(w, "missing multipart field 'file'", http.StatusBadRequest)
			return
		}
		defer f.Close()
		content, _ := io.ReadAll(f)
		ct := contentTypeFromMultipartHeader(fh.Header)
		resp := map[string]any{
			"content-type":         ct,
			"filename":             fh.Filename,
			"content":              string(content),
			"request-content-type": r.Header.Get("Content-Type"),
		}
		writeJSON(w, http.StatusOK, resp)
	})

	// multiple headers
	mux.HandleFunc("/multiple-headers", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Add("Set-Cookie", "foo")
		w.Header().Add("Set-Cookie", "bar")
		w.Header().Set("Content-Type", "text/plain")
		w.WriteHeader(http.StatusOK)
	})

	// fail/:number
	mux.HandleFunc("/fail/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.NotFound(w, r)
			return
		}
		numberStr := strings.TrimPrefix(r.URL.Path, "/fail/")
		n, _ := strconv.Atoi(numberStr)

		failCountMu.Lock()
		defer failCountMu.Unlock()
		if failCount >= n {
			writeText(w, http.StatusOK, "ok")
			return
		}
		failCount++
		http.Error(w, "oh noes!", http.StatusInternalServerError)
	})

	// fail_forever
	mux.HandleFunc("/fail_forever", func(w http.ResponseWriter, r *http.Request) {
		http.Error(w, "oh noes!", http.StatusInternalServerError)
	})

	// redirects
	mux.HandleFunc("/redirect", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/", http.StatusFound) // 302
	})
	mux.HandleFunc("/bad_redirect", func(w http.ResponseWriter, r *http.Request) {
		http.Redirect(w, r, "/bad_redirect", http.StatusFound)
	})

	// basic auth path: /auth_basic/:username/:password
	mux.HandleFunc("/auth_basic/", func(w http.ResponseWriter, r *http.Request) {
		pathPart := strings.TrimPrefix(r.URL.Path, "/auth_basic/")
		// Split only on the first slash to get username and password parts
		parts := strings.SplitN(pathPart, "/", 2)
		if len(parts) != 2 {
			http.NotFound(w, r)
			return
		}
		// URL decode the username and password from the path
		wantU, err1 := url.QueryUnescape(parts[0])
		wantP, err2 := url.QueryUnescape(parts[1])
		if err1 != nil || err2 != nil {
			http.NotFound(w, r)
			return
		}
		u, p, ok := r.BasicAuth()
		if ok && u == wantU && p == wantP {
			writeText(w, http.StatusOK, "ok")
			return
		}
		w.Header().Set("WWW-Authenticate", `Basic realm="Testing HTTP Auth"`)
		http.Error(w, "Not authorized", http.StatusUnauthorized)
	})

	// ntlm “presence” check
	mux.HandleFunc("/auth_ntlm", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("WWW-Authenticate", "NTLM")
		if strings.HasPrefix(r.Header.Get("Authorization"), "NTLM") {
			writeText(w, http.StatusOK, "ok")
			return
		}
		http.Error(w, "Not authorized", http.StatusUnauthorized)
	})

	// gzipped
	mux.HandleFunc("/gzipped", func(w http.ResponseWriter, r *http.Request) {
		body := echoEnvJSON(r, true)
		// Compress
		var b strings.Builder
		gz := gzip.NewWriter(&b)
		_, _ = gz.Write([]byte(body))
		_ = gz.Close()
		out := b.String()

		w.Header().Set("Content-Encoding", "gzip")
		w.Header().Set("Content-Type", "application/json")
		w.Header().Set("Content-Length", strconv.Itoa(len(out)))
		w.WriteHeader(http.StatusOK)
		_, _ = io.WriteString(w, out)
	})

	// catch-alls for /** (GET/HEAD/PUT/POST/DELETE/PATCH/OPTIONS/PURGE)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		applyDelay(r)

		switch r.Method {
		case http.MethodHead:
			// Return headers only (empty body)
			js := echoEnvJSON(r, false)
			w.Header().Set("Content-Type", "application/json")
			w.Header().Set("Content-Length", strconv.Itoa(len(js)))
			w.WriteHeader(http.StatusOK)
			return

		case http.MethodGet, http.MethodPost, http.MethodPut, http.MethodDelete, http.MethodPatch, http.MethodOptions:
			respMap := envMap(r)
			body, _ := io.ReadAll(r.Body)
			_ = r.Body.Close()
			respMap["body"] = string(body)
			
			// Handle multipart forms to extract filename
			if isMultipartForm(r.Header.Get("Content-Type")) {
				if filename := extractFilenameFromMultipart(string(body), r.Header.Get("Content-Type")); filename != "" {
					respMap["filename"] = filename
				}
			} else if isFormURLEncoded(r.Header.Get("Content-Type")) {
				// For urlencoded, include rack-like parsed form hash
				formHash := parseFormLikeRack(string(body))
				if formHash != nil {
					respMap["rack.request.form_hash"] = formHash
				}
			}
			writeJSON(w, http.StatusOK, respMap)

		default:
			// Support custom PURGE verb
			if r.Method == "PURGE" {
				respMap := envMap(r)
				// rack does rewind; replicate by reading whole body
				b, _ := io.ReadAll(r.Body)
				_ = r.Body.Close()
				respMap["body"] = string(b)
				
				// Handle multipart forms to extract filename  
				if isMultipartForm(r.Header.Get("Content-Type")) {
					if filename := extractFilenameFromMultipart(string(b), r.Header.Get("Content-Type")); filename != "" {
						respMap["filename"] = filename
					}
				} else if isFormURLEncoded(r.Header.Get("Content-Type")) {
					formHash := parseFormLikeRack(string(b))
					if formHash != nil {
						respMap["rack.request.form_hash"] = formHash
					}
				}
				writeJSON(w, http.StatusOK, respMap)
				return
			}
			http.NotFound(w, r)
		}
	})

	srv := &http.Server{
		Addr:              ":" + port,
		Handler:           logMiddleware(mux, verbose),
		ReadHeaderTimeout: 10 * time.Second,
	}

	// graceful shutdown
	idle := make(chan struct{})
	go func() {
		c := make(chan os.Signal, 1)
		signal.Notify(c, syscall.SIGINT, syscall.SIGTERM)
		<-c
		ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
		defer cancel()
		_ = srv.Shutdown(ctx)
		close(idle)
	}()

	log.Printf("ethon-test-server listening on :%s\n", port)
	if err := srv.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		log.Fatal(err)
	}
	<-idle
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func logMiddleware(next http.Handler, verbose bool) http.Handler {
	if !verbose {
		return next
	}
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		log.Printf("%s %s %s", r.RemoteAddr, r.Method, r.URL.String())
		next.ServeHTTP(w, r)
	})
}

func writeText(w http.ResponseWriter, code int, s string) {
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	w.Header().Set("Content-Length", strconv.Itoa(len(s)))
	w.WriteHeader(code)
	_, _ = io.WriteString(w, s)
}

func writeJSON(w http.ResponseWriter, code int, v any) {
	// Use custom encoder to avoid escaping &, <, > like Ruby does
	var buf bytes.Buffer
	encoder := json.NewEncoder(&buf)
	encoder.SetEscapeHTML(false)
	_ = encoder.Encode(v)
	b := bytes.TrimRight(buf.Bytes(), "\n") // Remove trailing newline from encoder
	
	w.Header().Set("Content-Type", "application/json")
	w.Header().Set("Content-Length", strconv.Itoa(len(b)))
	w.WriteHeader(code)
	_, _ = w.Write(b)
}

func scheme(r *http.Request) string {
	if r.TLS != nil {
		return "https"
	}
	// libcurl hits us over http in tests
	return "http"
}

func envMap(r *http.Request) map[string]any {
	m := map[string]any{
		"REQUEST_METHOD": r.Method,
		"REQUEST_URI":    fmt.Sprintf("%s://%s%s", scheme(r), r.Host, r.URL.RequestURI()),
	}
	if ct := r.Header.Get("Content-Type"); ct != "" {
		m["CONTENT_TYPE"] = ct
	}
	// Rack-style HTTP_* headers
	for k, vv := range r.Header {
		hk := "HTTP_" + strings.ToUpper(strings.ReplaceAll(k, "-", "_"))
		m[hk] = strings.Join(vv, ", ")
	}
	return m
}

func echoEnvJSON(r *http.Request, includeBody bool) string {
	m := envMap(r)
	if includeBody {
		b, _ := io.ReadAll(r.Body)
		_ = r.Body.Close()
		m["body"] = string(b)
		if isFormURLEncoded(r.Header.Get("Content-Type")) {
			formHash := parseFormLikeRack(string(b))
			if formHash != nil {
				m["rack.request.form_hash"] = formHash
			}
		}
	}
	b, _ := json.Marshal(m)
	return string(b)
}

func isFormURLEncoded(ct string) bool {
	ct = strings.ToLower(ct)
	return strings.HasPrefix(ct, "application/x-www-form-urlencoded")
}

func isMultipartForm(ct string) bool {
	ct = strings.ToLower(ct)
	return strings.HasPrefix(ct, "multipart/form-data")
}

func extractFilenameFromMultipart(body, contentType string) string {
	// Simple parsing to find filename
	bodyLines := strings.Split(body, "\r\n")
	for _, line := range bodyLines {
		if strings.Contains(line, "Content-Disposition:") && strings.Contains(line, "filename=") {
			// Extract filename from: Content-Disposition: form-data; name="file"; filename="custom_spec.rb"
			parts := strings.Split(line, "filename=")
			if len(parts) >= 2 {
				filename := strings.Trim(parts[1], `"`)
				// Remove any trailing parameters
				if idx := strings.Index(filename, `"`); idx > 0 {
					filename = filename[:idx]
				}
				return filename
			}
		}
	}
	return ""
}

func parseFormLikeRack(body string) map[string]any {
	// We can’t rely on r.ParseForm() after reading; emulate minimally:
	// split on &, decode keys/values.
	if body == "" {
		return nil
	}
	out := map[string]any{}
	pairs := strings.Split(body, "&")
	for _, p := range pairs {
		if p == "" {
			continue
		}
		kv := strings.SplitN(p, "=", 2)
		k := urlDecode(kv[0])
		v := ""
		if len(kv) == 2 {
			v = urlDecode(kv[1])
		}
		// For tests we map single key to string (not array)
		// If the key repeats we’ll overwrite; that’s fine for this suite
		out[k] = v
	}
	return out
}

func applyDelay(r *http.Request) {
	if delayStr := r.URL.Query().Get("delay"); delayStr != "" {
		if delay, err := strconv.Atoi(delayStr); err == nil && delay > 0 {
			time.Sleep(time.Duration(delay) * time.Second)
		}
	}
}

func urlDecode(s string) string {
	// net/url is overkill; quick decode of + and %.. (enough for tests)
	s = strings.ReplaceAll(s, "+", " ")
	// Percent decoding
	for {
		i := strings.IndexByte(s, '%')
		if i < 0 || i+2 >= len(s) {
			break
		}
		h := s[i+1 : i+3]
		b, err := strconv.ParseUint(h, 16, 8)
		if err != nil {
			break
		}
		s = s[:i] + string(byte(b)) + s[i+3:]
	}
	return s
}

func contentTypeFromMultipartHeader(h textproto.MIMEHeader) string {
	// Prefer explicit content-type of the part
	if ct := h.Get("Content-Type"); ct != "" {
		return ct
	}
	// Best-effort
	return "application/octet-stream"
}
