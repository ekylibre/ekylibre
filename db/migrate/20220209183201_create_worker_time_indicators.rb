class CreateWorkerTimeIndicators < ActiveRecord::Migration[5.0]
  def change
    create_view :worker_time_indicators, materialized: true

    add_index :worker_time_indicators, :worker_id
    add_index :worker_time_indicators, :start_at
    add_index :worker_time_indicators, :stop_at
  end
end
