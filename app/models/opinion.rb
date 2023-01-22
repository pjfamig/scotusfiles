class Opinion < ApplicationRecord
  validates_presence_of :title, :holding, :decision_date 
  has_rich_text :full_decision     # Styling for full decisions
  has_many_attached :files         # Use has_many_attached for multiple files allowed
  
  has_many :comments
  belongs_to :user  
end
