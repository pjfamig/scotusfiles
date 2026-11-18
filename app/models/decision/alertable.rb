module Decision::Alertable
  extend ActiveSupport::Concern

  # Only cases decided this recently are news; backfilling an older term
  # shouldn't email everyone about every case in it.
  ALERT_WINDOW = 1.week

  SUMMARY_SENTENCES = 3
  # A sentence ends after a lowercase word or a digit, so "U. S." and initials don't split.
  SENTENCE_BOUNDARY = /(?<=[a-z0-9)”"][.?!])\s+(?=[A-Z“"])/

  class_methods do
    # Off in production until email delivery is configured, so decisions
    # aren't marked alerted while their emails have nowhere to go.
    def holding_alerts_enabled? = Rails.configuration.x.holding_alerts_enabled
  end

  def alert_later
    HoldingAlertJob.perform_later(self) if alertable?
  end

  def send_holding_alerts
    return unless Decision.holding_alerts_enabled? && claim_holding_alert

    User.holding_alert_subscribers.find_each do |user|
      HoldingAlertMailer.with(user: user, decision: self).alert.deliver_later
    end
  end

  def holding_summary
    holding.to_s.squish.split(SENTENCE_BOUNDARY).first(SUMMARY_SENTENCES).join(" ").presence
  end

  private
    def alertable?
      Decision.holding_alerts_enabled? && holding_alert_sent_at.nil? && decided_on.present? && decided_on >= ALERT_WINDOW.ago.to_date
    end

    # Retries and overlapping imports may both get here; only one claims the send.
    def claim_holding_alert
      Decision.where(id: id, holding_alert_sent_at: nil).update_all(holding_alert_sent_at: Time.current) == 1
    end
end
