class CreateOpinions < ActiveRecord::Migration[7.0]
  def change
    create_table :opinions do |t|
      t.string :title
      t.text :holding
      t.text :full_decision
      t.date :decision_date

      t.timestamps
    end
  end
end
