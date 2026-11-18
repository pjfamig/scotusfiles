class Comment < ApplicationRecord
  belongs_to :decision, counter_cache: true
  belongs_to :passage, optional: true, counter_cache: true
  belongs_to :user
  has_many :votes, dependent: :delete_all

  validates :body, presence: true, length: { maximum: 5_000 }
  validate :passage_belongs_to_decision

  scope :chronological, -> { order(:created_at, :id) }
  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  after_create_commit :broadcast_creation
  after_destroy_commit :broadcast_removal

  def thread_target = passage ? ActionView::RecordIdentifier.dom_id(passage, :comments) : "decision_#{decision_id}_general_comments"

  # Recounts from the votes table in one statement so concurrent votes can't
  # leave the cached counts drifting.
  def tally_votes
    tallied = Comment.where(id: id).update_all(<<~SQL.squish)
      upvotes_count = (SELECT COUNT(*) FROM votes WHERE votes.comment_id = comments.id AND votes.direction = 1),
      downvotes_count = (SELECT COUNT(*) FROM votes WHERE votes.comment_id = comments.id AND votes.direction = -1),
      score = (SELECT COALESCE(SUM(votes.direction), 0) FROM votes WHERE votes.comment_id = comments.id)
    SQL
    broadcast_score if tallied.positive?
  end

  def score_class = ActionView::RecordIdentifier.dom_id(self, :score)

  private
    def passage_belongs_to_decision
      errors.add(:passage, "is not part of this decision") if passage && passage.decision_id != decision_id
    end

    def broadcast_creation
      broadcast_append_later_to decision, target: thread_target, partial: "comments/comment", locals: { comment: self }
      broadcast_prepend_later_to decision, target: "decision_discussion", partial: "comments/discussion_item", locals: { comment: self }
      broadcast_annotation_counts
    end

    def broadcast_removal
      broadcast_remove_to decision
      broadcast_remove_to decision, target: ActionView::RecordIdentifier.dom_id(self, :discussion)
      broadcast_annotation_counts
    end

    # A comment's score shows in both the passage thread and the discussion
    # list, so it is targeted by class rather than id.
    def broadcast_score
      broadcast_replace_later_to decision, targets: ".#{score_class}", partial: "comments/score", locals: { comment: self }
    end

    def broadcast_annotation_counts
      broadcast_replace_later_to decision, target: "annotation_counts", partial: "decisions/annotation_counts", locals: { decision: decision }
    end
end
