require "test_helper"

class Scotus::HttpTest < ActiveSupport::TestCase
  setup do
    @start = Net::HTTP.method(:start)
    @retry_delay = Scotus::Http.method(:retry_delay)
    Scotus::Http.define_singleton_method(:retry_delay) { |_attempt| 0 }
  end

  teardown do
    Net::HTTP.define_singleton_method(:start, @start)
    Scotus::Http.define_singleton_method(:retry_delay, @retry_delay)
  end

  test "retries a dropped connection" do
    responses = [ Errno::ECONNRESET, success("%PDF") ]
    Net::HTTP.define_singleton_method(:start) { |*, **| (response = responses.shift).is_a?(Class) ? raise(response) : response }

    assert_equal "%PDF", Scotus::Http.get("https://www.supremecourt.gov/opinions/a.pdf")
  end

  test "gives up as a Scotus::Http::Error so callers can skip or retry the import" do
    attempts = 0
    Net::HTTP.define_singleton_method(:start) { |*, **| attempts += 1; raise Errno::ECONNRESET, "SSL_read" }

    error = assert_raises(Scotus::Http::Error) { Scotus::Http.get("https://www.supremecourt.gov/opinions/a.pdf") }
    assert_match(/Connection reset by peer/, error.message)
    assert_equal Scotus::Http::ATTEMPTS, attempts
  end

  private
    def success(body)
      Net::HTTPOK.new("1.1", "200", "OK").tap do |response|
        response.instance_variable_set(:@body, body)
        response.instance_variable_set(:@read, true)
      end
    end
end
