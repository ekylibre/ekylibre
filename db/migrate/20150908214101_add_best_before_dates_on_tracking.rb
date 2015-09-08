class AddBestBeforeDatesOnTracking < ActiveRecord::Migration
  def change
    add_column :trackings, :used_by_on, :date
    add_column :trackings, :used_by_type, :string
  end
end
