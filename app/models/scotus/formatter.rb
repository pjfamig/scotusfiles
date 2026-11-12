# Renders parsed sections as reading-ready HTML. Every sentence in the body
# and footnotes is wrapped in a span with a stable key so readers can select
# it and comment on it; the same keys identify Passage records.
class Scotus::Formatter
  FormattedOpinion = Struct.new(:position, :kind, :label, :author, :html, :passages, keyword_init: true)
  FormattedPassage = Struct.new(:key, :position, :text, keyword_init: true)

  MARKER = /#{Scotus::PdfLayout::FOOTNOTE_OPEN}(\d+)#{Scotus::PdfLayout::FOOTNOTE_CLOSE}/o

  def self.format(sections) = sections.each_with_index.map { |section, index| new(section, index + 1).format }

  def initialize(section, position)
    @section = section
    @position = position
    @passages = []
    @counter = 0
  end

  def format
    FormattedOpinion.new(
      position: @position,
      kind: Scotus::OpinionLabel.kind(@section.label),
      label: @section.label,
      author: Scotus::OpinionLabel.author(@section.label, opening_text),
      html: render,
      passages: @passages
    )
  end

  private
    def render
      body = render_blocks(@section.blocks)
      notes = render_footnotes(@section.footnotes)
      [ body, notes ].compact_blank.join("\n")
    end

    def render_blocks(blocks)
      html = []
      blocks.each do |block|
        case block.type
        when :notice then html << %(<p class="notice">#{plain_inline(block.html)}</p>)
        when :banner then html << %(<p class="court-banner">#{block.html}</p>)
        when :caption then html << %(<div class="caption">#{block.html.split("\n").map { |line| "<p>#{plain_inline(line)}</p>" }.join}</div>)
        when :heading then html << %(<h3 class="division">#{plain_inline(block.html)}</h3>)
        when :flush_right then html << %(<p class="flush-right">#{plain_inline(block.html)}</p>)
        when :blockquote then html << %(<blockquote>#{paragraph(block.html)}</blockquote>)
        else html << paragraph(block.html)
        end
      end
      html.join("\n")
    end

    def render_footnotes(footnotes)
      return if footnotes.empty?

      items = footnotes.map do |footnote|
        number = footnote.number
        anchor = number ? %( id="#{footnote_id(number)}" value="#{number}") : %( class="continued")
        backlink = number ? %( <a href="##{footnote_ref_id(number)}" class="footnote-back" aria-label="Back to text">↩</a>) : ""
        paragraphs = footnote.paragraphs.map { |text| paragraph(text, footnote: number) }
        "<li#{anchor}>#{paragraphs.join}#{backlink}</li>"
      end
      %(<footer class="footnotes"><ol>#{items.join}</ol></footer>)
    end

    def paragraph(html, footnote: nil)
      sentences = Scotus::SentenceSplitter.split(html).map { |sentence| sentence_span(sentence, footnote) }
      "<p>#{sentences.join(' ')}</p>"
    end

    def sentence_span(sentence_html, footnote)
      @counter += 1
      key = footnote ? "#{@position}-n#{footnote}-#{@counter}" : "#{@position}-#{@counter}"
      text = plain_text(sentence_html)
      @passages << FormattedPassage.new(key: key, position: @counter, text: text) if text.present?
      %(<span class="sentence" id="s-#{key}" data-key="#{key}">#{link_footnotes(sentence_html)}</span>)
    end

    def link_footnotes(html)
      html.gsub(MARKER) do
        number = $1
        %(<sup class="footnote-ref"><a href="##{footnote_id(number)}" id="#{footnote_ref_id(number)}">#{number}</a></sup>)
      end
    end

    def plain_inline(html) = link_footnotes(html.gsub(/\s+/, " ").strip)

    def plain_text(html)
      CGI.unescapeHTML(html.gsub(MARKER, "").gsub(/<[^>]+>/, "")).squish
    end

    def opening_text
      @section.blocks.find { |block| block.type == :paragraph }&.html.to_s.gsub(/<[^>]+>/, "")
    end

    def footnote_id(number) = "fn-#{@position}-#{number}"
    def footnote_ref_id(number) = "fnref-#{@position}-#{number}"
end
