class AddScotusFilenameToOpinions < ActiveRecord::Migration[7.0]
  def change
    add_column :opinions, :scotus_filename, :string
  end
end
