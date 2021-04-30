class AddLastSyncAtToIntegration < ActiveRecord::Migration
  def change
    add_column :integrations, :last_sync_at, :datetime
  end
end
