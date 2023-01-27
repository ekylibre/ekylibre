class AddLastSyncAtToIntegration < ActiveRecord::Migration[4.2]
  def change
    add_column :integrations, :last_sync_at, :datetime
  end
end
