class ImportDecisionJob < ApplicationJob
  queue_as :default
  limits_concurrency to: 1, key: ->(decision) { decision }
  retry_on Scotus::Http::Error, wait: :polynomially_longer, attempts: 5
  discard_on Scotus::PdfLayout::ConversionError

  def perform(decision)
    decision.import!
  end
end
