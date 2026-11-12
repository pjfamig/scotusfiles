class Decision < ApplicationRecord
  include Importable

  AUTHORS = {
    "R" => "Roberts", "T" => "Thomas", "A" => "Alito", "SS" => "Sotomayor", "EK" => "Kagan",
    "NG" => "Gorsuch", "BK" => "Kavanaugh", "AB" => "Barrett", "KJ" => "Jackson", "B" => "Breyer",
    "PC" => "Per Curiam", "D" => "Decree"
  }.freeze

  has_many :opinions, -> { order(:position) }, dependent: :destroy, inverse_of: :decision
  has_many :passages, dependent: :destroy
  has_many :comments, dependent: :destroy

  enum :status, { pending: 0, importing: 1, imported: 2, failed: 3 }

  validates :term, :docket_number, :title, :pdf_url, presence: true
  validates :slug, presence: true, uniqueness: true

  before_validation :assign_slug, on: :create

  scope :latest_first, -> { order(decided_on: :desc, id: :desc) }
  scope :in_term, ->(term) { where(term: term) }
  scope :search, ->(query) {
    pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where("title ILIKE :pattern OR docket_number ILIKE :pattern OR holding ILIKE :pattern", pattern: pattern)
  }

  def self.terms = distinct.order(term: :desc).pluck(:term)

  def to_param = slug

  def term_label = "October Term #{term}"

  def author_name
    AUTHORS.fetch(author_code, author_code)
  end

  def per_curiam? = author_code == "PC"

  def official_citation
    citation if citation.to_s.include?("U.S.")
  end

  private
    def assign_slug
      return if slug.present? || title.blank?

      base = [ title.parameterize.truncate(80, omission: "").delete_suffix("-"), docket_number.to_s.parameterize ].compact_blank.join("-")
      candidate = base
      candidate = "#{base}-#{decided_on&.strftime('%Y%m%d') || SecureRandom.hex(2)}" if Decision.exists?(slug: candidate)
      self.slug = candidate
    end
end
