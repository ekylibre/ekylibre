class UpdateInterventionStates < ActiveRecord::Migration[4.2]
  def up
    execute "UPDATE interventions SET state = 'done'"
  end
end
