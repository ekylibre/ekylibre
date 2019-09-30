class AddReadingCacheToProduct < ActiveRecord::Migration[4.2]
  def change
    add_column :products, :reading_cache, :jsonb, default: {}
  end
end
