require "net/http"

module Scotus::Http
  USER_AGENT = "SCOTUSfiles (+https://www.scotusfiles.com)".freeze
  MAX_REDIRECTS = 3

  class Error < StandardError; end

  def self.get(url, redirects: MAX_REDIRECTS)
    uri = URI(url)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 60) do |http|
      http.get(uri.request_uri, "User-Agent" => USER_AGENT)
    end

    case response
    when Net::HTTPSuccess then response.body
    when Net::HTTPRedirection
      raise Error, "Too many redirects for #{url}" if redirects.zero?
      get(URI.join(url, response["location"]).to_s, redirects: redirects - 1)
    else
      raise Error, "GET #{url} returned #{response.code}"
    end
  end
end
