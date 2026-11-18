require "test_helper"

class VotesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @decision = decisions(:paxton)
    @comment = comments(:on_holding)
  end

  test "readers upvote, switch to a downvote, and take their vote back" do
    sign_in_as users(:two)

    put decision_comment_vote_path(@decision, @comment), params: { direction: "up" }, as: :turbo_stream
    assert_response :success
    assert_equal 1, @comment.reload.score
    assert_match %(target="#{ActionView::RecordIdentifier.dom_id(@comment, :votes)}"), response.body
    assert_match(/aria-pressed="true"[^>]*title="Remove your upvote"/, response.body)

    put decision_comment_vote_path(@decision, @comment), params: { direction: "down" }, as: :turbo_stream
    assert_equal [ 0, 1, -1 ], @comment.reload.values_at(:upvotes_count, :downvotes_count, :score)

    assert_difference -> { Vote.count }, -1 do
      delete decision_comment_vote_path(@decision, @comment), as: :turbo_stream
    end
    assert_equal 0, @comment.reload.score
  end

  test "authors can't vote on their own comments" do
    sign_in_as users(:one)

    assert_no_difference -> { Vote.count } do
      put decision_comment_vote_path(@decision, @comment), params: { direction: "up" }, as: :turbo_stream
    end
    assert_response :unprocessable_entity
  end

  test "guests are sent to sign in" do
    put decision_comment_vote_path(@decision, @comment), params: { direction: "up" }

    assert_redirected_to new_session_path
  end

  test "the passage thread shows each reader their own votes" do
    @comment.votes.create!(user: users(:two), direction: :down)
    sign_in_as users(:two)

    get decision_passage_path(@decision, passages(:paxton_holding)), headers: { "Turbo-Frame" => "passage_panel" }

    assert_select "##{ActionView::RecordIdentifier.dom_id(@comment, :votes)}" do
      assert_select "button[aria-pressed=true][title='Remove your downvote']"
      assert_select ".#{@comment.score_class}", text: "-1"
    end
  end
end
