require "test_helper"

class Scotus::LineJoinerTest < ActiveSupport::TestCase
  test "removes end-of-line hyphenation" do
    assert_equal "prohibits the distribution of sexually explicit", Scotus::LineJoiner.new.join([ "prohibits the distribution of sex-", "ually explicit" ])
  end

  test "keeps hyphens in compounds that appear unbroken elsewhere in the document" do
    joiner = Scotus::LineJoiner.new([ "all age-verification requirements" ])

    assert_equal "an age-verification law", joiner.join([ "an age-", "verification law" ])
  end

  test "marks sentence ends at line breaks but not abbreviations" do
    joiner = Scotus::LineJoiner.new

    assert_equal "We hold that they do not.  The power", joiner.join([ "We hold that they do not.", "The power" ])
    assert_equal "Tex. Penal Code Ann. §43.24(b)", joiner.join([ "Tex. Penal Code Ann.", "§43.24(b)" ])
    assert_equal "576 U. S. 155", joiner.join([ "576 U.", "S. 155" ])
  end

  test "re-derives sentence spacing when lines are justified with extra spaces" do
    lines = Array.new(10) { "likely  to  succeed  on  the  merits  of  their  argument" }
    joiner = Scotus::LineJoiner.new(lines)

    assert_equal "I would deny the stay.  In my view, see 558 U. S. 183.",
      joiner.join([ "I  would  deny  the  stay.  In  my", "view, see 558 U.  S.  183." ])
  end
end
