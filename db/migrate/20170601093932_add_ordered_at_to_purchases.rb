class AddOrderedAtToPurchases < ActiveRecord::Migration
  def change
    add_column :purchases, :ordered_at, :datetime
  end
end
