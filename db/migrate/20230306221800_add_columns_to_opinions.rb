class AddColumnsToOpinions < ActiveRecord::Migration[7.0]
  def change
    add_column :opinions, :syllabus, :text
    add_column :opinions, :majority_opinion, :text
    add_column :opinions, :dissent, :text
  end
end
