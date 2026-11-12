class CreateOpinions < ActiveRecord::Migration[8.1]
  def change
    create_table :opinions do |t|
      t.references :decision, null: false, foreign_key: true
      t.integer :kind, null: false, default: 0
      t.string :label, null: false
      t.string :author
      t.integer :position, null: false
      t.text :body_html, null: false, default: ""

      t.timestamps
    end
    add_index :opinions, [ :decision_id, :position ], unique: true
  end
end
