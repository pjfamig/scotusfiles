require "test_helper"

class DecisionTest < ActiveSupport::TestCase
  test "imports a PDF into opinions with commentable passages" do
    decision = decisions(:pending)
    decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))

    assert decision.reload.imported?
    assert_equal %w[syllabus majority dissent], decision.opinions.map(&:kind)
    assert_equal "Thomas", decision.opinions.second.author
    assert_equal "Justice Kagan, dissenting", decision.opinions.third.title

    passage = decision.passages.find_by!(key: "2-1")
    assert_equal "JUSTICE THOMAS delivered the opinion of the Court.", passage.text
    assert_includes decision.opinions.second.body_html, %(<span class="sentence" id="s-2-1" data-key="2-1">)
    assert_includes decision.opinions.second.body_html, %(<a href="#fn-2-1" id="fnref-2-1">1</a>)
  end

  test "re-importing keeps passage keys and the comments attached to them" do
    decision = decisions(:pending)
    decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
    passage = decision.passages.find_by!(key: "2-5")
    comment = decision.comments.create!(passage: passage, user: users(:one), body: "Worth rereading.")

    assert_no_difference -> { decision.passages.count } do
      decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
    end
    assert_equal passage, comment.reload.passage
    assert_equal passage.text, decision.passages.find_by!(key: "2-5").text
  end

  test "marks the decision failed when the PDF cannot be read" do
    decision = decisions(:pending)
    Tempfile.create([ "broken", ".pdf" ]) do |file|
      file.write("not a pdf")
      file.flush
      assert_raises(Scotus::PdfLayout::ConversionError) { decision.import!(pdf_path: file.path) }
    end
    assert decision.reload.failed?
  end

  test "logs first imports, refreshes, and failures" do
    decision = decisions(:pending)
    decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
    decision.import!(pdf_path: file_fixture("free_speech_coalition_v_paxton_slip.pdf"))
    Tempfile.create([ "broken", ".pdf" ]) do |file|
      file.write("not a pdf")
      file.flush
      assert_raises(Scotus::PdfLayout::ConversionError) { decision.import!(pdf_path: file.path) }
    end

    first, refresh, failure = decision.imports.order(:id).to_a
    assert first.succeeded?
    assert_not first.refresh?
    assert_equal decision.passages.count, first.passages_count
    assert refresh.refresh?
    assert_not failure.succeeded?
    assert failure.error.present?
  end

  test "logs each term sync" do
    entries = Scotus::SlipOpinionIndex.new(2024, file_fixture("slip_opinions_ot2024.html").read).entries
    original = Scotus::SlipOpinionIndex.method(:fetch)
    Scotus::SlipOpinionIndex.define_singleton_method(:fetch) { |_term| entries }

    assert_difference -> { TermSync.count } do
      Decision.sync_term(2024, enqueue: false)
    end
    assert_equal [ 2024, 3, 3 ], TermSync.last.slice(:term, :listed_count, :queued_count).values
  ensure
    Scotus::SlipOpinionIndex.define_singleton_method(:fetch, original)
  end

  test "builds a readable slug from the title and docket" do
    decision = Decision.create!(term: 2025, docket_number: "24-1287", title: "Learning Resources, Inc. v. Trump", pdf_url: "https://example.com/a.pdf")
    assert_equal "learning-resources-inc-v-trump-24-1287", decision.to_param
  end
end
