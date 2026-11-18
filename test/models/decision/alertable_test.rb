require "test_helper"

class Decision::AlertableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper, ActionMailer::TestHelper

  setup do
    @decision = decisions(:pending)
    @decision.update!(decided_on: Date.current)
  end

  test "the first import of a new decision queues a Holding alert" do
    assert_enqueued_with(job: HoldingAlertJob, args: [ @decision ]) do
      @decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
    end
  end

  test "re-imports don't alert again" do
    @decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))

    assert_no_enqueued_jobs(only: HoldingAlertJob) do
      @decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
    end
  end

  test "importing an older decision doesn't alert" do
    @decision.update!(decided_on: 2.weeks.ago.to_date)

    assert_no_enqueued_jobs(only: HoldingAlertJob) do
      @decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
    end
  end

  test "emails every subscribed reader exactly once" do
    users(:two).update!(holding_alerts: false)

    assert_enqueued_emails 2 do
      @decision.send_holding_alerts
      @decision.send_holding_alerts
    end
    assert @decision.reload.holding_alert_sent_at
  end

  test "without email delivery configured, alerts are skipped and left unclaimed" do
    with_holding_alerts_enabled(false) do
      assert_no_enqueued_jobs(only: HoldingAlertJob) do
        @decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
      end
      assert_no_enqueued_emails { @decision.send_holding_alerts }
    end

    assert_nil @decision.reload.holding_alert_sent_at
  end

  test "summarizes the holding in at most three sentences" do
    @decision.holding = "Held: The statute is valid. See 597 U. S. 1. The Fifth Circuit was right. It is affirmed. Extra."
    assert_equal "Held: The statute is valid. See 597 U. S. 1. The Fifth Circuit was right.", @decision.holding_summary

    @decision.holding = nil
    assert_nil @decision.holding_summary
  end

  private
    def with_holding_alerts_enabled(enabled)
      original, Rails.configuration.x.holding_alerts_enabled = Rails.configuration.x.holding_alerts_enabled, enabled
      yield
    ensure
      Rails.configuration.x.holding_alerts_enabled = original
    end
end
