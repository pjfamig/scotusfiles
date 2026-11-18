class HoldingAlertMailer < ApplicationMailer
  def alert
    @user, @decision = params.values_at(:user, :decision)
    token = @user.generate_token_for(:holding_alerts)
    @preferences_url = holding_alert_url(token)

    # Lets mail clients show their own unsubscribe button (RFC 8058).
    headers["List-Unsubscribe"] = "<#{holding_alert_url(token, subscribed: false)}>"
    headers["List-Unsubscribe-Post"] = "List-Unsubscribe=One-Click"

    mail to: @user.email_address, subject: "Holding alert! #{@decision.title}"
  end
end
