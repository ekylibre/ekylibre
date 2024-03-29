class UpdateStatusColumnOfReception < ActiveRecord::Migration[4.2]
  def change
    reversible do |dir|
      dir.up do
        execute "UPDATE parcels SET state = 'draft' WHERE state in ('ordered', 'in_preparation', 'prepared') AND nature = 'incoming'"
      end

      dir.down do
        # NOOP
      end
    end
  end
end
