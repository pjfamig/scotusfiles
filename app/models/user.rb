class User < ApplicationRecord
  HIGHLIGHT_COLORS = %w[ yellow green blue pink orange purple ].freeze

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :comments, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :name, with: ->(name) { name.squish }

  validates :name, presence: true, length: { maximum: 60 }
  validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :password, length: { minimum: 8 }, allow_nil: true
  validates :highlight_color, inclusion: { in: HIGHLIGHT_COLORS }

  def initials = name.split.first(2).map { |part| part[0] }.join.upcase

  def can_delete?(comment) = admin? || comment.user_id == id
end
