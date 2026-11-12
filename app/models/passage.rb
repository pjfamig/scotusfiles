class Passage < ApplicationRecord
  belongs_to :decision
  belongs_to :opinion, optional: true
  has_many :comments, dependent: :destroy

  def to_param = key

  def anchor = "s-#{key}"
end
