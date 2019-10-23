class UpdateExistingEuVatAccountUsages < ActiveRecord::Migration
  def change

    reversible do |d|
      d.up do
        execute <<-SQL
          UPDATE accounts
          SET usages = 'collected_intra_eu_vat'
          WHERE number LIKE '4452%'
        SQL
      end

      d.down do
        # NOOP
      end
    end
  end
end
