class Comment < ApplicationRecord
  validates_presence_of :content 
  belongs_to :opinion
  belongs_to :user
  broadcasts_to :opinion
end
