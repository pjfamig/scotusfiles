class AddHighlightColorToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :highlight_color, :string, default: "yellow", null: false
  end
end
