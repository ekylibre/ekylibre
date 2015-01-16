class AddAssociatedCashes < ActiveRecord::Migration
  def change
   add_reference :cashes, :owner, index: true
  end
end
