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
end
