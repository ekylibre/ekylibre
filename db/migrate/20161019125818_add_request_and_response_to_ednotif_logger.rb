class AddRequestAndResponseToEdnotifLogger < ActiveRecord::Migration
  def change
    add_column :ednotif_loggers, :request, :jsonb
    add_column :ednotif_loggers, :response, :jsonb
  end
end
