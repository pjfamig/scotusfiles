class CreateVotes < ActiveRecord::Migration[8.1]
  def change
    create_table :votes do |t|
      t.references :comment, null: false, foreign_key: { on_delete: :cascade }, index: false
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :direction, null: false
      t.timestamps
    end
    add_index :votes, %i[comment_id user_id], unique: true
    add_check_constraint :votes, "direction IN (-1, 1)", name: "votes_direction_is_up_or_down"

    change_table :comments, bulk: true do |t|
      t.integer :upvotes_count, default: 0, null: false
      t.integer :downvotes_count, default: 0, null: false
      t.integer :score, default: 0, null: false
    end
  end
end
