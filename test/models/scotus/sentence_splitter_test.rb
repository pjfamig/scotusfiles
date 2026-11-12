require "test_helper"

class Scotus::SentenceSplitterTest < ActiveSupport::TestCase
  test "splits on two spaces after terminal punctuation but not after abbreviations" do
    html = "See <i>Reed</i> v. <i>Town of Gilbert</i>, 576 U. S. 155, 163.  Laws that only incidentally burden speech are different.  §129B.006(a)."

    assert_equal [
      "See <i>Reed</i> v. <i>Town of Gilbert</i>, 576 U. S. 155, 163.",
      "Laws that only incidentally burden speech are different.",
      "§129B.006(a)."
    ], Scotus::SentenceSplitter.split(html)
  end

  test "keeps closing quotes and footnote markers with the sentence they end" do
    marker = "#{Scotus::PdfLayout::FOOTNOTE_OPEN}2#{Scotus::PdfLayout::FOOTNOTE_CLOSE}"
    html = "It is “addictive.”#{marker}  The Legislature agreed."

    assert_equal [ "It is “addictive.”#{marker}", "The Legislature agreed." ], Scotus::SentenceSplitter.split(html)
  end

  test "closes and reopens inline tags that span a sentence boundary" do
    assert_equal [ "<i>It is so ordered.</i>", "<i>Next.</i>" ], Scotus::SentenceSplitter.split("<i>It is so ordered.  Next.</i>")
  end
end
