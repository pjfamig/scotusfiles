class AddConcurrenceToOpinions < ActiveRecord::Migration[7.0]
  def change
    add_column :opinions, :concurrence, :text
  end
end
