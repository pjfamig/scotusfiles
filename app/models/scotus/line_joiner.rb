# Joins typeset lines back into running text: undoes end-of-line hyphenation
# and preserves the Court's convention of two spaces between sentences, which
# Scotus::SentenceSplitter relies on.
class Scotus::LineJoiner
  ABBREVIATIONS = %w[
    v vs no nos co corp inc ltd ann app stat stats supp cum rev id jj cl ch art arts n nn p pp ed eds cir dist ct cong sess
    reg leg assem pub fed seq al tr br pet govt gov dept mr ms mrs dr st jr sr bros assn assoc univ comm intl natl am admin
    rep sen doc res vol cf eg ie viz mfg ry r cal tex fla ga ill mass mich pa va wash wis ky la md minn mo ore okla tenn ariz
    colo conn del ind kan neb nev mont miss ala ark wyo vt nh nj nm ny nc nd sc sd ri ut haw ida me
  ].to_set.freeze

  TERMINAL = /[.?!][”’"')\]]*\z/
  TAG = /<[^>]+>/

  def initialize(document_lines = [])
    @compounds = document_lines.flat_map { |line| line.scan(/(?<=\s|\A)([A-Za-z]+-[A-Za-z]+)(?=[\s,.;:)”’]|\z)/).flatten }
                               .map(&:downcase).to_set
    @reliable_spacing = reliable_spacing?(document_lines)
    @broken_ligatures = Scotus::LigatureRepair.broken?(document_lines)
  end

  def repair(html) = Scotus::LigatureRepair.repair(html, broken: @broken_ligatures)

  def join(fragments)
    fragments.each_with_object(+"") do |fragment, result|
      fragment = fragment.sub(/\A\s+/, "")
      fragment = respace(fragment) unless @reliable_spacing
      next if fragment.empty?

      if result.empty?
        result << fragment
      else
        append(result, fragment)
      end
    end.rstrip.then { |html| repair(html) }
  end

  private
    def append(result, fragment)
      result.sub!(/\s+\z/, "")
      tail = plain(result)
      head = plain(fragment)

      if tail.end_with?("-") && !tail.end_with?("--") && head.match?(/\A[a-z]/)
        before = tail[/([A-Za-z]+)-\z/, 1].to_s
        after = head[/\A([a-z]+)/, 1].to_s
        result.sub!(/-((?:<\/[a-z]+>)*)\z/, '\1') unless @compounds.include?("#{before}-#{after}".downcase)
        result << fragment
      elsif tail.end_with?("—") || head.start_with?("—")
        result << fragment
      elsif sentence_end?(tail)
        result << "  " << fragment
      else
        result << " " << fragment
      end
    end

    def sentence_end?(text)
      return false unless text.match?(TERMINAL)

      word = text.sub(/[.?!][”’"')\]]*\z/, "").split(/\s/).last.to_s
      return true if word.match?(/\d\z/) || word.end_with?(")")
      return false if word.match?(/\A[A-Z]\z/) || word.match?(/\A(?:[a-z]\.)+[a-z]\z/i)

      !ABBREVIATIONS.include?(word.downcase.delete("’'."))
    end

    # Bound-volume prints justify lines with extra spaces between ordinary
    # words, which makes double spaces meaningless as sentence boundaries.
    def reliable_spacing?(lines)
      return true if lines.empty?

      padded = lines.count { |line| line.match?(/[a-z,;]  +[a-z]/) }
      padded < lines.size * 0.05
    end

    def respace(fragment)
      fragment = fragment.gsub(/ {2,}/, " ")
      fragment.gsub(/([.?!][”’"')\]]*(?:<\/[a-z]+>)*) (?=(?:<[a-z]+>)*[A-Z\d“‘(§])/) do
        sentence_end?(plain($` + $1)) ? "#{$1}  " : "#{$1} "
      end
    end

    def plain(html) = html.gsub(TAG, "").gsub(/#{Scotus::PdfLayout::FOOTNOTE_OPEN}\d+#{Scotus::PdfLayout::FOOTNOTE_CLOSE}/o, "")
end
