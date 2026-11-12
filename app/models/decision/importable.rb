module Decision::Importable
  extend ActiveSupport::Concern

  class_methods do
    # Creates or updates decisions from the Court's listing for a term and
    # queues imports for anything new or revised.
    def sync_term(term, enqueue: true)
      Scotus::SlipOpinionIndex.fetch(term).filter_map do |entry|
        decision = find_or_initialize_by(docket_number: entry.docket_number, decided_on: entry.decided_on)
        revised = decision.persisted? && decision.pdf_url != entry.pdf_url
        decision.assign_attributes(entry.to_h.except(:docket_number, :decided_on))
        decision.status = :pending if revised
        decision.save!
        decision if decision.pending?
      end.tap { |decisions| decisions.each(&:import_later) if enqueue }
    end
  end

  def import_later
    ImportDecisionJob.perform_later(self)
  end

  def import!(pdf_path: nil)
    importing!
    sections = with_pdf(pdf_path) { |path| Scotus::DocumentParser.parse(Scotus::PdfLayout.from_pdf(path)) }
    raise Scotus::PdfLayout::ConversionError, "No opinion text found in PDF" if sections.empty?

    store(Scotus::Formatter.format(sections))
    update!(status: :imported, imported_at: Time.current, import_error: nil)
    broadcast_refresh_later
    broadcast_refresh_later_to :decisions
  rescue Scotus::PdfLayout::ConversionError, Scotus::Http::Error => error
    update!(status: :failed, import_error: error.message)
    broadcast_refresh_later
    raise
  end

  private
    def with_pdf(path)
      return yield(path) if path

      Tempfile.create([ "decision-#{id}", ".pdf" ], binmode: true) do |file|
        file.write(Scotus::Http.get(pdf_url))
        file.flush
        yield file.path
      end
    end

    # Re-imports keep passage keys stable, so comments stay attached to their
    # sentences. Passages that disappear are kept only if someone discussed them.
    def store(formatted_opinions)
      transaction do
        kept_opinions = formatted_opinions.map do |formatted|
          opinion = opinions.find_or_initialize_by(position: formatted.position)
          opinion.update!(formatted.to_h.slice(:kind, :label, :author).merge(body_html: formatted.html))
          [ opinion, formatted.passages ]
        end
        opinions.where.not(id: kept_opinions.map { |opinion, _| opinion.id }).destroy_all

        rows = kept_opinions.flat_map do |opinion, formatted_passages|
          formatted_passages.map do |passage|
            { decision_id: id, opinion_id: opinion.id, key: passage.key, position: passage.position, text: passage.text }
          end
        end
        passages.upsert_all(rows, unique_by: %i[decision_id key], update_only: %i[opinion_id position text]) if rows.any?
        passages.where.not(key: rows.map { |row| row[:key] }).where(comments_count: 0).delete_all
      end
    end
end
