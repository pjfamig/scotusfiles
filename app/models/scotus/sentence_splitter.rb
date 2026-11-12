# Splits a paragraph of inline HTML into sentences. Slip opinions put two
# spaces after a sentence and one after an abbreviation ("U. S.", "Inc."),
# so a terminal mark followed by two or more spaces is a reliable boundary.
# Inline tags open across a boundary are closed and reopened so every
# sentence is well-formed HTML on its own.
class Scotus::SentenceSplitter
  MARKER = "#{Scotus::PdfLayout::FOOTNOTE_OPEN}\\d+#{Scotus::PdfLayout::FOOTNOTE_CLOSE}".freeze
  BOUNDARY = /([.?!][”’"')\]]*(?:#{MARKER})*(?:<\/[a-z]+>)*(?:#{MARKER})*)[ \u00A0]{2,}(?=\S)/o

  def self.split(html) = new(html).sentences

  def initialize(html)
    @html = html.to_s
  end

  def sentences
    pieces = @html.split(BOUNDARY).each_slice(2).map(&:join)
    balance(pieces).map { |piece| piece.gsub(/\s+/, " ").strip }.reject { |piece| plain(piece).blank? }
  end

  private
    def balance(pieces)
      open_tags = []
      pieces.map do |piece|
        reopened = open_tags.map { |tag| "<#{tag}>" }.join
        piece.scan(/<(\/?)([a-z]+)[^>]*>/) do |closing, name|
          closing.empty? ? open_tags.push(name) : open_tags.delete_at(open_tags.rindex(name) || open_tags.size)
        end
        reopened + piece + open_tags.reverse.map { |tag| "</#{tag}>" }.join
      end
    end

    def plain(html) = html.gsub(/<[^>]+>/, "").gsub(/#{MARKER}/o, "")
end
