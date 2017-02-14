class AddTeamAnalyticAccountancy < ActiveRecord::Migration
  def change
    add_reference :purchase_items, :team, index: true
    add_reference :sale_items, :team, index: true
    add_reference :journal_entry_items, :team, index: true
    add_reference :products, :team, index: true

    reversible do |d|
      d.up do
        execute 'UPDATE products AS p SET team_id = u.team_id FROM users AS u WHERE p.person_id = u.person_id'
      end
    end
  end
end
