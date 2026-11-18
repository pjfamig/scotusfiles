require "test_helper"

class HoldingAlertMailerTest < ActionMailer::TestCase
  test "sends the holding with a link to read and comment" do
    decision = decisions(:paxton)
    email = HoldingAlertMailer.with(user: users(:one), decision: decision).alert

    assert_equal [ "one@example.com" ], email.to
    assert_equal "Holding alert! Free Speech Coalition, Inc. v. Paxton", email.subject
    assert_includes email.text_part.body.to_s, "H. B. 1181 survives intermediate scrutiny."
    assert_includes email.html_part.body.to_s, "http://example.com/decisions/#{decision.slug}"
    assert_match %r{\A<http://example.com/holding_alerts/[^>]+\?subscribed=false>\z}, email["List-Unsubscribe"].value
    assert_equal "List-Unsubscribe=One-Click", email["List-Unsubscribe-Post"].value
  end
end
