class CreateComments < ActiveRecord::Migration[8.1]
  def change
    create_table :comments do |t|
      t.references :decision, null: false, foreign_key: true
      t.references :passage, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false

      t.timestamps
    end
    add_index :comments, [ :decision_id, :created_at ]
  end
end
