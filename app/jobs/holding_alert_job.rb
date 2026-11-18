class HoldingAlertJob < ApplicationJob
  queue_as :default

  def perform(decision)
    decision.send_holding_alerts
  end
end
