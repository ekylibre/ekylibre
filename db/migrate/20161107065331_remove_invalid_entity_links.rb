class RemoveInvalidEntityLinks < ActiveRecord::Migration[4.2]
  def up
    execute 'DELETE FROM entity_links WHERE entity_id NOT IN (SELECT id FROM entities)'
    execute 'DELETE FROM entity_links WHERE linked_id NOT IN (SELECT id FROM entities)'
  end
end
