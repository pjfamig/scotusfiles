# One attempt to convert a decision's PDF, kept so admins can see first imports,
# refreshes, and failures over time.
class DecisionImport < ApplicationRecord
  belongs_to :decision

  scope :latest_first, -> { order(created_at: :desc, id: :desc) }
  scope :failed, -> { where(succeeded: false) }
  scope :refreshes, -> { where(refresh: true) }
  scope :first_imports, -> { where(refresh: false) }
end
