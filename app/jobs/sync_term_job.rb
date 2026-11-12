class SyncTermJob < ApplicationJob
  queue_as :default
  retry_on Scotus::Http::Error, wait: :polynomially_longer, attempts: 3

  def perform(term = Scotus::SlipOpinionIndex.current_term)
    Decision.sync_term(term)
  end
end
