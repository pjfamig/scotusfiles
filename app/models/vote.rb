class Vote < ApplicationRecord
  belongs_to :comment
  belongs_to :user

  enum :direction, { down: -1, up: 1 }, validate: true

  validates :user_id, uniqueness: { scope: :comment_id }
  validate :not_on_own_comment

  after_commit -> { comment.tally_votes }

  private
    def not_on_own_comment
      errors.add(:comment, "is your own") if comment && comment.user_id == user_id
    end
end
