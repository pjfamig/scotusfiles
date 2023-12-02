require 'csv'

CSV.foreach(Rails.root.join('lib/seeds/2022_scotus_index.csv'), headers: true) do |row|
  # Construct full URL for PDF file
  pdf_url = row["url"]
  
  # Download PDF file
  pdf_data = URI.open(pdf_url)
  # file_name = File.basename(row["url"])
  

  # Add code to generate HTML file for full_decision
  temporary_text = "<h2>Opinion coming soon!</h2>".html_safe
  
  # Save the PDF file to S3
  # don't need this because Active Storage already set up to use S3
  # object_key = "opinions/pdf/#{file_name}"
  # s3.bucket(bucket_name).object(object_key).put(body: pdf_data)
  # p "#{file_name} PDF saved to S3!"
  
  # Save the HTML content to S3
  # filename = "#{row["title"].parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}.html"
  # File.write(Rails.root.join('public', 'opinions', filename), full_decision_html)
  
  
  # p "#{filename} HTML saved locally!"
    
 opinion = Opinion.new({
   user_id: "1",
   title: row["title"], 
   scotus_filename: pdf_url, 
   holding: temporary_text,
   full_decision: temporary_text,
   decision_date: Date.strptime(row["date"], "%m/%d/%Y"),
   # filename: filename,
   syllabus: temporary_text,
   majority_opinion: temporary_text,
   dissent: temporary_text,
   created_at: Time.zone.now,
   updated_at: Time.zone.now
 })
  
 # opinion.files.attach(io: pdf_data, filename: file_name) # Attach PDF file using Active Storage
 # p "#{file_name} saved to S3"
 
 opinion.save!
 
 p "#{opinion.title} saved to the database!"

end

p "All #{Opinion.count} Opinions successfully added to the database!"
