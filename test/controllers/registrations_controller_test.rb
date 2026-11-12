require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  test "creates an account and signs in" do
    assert_difference -> { User.count } do
      post registration_path, params: { user: { name: "New Reader", email_address: "new@example.com", password: "password123", password_confirmation: "password123" } }
    end

    assert_redirected_to root_url
    assert cookies[:session_id].present?
  end

  test "rejects invalid accounts" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { name: "", email_address: "one@example.com", password: "short", password_confirmation: "short" } }
    end

    assert_response :unprocessable_entity
  end
end
