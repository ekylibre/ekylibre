class AddAssociatedCashes < ActiveRecord::Migration[4.2]
  def change
    add_reference :cashes, :owner, index: true
  end
end
