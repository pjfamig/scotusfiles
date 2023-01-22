class SetDefaultValueForUserIdInOpinions < ActiveRecord::Migration[7.0]
  def change
    change_column_default :opinions, :user_id, from: nil, to: 1
  end
end
