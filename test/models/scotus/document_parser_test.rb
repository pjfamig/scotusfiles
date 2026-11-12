require "test_helper"

class Scotus::DocumentParserTest < ActiveSupport::TestCase
  test "splits a slip opinion into syllabus, majority, and dissent with footnotes" do
    sections = parse("free_speech_coalition_v_paxton_slip.pdf")

    assert_equal [ "Syllabus", "Opinion of the Court", "KAGAN, J., dissenting" ], sections.map(&:label)
    assert_equal (1..14).to_a, sections.second.footnotes.map(&:number)
    assert_equal [ 1, 2, 3 ], sections.third.footnotes.map(&:number)

    majority = sections.second.blocks
    assert_equal %i[notice banner caption paragraph paragraph heading heading], majority.first(7).map(&:type)
    assert_equal "JUSTICE THOMAS delivered the opinion of the Court.", majority[3].html
    assert majority.any? { |block| block.type == :flush_right && block.html.include?("It is so ordered") }
  end

  test "rejoins hyphenated words and keeps italics" do
    first_paragraph = parse("free_speech_coalition_v_paxton_slip.pdf").second.blocks.find { |block| block.type == :paragraph && block.html.start_with?("Texas") }

    assert_includes first_paragraph.html, "distribution of sexually explicit content to children."
    assert_includes parse("free_speech_coalition_v_paxton_slip.pdf").second.blocks.map(&:html).join, "<i>Ibid</i>"
  end

  test "handles bound-volume preliminary prints whose opinions start mid-page" do
    sections = parse("nrcc_v_brown_preliminary_print.pdf")

    assert_equal [ "Syllabus", "Per Curiam", "JACKSON, J., dissenting" ], sections.map(&:label)
    text = sections.flat_map(&:blocks).map(&:html).join(" ")
    assert_not_includes text, "Page Proof Pending Publication"
    assert_not_includes text, "PRELIMINARY"
    assert_includes text, "filed an application"
    assert sections.second.blocks.any? { |block| block.type == :flush_right && block.html.include?("It is so ordered") }
  end

  private
    def parse(name)
      @parsed ||= {}
      @parsed[name] ||= Scotus::DocumentParser.parse(Scotus::PdfLayout.from_pdf(file_fixture(name)))
    end
end
