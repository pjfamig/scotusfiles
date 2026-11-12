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
    when "syllabus" then "bg-stone-200 text-stone-700 dark:bg-white/10 dark:text-stone-300"
    when "majority", "per_curiam", "plurality" then "bg-navy-100 text-navy-800 dark:bg-navy-600/40 dark:text-navy-100"
    when "dissent" then "bg-red-100 text-red-800 dark:bg-red-900/40 dark:text-red-200"
    when "concurrence" then "bg-emerald-100 text-emerald-800 dark:bg-emerald-900/40 dark:text-emerald-200"
    else "bg-gold-200 text-gold-600 dark:bg-gold-400/20 dark:text-gold-300"
    end
  end
end
