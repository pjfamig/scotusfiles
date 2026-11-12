# Creates an admin account and imports recent Supreme Court opinions straight
# from supremecourt.gov. Re-running is safe: existing records are reused.
#
#   bin/rails db:seed                      # current and previous term
#   SEED_TERMS=2023,2024 bin/rails db:seed
#   SEED_LIMIT=5 bin/rails db:seed         # only the newest N per term

admin = User.find_or_create_by!(email_address: ENV.fetch("ADMIN_EMAIL", "admin@example.com")) do |user|
  user.name = "Admin"
  user.password = ENV.fetch("ADMIN_PASSWORD", "password123")
  user.admin = true
end
puts "Admin account: #{admin.email_address}"

current = Scotus::SlipOpinionIndex.current_term
terms = ENV["SEED_TERMS"]&.split(",")&.map(&:to_i) || [ current, current - 1 ]
limit = ENV["SEED_LIMIT"]&.to_i

terms.each do |term|
  puts "OT #{term}: fetching index…"
  Decision.sync_term(term, enqueue: false)
  decisions = Decision.in_term(term).where.not(status: :imported).latest_first
  decisions = decisions.limit(limit) if limit

  decisions.each do |decision|
    decision.import!
    puts "  ✓ #{decision.title} (#{decision.passages.count} sentences)"
  rescue Scotus::PdfLayout::ConversionError, Scotus::Http::Error => error
    puts "  ✗ #{decision.title}: #{error.message}"
  end
end
