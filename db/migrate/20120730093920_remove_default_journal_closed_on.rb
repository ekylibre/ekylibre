class RemoveDefaultJournalClosedOn < ActiveRecord::Migration
  def up
    change_column_default :journals, :closed_on, nil
  end

  def down
    change_column_default :journals, :closed_on, Date.civil(1970,12,31)
  end
end
