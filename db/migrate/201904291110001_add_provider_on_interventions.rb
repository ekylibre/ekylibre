class AddProviderOnInterventions < ActiveRecord::Migration
  def up
    # add providers colums to store pairs on provider / id number on article
    add_column :interventions, :providers, :jsonb
  end

  def down
    remove_column :interventions, :providers
  end
end
