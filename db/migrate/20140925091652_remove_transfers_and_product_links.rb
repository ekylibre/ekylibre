class RemoveTransfersAndProductLinks < ActiveRecord::Migration[4.2]
  def change
    drop_table :transfers
  end
end
