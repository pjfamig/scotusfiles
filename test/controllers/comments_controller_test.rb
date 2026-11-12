require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  test "signed-in readers comment on a passage" do
    sign_in_as users(:two)

    assert_difference -> { passages(:paxton_judgment).comments.count } do
      post decision_comments_path(decisions(:paxton)), params: { passage_key: "1-2", comment: { body: "Affirmed!" } }, as: :turbo_stream
    end

    assert_response :success
    assert_equal users(:two), Comment.last.user
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(passages(:paxton_judgment), :comments)}"), response.body
  end

  test "blank comments are rejected" do
    sign_in_as users(:two)

    assert_no_difference -> { Comment.count } do
      post decision_comments_path(decisions(:paxton)), params: { passage_key: "1-2", comment: { body: " " } }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "guests must sign in to comment" do
    post decision_comments_path(decisions(:paxton)), params: { passage_key: "1-2", comment: { body: "Hello" } }

    assert_redirected_to new_session_path
  end

  test "authors can delete their comments but others cannot" do
    comment = comments(:on_holding)

    sign_in_as users(:two)
    delete decision_comment_path(decisions(:paxton), comment), as: :turbo_stream
    assert_response :forbidden

    sign_in_as users(:one)
    assert_difference -> { Comment.count }, -1 do
      delete decision_comment_path(decisions(:paxton), comment), as: :turbo_stream
    end
  end

  test "lists recent discussion in the margin" do
    get decision_comments_path(decisions(:paxton))

    assert_response :success
    assert_select "#decision_discussion li", 1
  end
end
