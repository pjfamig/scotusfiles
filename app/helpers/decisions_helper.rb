module DecisionsHelper
  OPINION_TAGS = %w[section p span div h3 blockquote sup a i b em strong footer ol li].freeze
  OPINION_ATTRIBUTES = %w[id class href value data-key aria-label].freeze

  def cached_terms = @cached_terms ||= Decision.terms

  # The newest term is what the home page lists, so link there rather than to a duplicate /terms/:term page.
  def term_listing_path(term)
    term.to_i == cached_terms.first ? root_path : term_path(term)
  end

  def decision_year(decision) = (decision.decided_on || decision.created_at).year

  def decision_page_title(decision)
    citation = decision.official_citation || "No. #{decision.docket_number}"
    "#{decision.title}, #{citation} (#{decision_year(decision)})"
  end

  def decision_authorship(decision, opinions)
    lead = decision.per_curiam? ? "Per curiam opinion" : "Opinion by Justice #{decision.author_name}"
    separate = opinions.select { |opinion| opinion.concurrence? || opinion.dissent? }.map(&:title)
    "#{[ lead, *separate ].join('; ')}."
  end

  def decision_meta_description(decision, opinions)
    decided = decision.decided_on ? ", decided #{decision.decided_on.strftime('%B %-d, %Y')}" : ""
    holding = decision.holding.to_s.squish.delete_suffix(".")
    holding = holding.length > 160 ? "#{holding.truncate(160, separator: ' ', omission: '')}…" : "#{holding}." if holding.present?
    description = [ "#{decision.title} (No. #{decision.docket_number}#{decided}).", holding.presence, decision_authorship(decision, opinions) ].compact.join(" ")
    call_to_action = "Read the full opinion and discuss it sentence by sentence."
    description.length + call_to_action.length < 320 ? "#{description} #{call_to_action}" : description
  end

  def decision_schema(decision, opinions)
    url = absolute_url(decision_path(decision))
    {
      "@context": "https://schema.org",
      "@type": "Article",
      "@id": "#{url}#opinion",
      headline: decision.title.truncate(110, separator: " "),
      name: decision_page_title(decision),
      alternativeHeadline: "#{decision.title}, No. #{decision.docket_number}",
      description: decision.holding.presence || decision_authorship(decision, opinions),
      url: url,
      mainEntityOfPage: { "@type": "WebPage", "@id": url },
      image: og_image_url,
      datePublished: decision.decided_on&.iso8601,
      dateModified: (decision.imported_at || decision.updated_at).iso8601,
      author: SeoHelper::SUPREME_COURT,
      creator: decision.per_curiam? ? nil : { "@type": "Person", name: "Justice #{decision.author_name}" },
      publisher: publisher_schema,
      isBasedOn: decision.pdf_url,
      identifier: [ "No. #{decision.docket_number}", decision.official_citation ].compact,
      articleSection: decision.term_label,
      keywords: [ "Supreme Court", "SCOTUS", "opinion", decision.term_label, decision.docket_number, decision.official_citation ].compact.join(", "),
      hasPart: opinions.map { |opinion| { "@type": "CreativeWork", name: [ opinion.title, opinion.byline ].compact.join(", "), url: "#{url}##{opinion.anchor}" } },
      commentCount: decision.comments_count,
      discussionUrl: url,
      inLanguage: "en-US",
      isAccessibleForFree: true,
      copyrightNotice: "U.S. Supreme Court opinions are works of the United States government and are in the public domain."
    }.compact
  end

  def term_meta_description(term, count)
    "All #{pluralize(count, 'Supreme Court opinion')} from October Term #{term} (#{term}–#{(term + 1).to_s.last(2)}), " \
      "with holdings, majority opinions, concurrences, and dissents in clean, readable text you can discuss sentence by sentence."
  end

  def sanitize_opinion(html)
    sanitize(html, tags: OPINION_TAGS, attributes: OPINION_ATTRIBUTES)
  end

  def opinion_kind_name(opinion)
    {
      "syllabus" => "Syllabus", "majority" => "Majority", "per_curiam" => "Per curiam", "plurality" => "Plurality",
      "concurrence" => "Concurrence", "dissent" => "Dissent", "statement" => "Statement"
    }.fetch(opinion.kind, "Opinion")
  end

  def opinion_kind_classes(opinion)
    case opinion.kind
    when "majority", "per_curiam", "plurality" then "border-neutral-950 bg-neutral-950 text-white dark:border-white dark:bg-white dark:text-neutral-950"
    when "dissent" then "border-neutral-950 text-neutral-950 dark:border-white dark:text-white"
    else "border-neutral-300 text-neutral-500 dark:border-neutral-700 dark:text-neutral-400"
    end
  end
end
