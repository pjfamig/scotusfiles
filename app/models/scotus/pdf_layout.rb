require "open3"

# Reads a slip opinion PDF into positioned lines using Poppler's `pdftohtml -xml`,
# which preserves each text run's coordinates, size, and italics.
class Scotus::PdfLayout
  Line = Struct.new(:page, :top, :left, :right, :height, :html, :text, keyword_init: true) do
    def center = (left + right) / 2.0
    def width = right - left
  end

  Page = Struct.new(:number, :height, :width, :lines, keyword_init: true)

  # Private-use codepoints delimit footnote reference markers inside line HTML.
  FOOTNOTE_OPEN = "\u{E000}".freeze
  FOOTNOTE_CLOSE = "\u{E001}".freeze
  SUPERSCRIPT_RATIO = 0.75
  WATERMARK = "Page Proof Pending Publication".freeze
  PRIVATE_USE_GLYPHS = { "\u{E405}" => "fi", "\u{F0B7}" => "•" }.freeze
  PRIVATE_USE = /[\u{E000}-\u{F8FF}]/

  class ConversionError < StandardError; end

  def self.from_pdf(path)
    xml, status = Open3.capture2("pdftohtml", "-xml", "-i", "-q", "-stdout", "-nodrm", path.to_s)
    raise ConversionError, "pdftohtml failed (exit #{status.exitstatus})" unless status.success?
    new(xml)
  rescue Errno::ENOENT
    raise ConversionError, "pdftohtml is not installed (install poppler / poppler-utils)"
  end

  attr_reader :pages

  def initialize(xml)
    @pages = Nokogiri::XML(xml).css("page").map { |page| parse_page(page) }
  end

  def lines = pages.flat_map(&:lines)

  private
    Run = Struct.new(:top, :left, :width, :height, :html, :text, keyword_init: true) do
      def bottom = top + height
      def right = left + width
      def middle = top + height / 2.0
    end

    def parse_page(node)
      runs = node.css("text").filter_map { |text| parse_run(text) }
      lines = group_into_lines(runs).map { |line_runs| build_line(line_runs, node["number"].to_i) }
      Page.new(number: node["number"].to_i, height: node["height"].to_f, width: node["width"].to_f, lines: lines)
    end

    def parse_run(node)
      text = clean(node.text)
      return if text.empty? || text.squish == WATERMARK

      Run.new(
        top: node["top"].to_f, left: node["left"].to_f,
        width: node["width"].to_f, height: node["height"].to_f,
        html: inline_html(node), text: text
      )
    end

    def inline_html(node)
      node.children.map do |child|
        if child.text?
          ERB::Util.html_escape(clean(child.text))
        elsif %w[i b].include?(child.name)
          inner = inline_html(child)
          inner.strip.empty? ? inner : "<#{child.name}>#{inner}</#{child.name}>"
        else
          inline_html(child)
        end
      end.join
    end

    def clean(text)
      text.gsub(PRIVATE_USE) { |glyph| PRIVATE_USE_GLYPHS.fetch(glyph, "") }
    end

    def group_into_lines(runs)
      runs.sort_by { |run| [ run.top, run.left ] }.each_with_object([]) do |run, lines|
        line = lines.reverse_each.first(3).find { |candidate| same_line?(candidate, run) }
        line ? line << run : lines << [ run ]
      end
    end

    def same_line?(line_runs, run)
      top = line_runs.map(&:top).min
      bottom = line_runs.map(&:bottom).max
      run.middle.between?(top - 1, bottom + 1) || line_runs.any? { |other| other.middle.between?(run.top - 1, run.bottom + 1) }
    end

    def build_line(runs, page_number)
      runs = runs.sort_by(&:left)
      line_height = runs.map(&:height).max
      html = +""
      text = +""

      runs.each_with_index do |run, index|
        previous = runs[index - 1] if index.positive?
        if previous && run.left - previous.right > 1.5 && !text.end_with?(" ") && !run.text.start_with?(" ")
          html << " "
          text << " "
        end

        if footnote_marker?(run, line_height)
          number = run.text.strip
          html << "#{FOOTNOTE_OPEN}#{number}#{FOOTNOTE_CLOSE}"
          text << "#{FOOTNOTE_OPEN}#{number}#{FOOTNOTE_CLOSE}"
        else
          html << run.html
          text << run.text
        end
      end

      Line.new(
        page: page_number, top: runs.select { |r| r.height == line_height }.map(&:top).min,
        left: runs.first.left, right: runs.map(&:right).max, height: line_height,
        html: html, text: text
      )
    end

    def footnote_marker?(run, line_height)
      run.text.match?(/\A\s*\d{1,3}\s*\z/) && run.height < line_height * SUPERSCRIPT_RATIO
    end
end
