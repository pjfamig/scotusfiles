atom_feed(root_url: absolute_url(root_path), url: absolute_url(feed_path), schema_date: "2026", language: "en-US") do |feed|
  feed.title "New Supreme Court opinions · SCOTUSfiles"
  feed.subtitle SeoHelper::DEFAULT_DESCRIPTION
  feed.icon absolute_url("/icon.png")
  feed.updated @decisions.map { |decision| decision.imported_at || decision.updated_at }.max || Time.current

  @decisions.each do |decision|
    feed.entry decision, url: absolute_url(decision_path(decision)), published: decision.decided_on.in_time_zone,
        updated: decision.imported_at || decision.updated_at do |entry|
      entry.title decision_page_title(decision)
      entry.summary [ decision.holding, decision.per_curiam? ? "Per curiam." : "Opinion by Justice #{decision.author_name}." ].compact.join(" ")
      entry.category term: decision.term_label
      entry.author do |author|
        author.name "Supreme Court of the United States"
      end
    end
  end
end
