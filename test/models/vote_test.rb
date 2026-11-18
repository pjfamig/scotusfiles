require "test_helper"

class VoteTest < ActiveSupport::TestCase
  setup { @comment = comments(:on_holding) }

  test "tallies upvotes, downvotes, and score on the comment" do
    @comment.votes.create!(user: users(:two), direction: :up)
    @comment.votes.create!(user: users(:admin), direction: :down)
    assert_equal [ 1, 1, 0 ], @comment.reload.values_at(:upvotes_count, :downvotes_count, :score)

    @comment.votes.find_by!(user: users(:admin)).update!(direction: :up)
    assert_equal [ 2, 0, 2 ], @comment.reload.values_at(:upvotes_count, :downvotes_count, :score)

    @comment.votes.find_by!(user: users(:two)).destroy!
    assert_equal [ 1, 0, 1 ], @comment.reload.values_at(:upvotes_count, :downvotes_count, :score)
  end

  test "one vote per reader per comment" do
    @comment.votes.create!(user: users(:two), direction: :up)
    assert_not @comment.votes.new(user: users(:two), direction: :down).valid?
  end

  test "authors can't vote on their own comments" do
    vote = @comment.votes.new(user: users(:one), direction: :up)

    assert_not vote.valid?
    assert_includes vote.errors[:comment], "is your own"
  end

  test "rejects directions other than up or down" do
    assert_not @comment.votes.new(user: users(:two), direction: "sideways").valid?
  end

  test "a voter leaving recounts the comments they voted on" do
    @comment.votes.create!(user: users(:two), direction: :down)

    users(:two).destroy!
    assert_equal 0, @comment.reload.score
  end
end
