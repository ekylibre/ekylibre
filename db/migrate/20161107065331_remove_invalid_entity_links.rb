class RemoveInvalidEntityLinks < ActiveRecord::Migration
  def up
    execute 'DELETE FROM entity_links WHERE entity_id NOT IN (SELECT id FROM entities)'
    execute 'DELETE FROM entity_links WHERE linked_id NOT IN (SELECT id FROM entities)'
  end
end
