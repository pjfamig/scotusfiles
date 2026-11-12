# Reads the Court's per-term slip opinion listing, e.g.
# https://www.supremecourt.gov/opinions/slipopinion/25
class Scotus::SlipOpinionIndex
  BASE_URL = "https://www.supremecourt.gov".freeze

  Entry = Struct.new(:term, :docket_number, :title, :decided_on, :holding, :author_code, :citation, :pdf_url, keyword_init: true)

  def self.url_for(term) = "#{BASE_URL}/opinions/slipopinion/#{term % 100}"

  def self.fetch(term)
    new(term, Scotus::Http.get(url_for(term))).entries
  end

  def self.current_term(on: Date.current)
    on.month >= 10 ? on.year : on.year - 1
  end

  def initialize(term, html)
    @term = term
    @document = Nokogiri::HTML(html)
  end

  def entries
    rows.filter_map { |row| parse_row(row) }.uniq(&:pdf_url)
  end

  private
    def rows
      @document.css("table").select { |table| table.at_css("th")&.text.to_s.match?(/R-/) }.flat_map { |table| table.css("tr") }
    end

    def parse_row(row)
      cells = row.css("td")
      link = cells[3]&.at_css("a[href$='.pdf']")
      return unless cells.size >= 6 && link

      Entry.new(
        term: @term,
        decided_on: parse_date(cells[1].text.strip),
        docket_number: cells[2].text.squish,
        title: link.text.squish,
        holding: link["title"].to_s.squish.presence,
        author_code: cells[4].text.squish.presence,
        citation: cells[5].text.squish.presence,
        pdf_url: URI.join(BASE_URL, link["href"]).to_s
      )
    end

    # The listing writes two-digit years ("11/09/26") but occasionally four ("10/14/2026").
    def parse_date(text)
      Date.strptime(text, text.match?(%r{/\d{4}\z}) ? "%m/%d/%Y" : "%m/%d/%y")
    rescue Date::Error
      nil
    end
end
