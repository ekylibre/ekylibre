class RenameUsagesOfAccountsRemovedInNomenclature < ActiveRecord::Migration[4.2]
  USAGES_TO_RENAME = {
    others_taxes: 'government_tax_expenses',
    interests_expenses: 'loans_interests',
    tax_depreciation_revenues: 'exceptional_depreciations_inputations_revenues',
    # Following account are just minor renaming, they are not removed from nomenclature
    exceptionnal_charge_transfer_revenues: 'exceptional_charge_transfer_revenues',
    exceptionnal_depreciations_inputations_expenses: 'exceptional_depreciations_inputations_expenses',
    exceptionnal_incorporeal_asset_depreciation_revenues: 'exceptional_incorporeal_asset_depreciation_revenues'
  }.freeze

  def change
    reversible do |d|
      d.up do
        USAGES_TO_RENAME.each do |usage, new_usage|
          execute <<-SQL
            UPDATE accounts AS ac
            SET usages = '#{new_usage}'
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
