# frozen_string_literal: true
require 'digest'
require 'json'
require 'zlib'
require 'sinatra/base'

TESTSERVER = Sinatra.new do
  use Rack::RewindableInput::Middleware if defined?(Rack::RewindableInput::Middleware)

  set :logging, nil
  disable :protection
  # Test server: don't spend time logging host authorization on every request.
  set :host_authorization, { :permitted_hosts => [] }

  fail_count = 0

  def read_request_body
    body = request.body
    # Sinatra parses some methods' bodies before the route runs. Rewind so the
    # tests can assert on the body that was actually sent.
    body.rewind if body.respond_to?(:rewind)
    body.read
  end

  post '/file' do
    {
      'content-type' => params[:file][:type],
      'filename' => params[:file][:filename],
      'content' => params[:file][:tempfile].read,
      'request-content-type' => request.env['CONTENT_TYPE']
    }.to_json
  end

  put '/file' do
    {
      'field' => params[:field],
      'filename' => params[:file][:filename],
      'content' => params[:file][:tempfile].read,
      'request-content-type' => request.env['CONTENT_TYPE']
    }.to_json
  end

  get '/multiple-headers' do
    [200, { 'Set-Cookie' => %w[ foo bar ], 'Content-Type' => 'text/plain' }, ['']]
  end

  # Deterministic binary payload for byte-exact transfer tests.
  get '/binary/:size' do
    size = params[:size].to_i
    pattern = (0..255).to_a.pack("C*")
    body = (pattern * (size / pattern.bytesize + 1)).byteslice(0, size)

    content_type 'application/octet-stream'
    body
  end

  # Echo the raw request body so uploads can be compared byte for byte.
  post '/echo' do
    body = read_request_body.b

    content_type 'application/octet-stream'
    body
  end

  put '/echo' do
    body = read_request_body.b

    content_type 'application/octet-stream'
    body
  end

  post '/multipart' do
    content_type 'application/json'

    result = {}
    params.each do |key, value|
      if value.is_a?(Hash) && value[:tempfile]
        value[:tempfile].rewind
        content = value[:tempfile].read
        result[key] = {
          'filename' => value[:filename],
          'size' => content.bytesize,
          'sha256' => Digest::SHA256.hexdigest(content)
        }
      else
        result[key] = value
      end
    end
    result.to_json
  end

  get '/fail/:number' do
    if fail_count >= params[:number].to_i
      "ok"
    else
      fail_count += 1
      error 500, "oh noes!"
    end
  end

  get '/fail_forever' do
    error 500, "oh noes!"
  end

  get '/redirect' do
    redirect '/'
  end

  post '/redirect' do
    redirect '/'
  end

  get '/bad_redirect' do
    redirect '/bad_redirect'
  end

  get '/auth_basic/:username/:password' do
    @auth ||=  Rack::Auth::Basic::Request.new(request.env)
    # Check that we've got a basic auth, and that it's credentials match the ones
    # provided in the request
    if @auth.provided? && @auth.basic? && @auth.credentials == [ params[:username], params[:password] ]
      # auth is valid - confirm it
      true
    else
      # invalid auth - request the authentication
      response['WWW-Authenticate'] = %(Basic realm="Testing HTTP Auth")
      throw(:halt, [401, "Not authorized\n"])
    end
  end

  get '/auth_ntlm' do
    # we're just checking for the existence if NTLM auth header here. It's validation
    # is too troublesome and really doesn't bother is much, it's up to libcurl to make
    # it valid
    response['WWW-Authenticate'] = 'NTLM'
    is_ntlm_auth = /^NTLM/ =~ request.env['HTTP_AUTHORIZATION']
    true if is_ntlm_auth
    throw(:halt, [401, "Not authorized\n"]) if !is_ntlm_auth
  end

  get '/gzipped' do
    req_env = request.env.to_json
    z = Zlib::Deflate.new
    gzipped_env = z.deflate(req_env, Zlib::FINISH)
    z.close
    response['Content-Encoding'] = 'gzip'
    gzipped_env
  end

  get '/**' do
    sleep params["delay"].to_f if params.has_key?("delay")
    request.env.merge!(:body => read_request_body).to_json
  end

  head '/**' do
    sleep params["delay"].to_f if params.has_key?("delay")
  end

  put '/**' do
    request.env.merge!(:body => read_request_body).to_json
  end

  post '/**' do
    request.env.merge!(:body => read_request_body).to_json
  end

  delete '/**' do
    request.env.merge!(:body => read_request_body).to_json
  end

  patch '/**' do
    request.env.merge!(:body => read_request_body).to_json
  end

  options '/**' do
    request.env.merge!(:body => read_request_body).to_json
  end

  route 'PURGE', '/**' do
    request.env.merge!(:body => read_request_body).to_json
  end
end
