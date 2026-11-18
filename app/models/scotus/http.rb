require "net/http"

module Scotus::Http
  USER_AGENT = "SCOTUSfiles (+https://www.scotusfiles.com)".freeze
  MAX_REDIRECTS = 3
  ATTEMPTS = 3
  # supremecourt.gov sometimes drops connections mid-download; these are worth retrying.
  NETWORK_ERRORS = [ IOError, SocketError, SystemCallError, Timeout::Error, OpenSSL::SSL::SSLError, Net::ProtocolError ].freeze

  class Error < StandardError; end

  def self.get(url, redirects: MAX_REDIRECTS)
    response = fetch(URI(url))

    case response
    when Net::HTTPSuccess then response.body
    when Net::HTTPRedirection
      raise Error, "Too many redirects for #{url}" if redirects.zero?
      get(URI.join(url, response["location"]).to_s, redirects: redirects - 1)
    else
      raise Error, "GET #{url} returned #{response.code}"
    end
  end

  def self.fetch(uri, attempt: 1)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 60) do |http|
      http.get(uri.request_uri, "User-Agent" => USER_AGENT)
    end
  rescue *NETWORK_ERRORS => error
    raise Error, "GET #{uri} failed: #{error.message} (#{error.class})" if attempt >= ATTEMPTS

    sleep retry_delay(attempt)
    fetch(uri, attempt: attempt + 1)
  end
  private_class_method :fetch

  def self.retry_delay(attempt) = attempt * 2
end
