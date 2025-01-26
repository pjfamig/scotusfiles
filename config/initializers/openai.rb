# config/initializers/openai.rb

OpenAI.configure do |config|
  config.access_token = Rails.application.credentials.dig(:openai, :access_token)
end