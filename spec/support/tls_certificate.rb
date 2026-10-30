# frozen_string_literal: true
require 'openssl'

# Generates self-signed certificate material for the TLS test server.
module TLSCertificate
  module_function

  def generate(common_name)
    key = OpenSSL::PKey::RSA.new(2048)
    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = 1
    certificate.subject = OpenSSL::X509::Name.parse("/CN=#{common_name}")
    certificate.issuer = certificate.subject
    certificate.public_key = key.public_key
    certificate.not_before = Time.now - 60
    certificate.not_after = Time.now + 3600

    extensions = OpenSSL::X509::ExtensionFactory.new
    extensions.subject_certificate = certificate
    extensions.issuer_certificate = certificate
    certificate.add_extension(
      extensions.create_extension("basicConstraints", "CA:TRUE", true)
    )
    certificate.add_extension(
      extensions.create_extension("keyUsage", "keyCertSign,digitalSignature,keyEncipherment", true)
    )
    certificate.add_extension(
      extensions.create_extension("subjectAltName", "DNS:#{common_name}", false)
    )
    certificate.sign(key, OpenSSL::Digest.new("SHA256"))

    [certificate, key]
  end

  # Generates a CA certificate that can sign server and client certificates.
  def generate_ca(common_name)
    key = OpenSSL::PKey::RSA.new(2048)
    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = 1
    certificate.subject = OpenSSL::X509::Name.parse("/CN=#{common_name}")
    certificate.issuer = certificate.subject
    certificate.public_key = key.public_key
    certificate.not_before = Time.now - 60
    certificate.not_after = Time.now + 3600

    extensions = OpenSSL::X509::ExtensionFactory.new
    extensions.subject_certificate = certificate
    extensions.issuer_certificate = certificate
    certificate.add_extension(
      extensions.create_extension("basicConstraints", "CA:TRUE", true)
    )
    certificate.add_extension(
      extensions.create_extension("keyUsage", "keyCertSign,cRLSign", true)
    )
    certificate.sign(key, OpenSSL::Digest.new("SHA256"))

    [certificate, key]
  end

  # Signs a leaf certificate for the given usage with a CA certificate.
  def sign(common_name, issuer_certificate, issuer_key, usage:, subject_alt_name: nil)
    key = OpenSSL::PKey::RSA.new(2048)
    certificate = OpenSSL::X509::Certificate.new
    certificate.version = 2
    certificate.serial = 2
    certificate.subject = OpenSSL::X509::Name.parse("/CN=#{common_name}")
    certificate.issuer = issuer_certificate.subject
    certificate.public_key = key.public_key
    certificate.not_before = Time.now - 60
    certificate.not_after = Time.now + 3600

    extensions = OpenSSL::X509::ExtensionFactory.new
    extensions.subject_certificate = certificate
    extensions.issuer_certificate = issuer_certificate
    certificate.add_extension(
      extensions.create_extension("basicConstraints", "CA:FALSE", true)
    )
    certificate.add_extension(
      extensions.create_extension("keyUsage", "digitalSignature,keyEncipherment", true)
    )
    certificate.add_extension(
      extensions.create_extension("extendedKeyUsage", usage, false)
    )
    if subject_alt_name
      certificate.add_extension(
        extensions.create_extension("subjectAltName", subject_alt_name, false)
      )
    end
    certificate.sign(issuer_key, OpenSSL::Digest.new("SHA256"))

    [certificate, key]
  end
end
