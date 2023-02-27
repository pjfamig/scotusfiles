require 'csv'

# Populate topics database

CSV.foreach(Rails.root.join('lib/seeds/2022_decisions_index.csv'), headers: true) do |row|
  # Construct full URL for PDF file
    pdf_url = "https://www.supremecourt.gov/opinions/22pdf/#{row["scotus_filename"]}"
  
  # Download PDF file
  pdf_data = URI.open(pdf_url)
  file_name = File.basename(row["scotus_filename"])
  
  # Save PDF file to local file system
  file_path = Rails.root.join('tmp', file_name)
  File.write(file_path, pdf_data)
  
 opinion = Opinion.new({
   user_id: "1",
   title: row["title"], 
   scotus_filename: pdf_url, 
   holding: row["holding"],
   full_decision: "Coming soon",
   decision_date: Date.strptime(row["decision_date"], "%m/%d/%Y"),
   created_at: Time.zone.now,
   updated_at: Time.zone.now
 })
 
 opinion.files.attach(io: pdf_data, filename: file_name) # Attach PDF file using Active Storage
 
 opinion.save!
 
end

p "All #{Opinion.count} Opinions successfully added to the database!"


# need to add command to upload PDF file for each case and fix show page for full_decision text