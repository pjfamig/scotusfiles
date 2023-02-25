class AddFilenameToOpinions < ActiveRecord::Migration[7.0]
  def change
    add_column :opinions, :filename, :string
  end
end
