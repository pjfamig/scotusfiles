class CreateDecisionImports < ActiveRecord::Migration[8.1]
  def change
    create_table :decision_imports do |t|
      t.references :decision, null: false, foreign_key: { on_delete: :cascade }
      t.boolean :refresh, default: false, null: false
      t.boolean :succeeded, null: false
      t.text :error
      t.integer :duration_ms
      t.integer :passages_count
      t.datetime :created_at, null: false
    end
    add_index :decision_imports, :created_at
  end
end
