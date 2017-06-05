class MakeStatesNonNullInPurchases < ActiveRecord::Migration
  def change
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE purchases
          SET state = 'draft'
          WHERE state IS NULL;
        SQL
      end

      dir.down do
        # NOOP
      end
    end

    change_column :purchases, :state, :string, null: false
  end
end
