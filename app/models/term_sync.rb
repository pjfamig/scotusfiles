# One check of the Court's listing for a term (hourly or from the admin sync button).
class TermSync < ApplicationRecord
  scope :latest_first, -> { order(created_at: :desc, id: :desc) }

  def failed? = error.present?
end
