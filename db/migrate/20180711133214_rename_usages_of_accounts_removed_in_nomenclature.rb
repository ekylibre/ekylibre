class RenameUsagesOfAccountsRemovedInNomenclature < ActiveRecord::Migration
  REMOVED_USAGES = %w{others_taxes interests_expenses tax_depreciation_revenues}
  def change
    reversible do |d|
      d.up do
        REMOVED_USAGES.each do |usage|
          execute <<-SQL
            UPDATE accounts AS ac
            SET usages = (SELECT usages
                          FROM accounts
                          WHERE number = ac.number)
            WHERE usages = '#{usage}'
          SQL
        end
      end

      d.down do
        # NOOP
      end
    end
  end
end
