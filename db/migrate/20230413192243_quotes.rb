class Quotes < ActiveRecord::Migration[7.0]
  def change
    create_table :quotes do |t|
      t.text :content
      t.references :opinion, null: false, foreign_key: true

      t.timestamps
    end
  end
end
