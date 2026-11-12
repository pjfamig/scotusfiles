class CreateDecisions < ActiveRecord::Migration[8.1]
  def change
    create_table :decisions do |t|
      t.integer :term, null: false
      t.string :docket_number, null: false
      t.string :title, null: false
      t.string :slug, null: false
      t.date :decided_on
      t.string :citation
      t.text :holding
      t.string :author_code
      t.string :pdf_url, null: false
      t.integer :status, null: false, default: 0
      t.text :import_error
      t.datetime :imported_at
      t.integer :comments_count, null: false, default: 0

      t.timestamps
    end
    add_index :decisions, :slug, unique: true
    add_index :decisions, [ :docket_number, :decided_on ], unique: true
    add_index :decisions, [ :term, :decided_on ]
  end
end
