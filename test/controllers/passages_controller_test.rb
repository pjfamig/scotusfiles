require "test_helper"

class PassagesControllerTest < ActionDispatch::IntegrationTest
  test "renders a passage thread inside the margin frame" do
    get decision_passage_path(decisions(:paxton), "1-1"), headers: { "Turbo-Frame" => "passage_panel" }

    assert_response :success
    assert_select "turbo-frame#passage_panel blockquote", text: /We hold that they do not\./
    assert_select "li", text: /This is the crux of the case\./
    assert_select "a", text: "Sign in"
  end

  test "remembers the passage so readers return to it after signing in" do
    get decision_passage_path(decisions(:paxton), "1-1"), headers: { "Turbo-Frame" => "passage_panel" }
    post session_path, params: { email_address: users(:one).email_address, password: "password" }

    assert_redirected_to decision_url(decisions(:paxton), s: "1-1")
  end

  test "redirects direct visits to the sentence on the decision page" do
    get decision_passage_path(decisions(:paxton), "1-2")

    assert_redirected_to decision_path(decisions(:paxton), anchor: "s-1-2")
  end
end
