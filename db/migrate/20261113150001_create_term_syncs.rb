class CreateTermSyncs < ActiveRecord::Migration[8.1]
  def change
    create_table :term_syncs do |t|
      t.integer :term, null: false
      t.integer :listed_count
      t.integer :queued_count
      t.text :error
      t.datetime :created_at, null: false
    end
    add_index :term_syncs, :created_at
  end
end
