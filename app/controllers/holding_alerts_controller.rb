class HoldingAlertsController < ApplicationController
  allow_unauthenticated_access
  # One-click unsubscribes come from mail clients without a CSRF token; the signed token in the URL authorizes them.
  skip_forgery_protection only: :update
  before_action :set_user

  def show
    response.headers["X-Robots-Tag"] = "noindex"
  end

  def update
    @user.update!(holding_alerts: params.expect(:subscribed))

    respond_to do |format|
      format.html do
        redirect_to holding_alert_path(params[:token]),
          notice: @user.holding_alerts? ? "Holding alerts are back on." : "You won’t get Holding alerts anymore."
      end
      format.any { head :ok }
    end
  end

  private
    def set_user
      @user = User.find_by_token_for(:holding_alerts, params[:token]) or raise ActiveRecord::RecordNotFound
    end
end
