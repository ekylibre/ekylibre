class UpdateLandParcelDeadAt < ActiveRecord::Migration
  def up
    execute "UPDATE products AS lp SET initial_dead_at = ap.stopped_on FROM activity_productions AS ap WHERE ap.support_id = lp.id AND lp.type = 'LandParcel' AND initial_dead_at IS NULL"
    execute "UPDATE products AS lp SET dead_at = initial_dead_at WHERE dead_at IS NULL AND initial_dead_at IS NOT NULL AND lp.id IN (SELECT support_id FROM activity_productions) AND lp.type = 'LandParcel'"
  end
end
