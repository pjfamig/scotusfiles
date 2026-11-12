class CreatePassages < ActiveRecord::Migration[8.1]
  def change
    create_table :passages do |t|
      t.references :decision, null: false, foreign_key: true
      t.references :opinion, foreign_key: { on_delete: :nullify }
      t.string :key, null: false
      t.integer :position, null: false
      t.text :text, null: false
      t.integer :comments_count, null: false, default: 0

      t.timestamps
    end
    add_index :passages, [ :decision_id, :key ], unique: true
  end
end
