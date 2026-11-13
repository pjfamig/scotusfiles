module DecisionsHelper
  OPINION_TAGS = %w[section p span div h3 blockquote sup a i b em strong footer ol li].freeze
  OPINION_ATTRIBUTES = %w[id class href value data-key aria-label].freeze

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
