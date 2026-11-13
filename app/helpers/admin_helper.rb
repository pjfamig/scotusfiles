module AdminHelper
  def admin_time_zone
    ActiveSupport::TimeZone[ENV.fetch("ADMIN_TIME_ZONE", "Pacific Time (US & Canada)")] || Time.zone
  end

  def admin_time(time)
    return "—" unless time

    local = time.in_time_zone(admin_time_zone)
    time_tag time, "#{time_ago_in_words(time)} ago", title: local.strftime("%b %-d, %Y %-l:%M %p %Z")
  end

  def admin_nav_link(label, path)
    current = current_page?(path)
    link_to label, path, aria: { current: ("page" if current) },
      class: class_names("rounded-full px-3.5 py-1.5 text-sm font-medium transition-colors duration-150",
        "bg-neutral-950 text-white dark:bg-white dark:text-neutral-950": current,
        "text-neutral-600 hover:bg-neutral-100 hover:text-neutral-950 dark:text-neutral-300 dark:hover:bg-neutral-800 dark:hover:text-white": !current)
  end

  def admin_card_classes
    "rounded-2xl border border-neutral-200 bg-white dark:border-neutral-800 dark:bg-neutral-900"
  end

  def admin_pill(label, tone)
    tones = {
      green: "bg-emerald-50 text-emerald-700 dark:bg-emerald-500/15 dark:text-emerald-200",
      red: "bg-red-50 text-red-700 dark:bg-red-500/15 dark:text-red-200",
      amber: "bg-amber-50 text-amber-800 dark:bg-amber-500/15 dark:text-amber-200",
      blue: "bg-accent-50 text-accent-700 dark:bg-accent-500/15 dark:text-accent-200",
      gray: "bg-neutral-100 text-neutral-700 dark:bg-neutral-800 dark:text-neutral-300"
    }
    tag.span label, class: "inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium #{tones.fetch(tone)}"
  end

  def decision_status_pill(decision)
    tone = { "imported" => :green, "failed" => :red }.fetch(decision.status, :amber)
    admin_pill decision.status.humanize, tone
  end

  def import_pill(import)
    return admin_pill("Failed", :red) unless import.succeeded?

    import.refresh? ? admin_pill("Refresh", :blue) : admin_pill("First import", :green)
  end
end
