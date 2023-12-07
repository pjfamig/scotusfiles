require 'csv'

CSV.foreach(Rails.root.join('lib/seeds/2022_scotus_index_with_opinions.csv'), headers: true) do |row|
  pdf_url = row["url"]
  temporary_text = "Coming soon!"
  opinion = Opinion.new({
   user_id: "1",
   title: row["title"], 
   scotus_filename: pdf_url, 
   holding: row["holding"],
   full_decision: temporary_text,
   decision_date: Date.strptime(row["date"], "%m/%d/%Y"),
   # filename: filename,
   syllabus: row["syllabus"],
   majority_opinion: row["majority_opinion"],
   concurrence: row["concurrence"],
   dissent: row["dissent"],
   created_at: Time.zone.now,
   updated_at: Time.zone.now
 })
 opinion.save!
 p "#{opinion.title} saved to the database!"
end

p "All #{Opinion.count} 2022 opinions successfully added to the database!"

CSV.foreach(Rails.root.join('lib/seeds/2023_scotus_index_with_opinions.csv'), headers: true) do |row|
  pdf_url = row["url"]
  temporary_text = "Coming soon!"
  opinion = Opinion.new({
   user_id: "1",
   title: row["title"], 
   scotus_filename: pdf_url, 
   holding: row["holding"],
   full_decision: temporary_text,
   decision_date: Date.strptime(row["date"], "%m/%d/%Y"),
   # filename: filename,
   syllabus: row["syllabus"],
   majority_opinion: row["majority_opinion"],
   concurrence: row["concurrence"],
   dissent: row["dissent"],
   created_at: Time.zone.now,
   updated_at: Time.zone.now
 })
 opinion.save!
 p "#{opinion.title} saved to the database!"
end

p "All #{Opinion.count} 2023 opinions successfully added to the database!"
