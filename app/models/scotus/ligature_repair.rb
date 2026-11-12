# Some PDFs (notably the bound-volume preliminary prints) map the "fi" and
# "fl" ligature glyphs to a bare "f", so "first" extracts as "frst". This
# restores words using a table of unambiguous non-words (lib/scotus/ligature_repairs.txt).
module Scotus::LigatureRepair
  TABLE = Rails.root.join("lib/scotus/ligature_repairs.txt").readlines(chomp: true)
                .reject { |line| line.start_with?("#") || line.blank? }
                .to_h { |line| line.split(" ", 2) }.freeze

  # Real words that, once a document is known to drop ligatures, can only
  # have come from the longer word.
  IN_BROKEN_DOCUMENTS = {
    "fled" => "filed", "fling" => "filing", "flings" => "filings", "fle" => "file", "fles" => "files",
    "refled" => "refiled"
  }.freeze

  WORD = /\b[[:alpha:]]+\b/
  BROKEN_THRESHOLD = 3

  extend self

  def broken?(texts)
    texts.sum { |text| text.scan(WORD).count { |word| TABLE.key?(word.downcase) } } >= BROKEN_THRESHOLD
  end

  def repair(html, broken:)
    return html unless broken

    html.gsub(WORD) do |word|
      lower = word.downcase
      replacement = TABLE[lower] || IN_BROKEN_DOCUMENTS[lower]
      replacement ? match_case(word, replacement) : word
    end
  end

  private
    def match_case(original, replacement)
      if original == original.upcase && original.length > 1 then replacement.upcase
      elsif original[0] == original[0].upcase then replacement.capitalize
      else replacement
      end
    end
end
