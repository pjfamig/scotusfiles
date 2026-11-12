class Comment < ApplicationRecord
  belongs_to :decision, counter_cache: true
  belongs_to :passage, optional: true, counter_cache: true
  belongs_to :user

  validates :body, presence: true, length: { maximum: 5_000 }
  validate :passage_belongs_to_decision

  scope :chronological, -> { order(:created_at, :id) }
  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  after_create_commit :broadcast_creation
  after_destroy_commit :broadcast_removal

  def thread_target = passage ? ActionView::RecordIdentifier.dom_id(passage, :comments) : "decision_#{decision_id}_general_comments"

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

    def broadcast_annotation_counts
      broadcast_replace_later_to decision, target: "annotation_counts", partial: "decisions/annotation_counts", locals: { decision: decision }
    end
end
