class RemoveImmatterTypes < ActiveRecord::Migration
  def up
    execute "UPDATE products SET type='Product' WHERE type IN ('Immatter', 'Service')"
  end

  def down
    execute "UPDATE products SET type='Service' WHERE variety = 'service'"
    execute "UPDATE products SET type='Immatter' WHERE variety = 'immatter'"
  end
end
