class UpdateInterventionStates < ActiveRecord::Migration
  def up
    execute "UPDATE interventions SET state = 'done'"
  end
end
