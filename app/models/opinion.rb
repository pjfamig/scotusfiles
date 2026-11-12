class Opinion < ApplicationRecord
  belongs_to :decision
  has_many :passages, dependent: :nullify

  enum :kind, { other: 0, syllabus: 1, majority: 2, per_curiam: 3, plurality: 4, concurrence: 5, dissent: 6, statement: 7 }

  def title
    case kind
    when "syllabus" then "Syllabus"
    when "majority" then "Opinion of the Court"
    when "per_curiam" then "Per Curiam"
    else display_label
    end
  end

  def byline
    return if syllabus? || per_curiam?
    return "Justice #{author}" if majority? && author

    nil
  end

  def anchor = "opinion-#{position}"

  private
    # "KAGAN, J., concurring in part" -> "Justice Kagan, concurring in part"
    def display_label
      label.sub(/\A(?:Opinion of )?([[:alpha:]’'\-]+),\s*C\.\s*J\.,?\s*/i) { "Chief Justice #{$1.capitalize}, " }
           .sub(/\A(?:Opinion of )?([[:alpha:]’'\-]+),\s*J\.,?\s*/i) { "Justice #{$1.capitalize}, " }
           .sub(/,\s*\z/, "")
           .then { |text| plurality? ? "Opinion of #{text}" : text }
    end
end
