# Preview all emails at http://localhost:3000/rails/mailers/holding_alert_mailer
class HoldingAlertMailerPreview < ActionMailer::Preview
  # Preview this email at http://localhost:3000/rails/mailers/holding_alert_mailer/alert
  def alert
    HoldingAlertMailer.with(user: User.take, decision: Decision.latest_first.where.not(holding: nil).take).alert
  end
end
