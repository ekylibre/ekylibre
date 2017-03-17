class AddStateToLoans < ActiveRecord::Migration
  def change
    add_column :loans, :state, :string
    add_column :loans, :ongoing_at, :datetime
    add_column :loans, :repaid_at, :datetime

    execute "UPDATE loans SET state = 'ongoing', ongoing_at = NOW()"
  end
end
