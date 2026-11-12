require "test_helper"

class DecisionsControllerTest < ActionDispatch::IntegrationTest
  test "lists decisions for a term" do
    get decisions_path(term: 2024)

    assert_response :success
    assert_select "h3", text: "Free Speech Coalition, Inc. v. Paxton"
    assert_select "h3", text: "Example v. Pending", count: 0
  end

  test "searches across terms" do
    get decisions_path(q: "23-1122")

    assert_response :success
    assert_select "h3", text: "Free Speech Coalition, Inc. v. Paxton"
  end

  test "shows the formatted opinion with commentable sentences" do
    get decision_path(decisions(:paxton))

    assert_response :success
    assert_select "h1", "Free Speech Coalition, Inc. v. Paxton"
    assert_select "article .sentence[data-key='1-1']", "We hold that they do not."
    assert_select "#annotation_counts[data-annotation-counts-counts-value=?]", { "1-1" => 1 }.to_json
  end

  test "shows a progress message while a decision is being formatted" do
    get decision_path(decisions(:pending))

    assert_response :success
    assert_select "p", text: "Formatting this opinion…"
  end

  test "admins can sync a term" do
    sign_in_as users(:admin)

    assert_enqueued_with(job: SyncTermJob, args: [ 2025 ]) do
      post admin_term_sync_path(2025)
    end
    assert_redirected_to decisions_path(term: 2025)
  end

  test "non-admins cannot sync or re-import" do
    sign_in_as users(:one)

    post admin_term_sync_path(2025)
    assert_response :forbidden

    post decision_import_path(decisions(:paxton))
    assert_response :forbidden
  end
end
