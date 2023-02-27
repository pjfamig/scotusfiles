require 'csv'

# Populate topics database

CSV.foreach(Rails.root.join('lib/seeds/2022_decisions_index.csv'), headers: true) do |row|
 Opinion.create({
   user_id: "1",
   title: row["title"], 
   scotus_filename: row["scotus_filename"], 
   holding: row["holding"],
   full_decision: "Coming soon",
   created_at: Time.zone.now,
   updated_at: Time.zone.now
 })
end

p "All #{Opinion.count} Opinions successfully added to the database!"


# need to add command to upload PDF file for each case and fix show page for full_decision text