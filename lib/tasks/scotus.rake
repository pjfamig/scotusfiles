namespace :scotus do
  desc "Sync a term's decisions from supremecourt.gov and import them now (TERM=2025, defaults to the current term)"
  task sync: :environment do
    # Shells set TERM to the terminal type ("xterm"), so only a year counts as a term.
    term = ENV["TERM"].to_s.match?(/\A\d{4}\z/) ? ENV["TERM"].to_i : Scotus::SlipOpinionIndex.current_term
    Decision.sync_term(term, enqueue: false)
    Decision.in_term(term).where.not(status: :imported).latest_first.each do |decision|
      decision.import!
      puts "✓ #{decision.title}"
    rescue Scotus::PdfLayout::ConversionError, Scotus::Http::Error => error
      puts "✗ #{decision.title}: #{error.message}"
    end
  end

  desc "Re-import every decision (after improving the converter)"
  task reimport: :environment do
    Decision.find_each do |decision|
      decision.import!
      puts "✓ #{decision.title}"
    rescue Scotus::PdfLayout::ConversionError, Scotus::Http::Error => error
      puts "✗ #{decision.title}: #{error.message}"
    end
  end
end
