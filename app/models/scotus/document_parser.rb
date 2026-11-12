# Turns positioned lines from a slip opinion into sections (syllabus, opinion of
# the Court, concurrences, dissents) made of typed blocks plus footnotes.
#
# Slip opinions are typeset consistently, so layout carries the structure:
# every page has a running header naming the section it belongs to, footnotes
# sit below an em-dash rule, paragraphs start with an indent (or an outdent in
# the syllabus), block quotes are inset, and headings are centered.
class Scotus::DocumentParser
  Section = Struct.new(:label, :blocks, :footnotes, keyword_init: true)
  Block = Struct.new(:type, :html, keyword_init: true)
  Footnote = Struct.new(:number, :paragraphs, keyword_init: true)

  HEADER_ZONE = 0.185
  FOOTNOTE_RULE = /\A\s*[—–]{3,}\s*\z/
  SEPARATOR = /\A\s*[_—–-]{5,}\s*\z/
  COURT_BANNER = /\ASUPREME COURT OF THE UNITED STATES\s*\z/
  UNTITLED = "Opinion".freeze
  OPENING = /\A(?:THE )?(?:CHIEF )?JUSTICE [[:alpha:]’'\-]+(?:,| delivered| announced)/i
  PRELIMINARY_COVER = /P\s?R\s?E\s?L\s?I\s?M\s?I\s?N\s?A\s?R\s?Y\s+P\s?R\s?I\s?N\s?T/
  REPORTERS_NOTE = /\AReporter’s Note\b/
  CAPTION_SEARCH_LINES = 30
  CAPTION_END = /\A\[[^\]]*\d{4}\]\z|Decided [A-Z][a-z]+ \d{1,2}, \d{4}\z/
  NOT_A_LABEL = [ /\A[\d\s]*\z/, /Cite as:/i, /Slip Opinion/i, /OCTOBER TERM/i, /\sv\.\s/, /\A\s*\(?Bench Opinion\)?/i ].freeze

  def self.parse(layout) = new(layout).sections

  def initialize(layout)
    @layout = layout
    @joiner = Scotus::LineJoiner.new(layout.lines.map(&:text))
  end

  def sections
    @sections ||= group_pages_by_label.filter_map { |label, body, notes| build_section(label, body, notes) }
  end

  private
    attr_reader :joiner

    # Slip opinions start each opinion on a new page, so the running header is
    # enough. Preliminary prints run opinions together, so an opening line such
    # as "JUSTICE KAGAN, dissenting." also starts a section mid-page.
    def group_pages_by_label
      groups = []
      start = ->(label) { groups << [ label, [], [] ] }

      content_pages.each do |page|
        header, body, notes = split_page(page)
        header_label = section_label(header)
        start.(header_label) if header_label && !same_label?(groups.last&.first, header_label) && !continues_previous_page?(body)
        start.(header_label || UNTITLED) if groups.empty?

        body.each_with_index do |line, index|
          if (label = opening_label(body, index)) && !same_label?(groups.last.first, label)
            start.(label)
          end
          groups.last[1] << line
        end
        groups.last[2].concat(notes)
      end

      label_leading_syllabus(groups)
    end

    # Bound-volume prints give the syllabus's first page no running header.
    def label_leading_syllabus(groups)
      first, second = groups
      return groups unless first && first[0] == UNTITLED && second

      if Scotus::OpinionLabel.kind(second[0]) == :syllabus
        second[1].unshift(*first[1])
        second[2].unshift(*first[2])
        groups.drop(1)
      else
        first[0] = "Syllabus"
        groups
      end
    end

    def content_pages
      pages = @layout.pages.reject { |page| page.lines.any? { |line| line.text.match?(PRELIMINARY_COVER) } }
      reporters_note = pages.index { |page| page.lines.any? { |line| line.text.squish.match?(REPORTERS_NOTE) } }
      reporters_note ? pages[0...reporters_note] : pages
    end

    # A page whose header names a new opinion may still open with the tail of
    # the previous one when opinions run together; the opening line handles it.
    def continues_previous_page?(body)
      opening = body.each_index.find { |index| opening_label(body, index) }
      opening&.positive? && body[0...opening].none? { |line| line.text.squish.match?(COURT_BANNER) }
    end

    def opening_label(lines, index)
      text = lines[index].text.squish
      return "Per Curiam" if text.match?(/\APER CURIAM\.?\z/i)
      return unless text.match?(OPENING) && starts_line_block?(lines, index)

      sentence = lines[index, 3].map { |l| l.text.squish }.join(" ").gsub(/(\p{Ll})- (\p{Ll})/, '\1\2')[/\A.*?(?:dissenting|concurring|of the Court|judgment|part|result|joins?|joined)\./i]
      label_for_opening(sentence) if sentence
    end

    def starts_line_block?(lines, index)
      return true if index.zero?

      previous = lines[index - 1]
      rights = lines.map(&:right).sort
      previous.right < rights[(rights.size * 0.9).floor] - 30 || previous.left > lines[index].left + 60
    end

    def label_for_opening(sentence)
      name = sentence[/JUSTICE ([[:alpha:]’'\-]+)/i, 1].to_s.upcase
      chief = sentence.match?(/\A(?:THE )?CHIEF JUSTICE/i)
      title = chief ? "#{name}, C. J." : "#{name}, J."

      case sentence
      when /delivered the opinion of the Court/i then "Opinion of the Court"
      when /announced the judgment of the Court/i then "Opinion of #{title}"
      else "#{title}, #{sentence.split(/,\s*/).last.delete_suffix('.')}"
      end
    end

    def same_label?(a, b)
      a && b && normalize_label(a) == normalize_label(b)
    end

    def normalize_label(label) = label.downcase.gsub(/[^a-z]/, "")

    def split_page(page)
      cutoff = page.height * HEADER_ZONE
      header, rest = page.lines.partition { |line| line.top < cutoff }
      rule_index = rest.index { |line| line.text.match?(FOOTNOTE_RULE) }
      return [ header, rest[0...rule_index], rest[(rule_index + 1)..] ] if rule_index

      notes_start = trailing_small_print_index(rest)
      [ header, rest[0...notes_start], rest[notes_start..] ]
    end

    # Bound-volume prints draw the footnote rule as a graphic, so footnotes are
    # recognized as the small-type lines at the foot of the page instead.
    # Measured against the page's largest recurring text size, because the
    # syllabus is set smaller than opinions and a page can hold both.
    def trailing_small_print_index(lines)
      left = lines.map(&:left).min
      right = lines.map(&:right).max
      running_text = lines.reject { |line| line.left > left + 15 && line.right < right - 15 }
      text_height = running_text.map { |line| line.height.round }.tally.select { |_, count| count >= 3 }.keys.max
      return lines.size unless text_height

      small = ->(line) { line.height < text_height * 0.85 }
      index = lines.size
      index -= 1 while index.positive? && small.(lines[index - 1])
      lines[0...index].any? { |line| !small.(line) } ? index : lines.size
    end

    def section_label(header_lines)
      label = header_lines.map { |line| line.text.squish }.reverse.find do |text|
        NOT_A_LABEL.none? { |pattern| text.match?(pattern) }
      end
      label&.sub(/\A\d+\s+/, "")&.sub(/\s+\d+\z/, "")
    end

    def build_section(label, body_lines, note_lines)
      body_lines = body_lines.reject { |line| line.text.squish.empty? }
      return if body_lines.empty?

      metrics = Metrics.new(body_lines)
      Section.new(label: label, blocks: build_blocks(body_lines, metrics), footnotes: build_footnotes(note_lines))
    end

    def build_blocks(lines, metrics)
      blocks = []
      paragraph = []
      paragraph_type = :paragraph
      in_caption = false
      quote_lines = quote_line_indexes(lines, metrics)
      caption_through = caption_end_index(lines, metrics)

      flush = lambda do
        if paragraph.any?
          blocks << Block.new(type: paragraph_type, html: joiner.join(paragraph.map(&:html)))
          paragraph = []
        end
      end

      lines.each_with_index do |line, index|
        text = line.text.squish
        next if text.match?(SEPARATOR) && !text.match?(/[a-z]/i)

        if text.match?(COURT_BANNER)
          flush.call
          in_caption = true
          blocks << Block.new(type: :banner, html: "Supreme Court of the United States")
          next
        end

        if caption_through && index <= caption_through && !metrics.small?(line)
          flush.call
          append_caption_line(blocks, line)
          next
        end

        if in_caption
          if metrics.roughly_centered?(line) || metrics.small?(line)
            append_caption_line(blocks, line)
            in_caption = false if text.match?(CAPTION_END)
            next
          end
          in_caption = false
        end

        type =
          if metrics.small?(line) then :notice
          elsif metrics.centered?(line) then :heading
          elsif quote_lines.include?(index) then :blockquote
          elsif metrics.flush_right?(line) then :flush_right
          else :paragraph
          end

        if type == :heading
          flush.call
          blocks << Block.new(type: :heading, html: joiner.repair(line.html.strip))
          next
        end

        previous = lines[index - 1] if index.positive?
        if paragraph.any? && (type != paragraph_type || starts_paragraph?(line, previous, metrics, type))
          flush.call
        end
        paragraph_type = type
        paragraph << line
      end

      flush.call
      merge_caption_lines(blocks)
    end

    def starts_paragraph?(line, previous, metrics, type)
      return true if previous.nil?
      return false if type == :notice
      return true if line.text.start_with?("  ")
      return true if metrics.short?(previous)

      if type == :blockquote
        line.left > previous.left + 4
      else
        !metrics.at_margin?(line) && metrics.at_margin?(previous)
      end
    end

    # Inset lines that wrap onto further inset lines are block quotes; a lone
    # inset line is just a paragraph's first-line indent. Consecutive lines at
    # exactly the paragraph indent are separate one-line paragraphs.
    def quote_line_indexes(lines, metrics)
      inset = lines.map do |line|
        metrics.inset?(line) && !metrics.centered?(line) && !metrics.small?(line) && !metrics.flush_right?(line)
      end
      indent = paragraph_indent(lines, inset)
      at_indent = ->(index) { indent && (lines[index].left - indent).abs <= 2 }
      wraps = lambda do |index|
        inset[index] && inset[index + 1] && !metrics.short?(lines[index]) && !(at_indent.(index) && at_indent.(index + 1))
      end

      inset.each_index.select do |index|
        wraps.(index) || (index.positive? && wraps.(index - 1))
      end.to_set
    end

    def paragraph_indent(lines, inset)
      starts = inset.each_index.select { |index| inset[index] && lines[index + 1] && !inset[index + 1] }
      starts.map { |index| lines[index].left.round }.tally.max_by { |_, count| count }&.first
    end

    # The caption runs from the top of a section through its date line
    # ("No. 23–1122. Argued …—Decided June 27, 2025" or "[June 27, 2025]").
    def caption_end_index(lines, metrics)
      lines.first(CAPTION_SEARCH_LINES).index do |line|
        line.text.squish.match?(CAPTION_END) && metrics.roughly_centered?(line)
      end
    end

    def append_caption_line(blocks, line)
      blocks << Block.new(type: :caption_line, html: joiner.repair(line.html.strip))
    end

    def merge_caption_lines(blocks)
      blocks.chunk_while { |a, b| a.type == :caption_line && b.type == :caption_line }.flat_map do |chunk|
        if chunk.first.type == :caption_line
          [ Block.new(type: :caption, html: chunk.map(&:html).join("\n")) ]
        else
          chunk
        end
      end
    end

    def build_footnotes(lines)
      lines = lines.reject { |line| line.text.squish.empty? }
      return [] if lines.empty?

      metrics = Metrics.new(lines)
      footnotes = []

      lines.each do |line|
        if (match = line.html.match(/\A\s*#{Scotus::PdfLayout::FOOTNOTE_OPEN}(\d+)#{Scotus::PdfLayout::FOOTNOTE_CLOSE}\s*/o))
          footnotes << Footnote.new(number: match[1].to_i, paragraphs: [ [ match.post_match ] ])
        elsif footnotes.empty?
          footnotes << Footnote.new(number: nil, paragraphs: [ [ line.html ] ])
        elsif metrics.inset?(line) && !line.text.start_with?(" ")
          footnotes.last.paragraphs << [ line.html ]
        else
          footnotes.last.paragraphs.last << line.html
        end
      end

      footnotes.each do |footnote|
        footnote.paragraphs = footnote.paragraphs.map { |parts| joiner.join(parts) }
      end
    end

    class Metrics
      def initialize(lines)
        @body_height = mode(lines.map { |line| line.height.round })
        regular = lines.select { |line| (line.height - @body_height).abs <= 1 }
        regular = lines if regular.empty?
        @margin = mode(regular.map { |line| line.left.round })
        rights = regular.map(&:right).sort
        @right = rights[(rights.size * 0.9).floor.clamp(0, rights.size - 1)]
        @center = (@margin + @right) / 2.0
      end

      def small?(line) = line.height < @body_height * 0.85
      def at_margin?(line) = (line.left - @margin).abs <= 4
      def inset?(line) = line.left > @margin + 4
      def short?(line) = line.right < @right - 25

      def centered?(line)
        roughly_centered?(line) && line.left >= @margin + 20 && line.right <= @right - 20
      end

      def roughly_centered?(line) = (line.center - @center).abs <= 14

      def flush_right?(line)
        line.left > @margin + 60 && (line.right - @right).abs <= 12
      end

      private
        def mode(values) = values.tally.max_by { |_, count| count }&.first || 0
    end
end
