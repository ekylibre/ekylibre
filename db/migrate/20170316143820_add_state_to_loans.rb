class AddStateToLoans < ActiveRecord::Migration
  def change
    add_column :loans, :state, :string
  end
end
