require "test_helper"

class HoldingAlertsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = @user.generate_token_for(:holding_alerts)
  end

  test "shows the reader's alert setting without signing in" do
    get holding_alert_path(@token)

    assert_response :success
    assert_select "button", "Turn off Holding alerts"
  end

  test "turns alerts off and back on" do
    patch holding_alert_path(@token), params: { subscribed: false }
    assert_redirected_to holding_alert_path(@token)
    assert_not @user.reload.holding_alerts?

    patch holding_alert_path(@token), params: { subscribed: true }
    assert @user.reload.holding_alerts?
  end

  test "mail clients unsubscribe in one click" do
    post holding_alert_path(@token, subscribed: false), params: { "List-Unsubscribe" => "One-Click" }

    assert_not @user.reload.holding_alerts?
  end

  test "rejects forged tokens" do
    get holding_alert_path("forged")

    assert_response :not_found
  end
end
