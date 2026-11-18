class AddHoldingAlerts < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :holding_alerts, :boolean, default: true, null: false
    add_column :decisions, :holding_alert_sent_at, :datetime
  end
end
