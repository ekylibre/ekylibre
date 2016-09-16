class AddPartnerUrlToSensors < ActiveRecord::Migration
  def change
    add_column :sensors, :partner_url, :string
  end
end
