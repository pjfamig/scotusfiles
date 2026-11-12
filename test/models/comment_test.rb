require "test_helper"

class CommentTest < ActiveSupport::TestCase
  test "updates passage and decision comment counts" do
    passage = passages(:paxton_judgment)

    assert_difference -> { passage.reload.comments_count } => 1, -> { decisions(:paxton).reload.comments_count } => 1 do
      Comment.create!(decision: decisions(:paxton), passage: passage, user: users(:two), body: "Short and sweet.")
    end
  end

  test "rejects passages from another decision" do
    comment = Comment.new(decision: decisions(:pending), passage: passages(:paxton_holding), user: users(:one), body: "Hmm")

    assert_not comment.valid?
    assert_includes comment.errors[:passage], "is not part of this decision"
  end
end
