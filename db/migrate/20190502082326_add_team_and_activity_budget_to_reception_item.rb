class AddTeamAndActivityBudgetToReceptionItem < ActiveRecord::Migration
  def change

    add_reference :parcel_items, :activity_budget, foreign_key: true
    add_reference :parcel_items, :team, foreign_key: true

  end
end
