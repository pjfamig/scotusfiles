require 'csv'

CSV.foreach(Rails.root.join('lib/seeds/2022_decisions_index.csv'), headers: true) do |row|
  # Construct full URL for PDF file
  
  pdf_url = row["scotus_filename"]
  
  # Download PDF file
  pdf_data = URI.open(pdf_url)
  file_name = File.basename(row["scotus_filename"])
  
  # Save PDF file to local file system
  file_path = Rails.root.join('tmp', file_name)
  File.write(file_path, pdf_data)
  
  # Add code to generate HTML file for full_decision
  full_decision = "<h1>Coming soon!</h1>"
  full_decision_html = full_decision.html_safe
  
  # Save the HTML content to a separate file
  filename = "#{row["title"].parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}.html"
  File.write(Rails.root.join('public', 'opinions', filename), full_decision_html)
  
 opinion = Opinion.new({
   user_id: "1",
   title: row["title"], 
   scotus_filename: pdf_url, 
   holding: row["holding"],
   full_decision: full_decision_html,
   decision_date: Date.strptime(row["decision_date"], "%m/%d/%Y"),
   filename: filename,
   created_at: Time.zone.now,
   updated_at: Time.zone.now
 })
  
 opinion.files.attach(io: pdf_data, filename: file_name) # Attach PDF file using Active Storage
 
 opinion.save!
 
end

p "All #{Opinion.count} Opinions successfully added to the database!"
