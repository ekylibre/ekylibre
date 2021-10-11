class AddPartnerUrlToSensors < ActiveRecord::Migration[4.2]
  def change
    add_column :sensors, :partner_url, :string
  end
end
