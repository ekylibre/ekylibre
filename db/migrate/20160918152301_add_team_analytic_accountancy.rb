class AddTeamAnalyticAccountancy < ActiveRecord::Migration
  def change
    add_reference :purchase_items, :team, index: true
    add_reference :sale_items, :team, index: true
    add_reference :journal_entry_items, :team, index: true
    add_reference :products, :team, index: true

    execute "UPDATE products AS p SET team_id = (SELECT team_id FROM users as u WHERE u.person_id = (SELECT id FROM entities as e WHERE e.id = p.id))"

  end
end
