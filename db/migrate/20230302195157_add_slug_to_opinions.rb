class AddSlugToOpinions < ActiveRecord::Migration[7.0]
  def change
    add_column :opinions, :slug, :string
    add_index :opinions, :slug, unique: true
  end
end
