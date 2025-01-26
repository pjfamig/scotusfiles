# app/services/message_creator.rb

class MessageCreator
  def initialize(params: [])
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:openai, :access_token))
    @params = params
  end

  def call
    send_request
  end

  private

  def send_request
    response = @client.chat(parameters: default_parameters)

    # Log the full response for debugging
    Rails.logger.info("OpenAI Response: #{response}")

    if response['error']
      raise "OpenAI API Error: #{response['error']['message']}"
    end

    # Extract the message content from the response
    response.dig('choices', 0, 'message', 'content')
  rescue Faraday::Error => e
    Rails.logger.error("API Request Error: #{e.message}")
    raise "API Request Failed: #{e.message}"
  end

  def default_parameters
    {
      model: 'gpt-4o-mini',
      messages: [
        {
          role: 'system',
          content: 'You are a helpful assistant.'
        },
        {
          role: 'user',
          content: "Write a brief two or three-sentence summary of the Supreme Court decision #{@params}."
        }
      ]
    }
  end
end