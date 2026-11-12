# Interprets running-header labels such as "KAGAN, J., dissenting" or
# "Opinion of the Court".
module Scotus::OpinionLabel
  extend self

  def kind(label)
    case label
    when /syllabus/i then :syllabus
    when /per curiam/i then :per_curiam
    when /opinion of the court/i then :majority
    when /\Aopinion of /i then :plurality
    when /dissent/i then :dissent
    when /concurr/i then :concurrence
    when /statement/i then :statement
    else :other
    end
  end

  def author(label, opening_text = nil)
    name = label[/\A(?:Opinion of )?([[:alpha:]’'\-]+),\s*(?:C\.\s*)?J\./i, 1]
    name ||= opening_text.to_s[/\A\s*(?:THE )?(?:CHIEF )?JUSTICE ([[:alpha:]’'\-]+) (?:delivered|announced)/i, 1]
    name&.downcase&.capitalize
  end
end
