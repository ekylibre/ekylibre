class UpdateOutputTransportHarvesting < ActiveRecord::Migration[5.2]
  def change
    add_reference :incoming_harvest_crops, :harvest_intervention, index: true
    add_reference :incoming_harvest_storages, :product, index: true
    rename_column :incoming_harvest_crops, :harvest_percentage_received, :harvest_percentage_repartition
  end
end
