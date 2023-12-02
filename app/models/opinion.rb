class Opinion < ApplicationRecord
  extend FriendlyId
  friendly_id :title, use: :slugged
  validates :title, :holding, presence: true
  has_many_attached :files  
  has_many :comments
  belongs_to :user    
  has_many :quotes, dependent: :destroy
end
