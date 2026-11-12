require "test_helper"

class Scotus::SlipOpinionIndexTest < ActiveSupport::TestCase
  test "parses decisions from the Court's term listing" do
    html = file_fixture("slip_opinions_ot2024.html").read
    entries = Scotus::SlipOpinionIndex.new(2024, html).entries

    assert_equal 3, entries.size
    goldey = entries.first
    assert_equal "Goldey v. Fields", goldey.title
    assert_equal "24-809", goldey.docket_number
    assert_equal Date.new(2025, 6, 30), goldey.decided_on
    assert_equal "PC", goldey.author_code
    assert_equal "606 U.S. 942", goldey.citation
    assert_equal "https://www.supremecourt.gov/opinions/24pdf/606us2r67_8nka.pdf", goldey.pdf_url
    assert_match(/Eighth Amendment/, goldey.holding)
  end

  test "reads four-digit years in the listing's dates" do
    html = file_fixture("slip_opinions_ot2024.html").read.sub(">6/30/25<", ">6/30/2025<")
    entries = Scotus::SlipOpinionIndex.new(2024, html).entries

    assert_equal Date.new(2025, 6, 30), entries.first.decided_on
  end

  test "computes the current October Term" do
    assert_equal 2026, Scotus::SlipOpinionIndex.current_term(on: Date.new(2026, 10, 5))
    assert_equal 2025, Scotus::SlipOpinionIndex.current_term(on: Date.new(2026, 6, 30))
  end
end
