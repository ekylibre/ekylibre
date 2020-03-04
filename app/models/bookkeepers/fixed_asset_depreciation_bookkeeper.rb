class FixedAssetDepreciationBookkeeper < Ekylibre::Bookkeeper
  def call
    return unless accountable

    if fixed_asset.in_use?
      bookkeep_in_use
    elsif fixed_asset.sold?
      bookkeep_sold
    elsif fixed_asset.scrapped?
      bookkeep_scrapped
    end
  end

  private

    def bookkeep_in_use
      return if fixed_asset.depreciation_method_none?

      if FinancialYear.at(fixed_asset.started_on)&.opened? || FinancialYear.at(stopped_on)&.opened?
        journal_entry(fixed_asset.journal, printed_on: stopped_on, if: accountable && !locked) do |entry|
          name = tc(:bookkeep, resource: FixedAsset.model_name.human, number: fixed_asset.number, name: fixed_asset.name, position: position, total: fixed_asset.depreciations.count)
          entry.add_debit(name, fixed_asset.expenses_account, amount)
          entry.add_credit(name, fixed_asset.allocation_account, amount)
        end
      else
        current_fy = FinancialYear.opened.first
        waiting_account = Account.find_or_import_from_nomenclature(:suspense)

        journal_entry(fixed_asset.journal, printed_on: current_fy.started_on, unless: has_journal_entry?) do |entry|
          name = tc(:bookkeep, resource: FixedAsset.model_name.human, number: fixed_asset.number, name: fixed_asset.name, position: position, total: fixed_asset.depreciations.count)
          entry.add_debit(name, waiting_account, amount)
          entry.add_credit(name, fixed_asset.allocation_account, amount)
        end
      end
    end

    def bookkeep_sold
      journal_entry(fixed_asset.journal, printed_on: stopped_on, if: accountable && !locked) do |entry|
        name = tc(:bookkeep_partial, resource: FixedAsset.model_name.human, number: fixed_asset.number, name: fixed_asset.name, position: position, total: fixed_asset.depreciations.count)
        entry.add_debit(name, fixed_asset.expenses_account, amount)
        entry.add_credit(name, fixed_asset.allocation_account, amount)
      end
    end

    def bookkeep_scrapped
      exceptional_expenses_account = Account.find_or_import_from_nomenclature :exceptional_depreciations_imputations_expenses_for_fixed_assets

      journal_entry(fixed_asset.journal, printed_on: fixed_asset.scrapped_on, if: accountable && !locked) do |entry|
        name = tc(:bookkeep_partial, resource: FixedAsset.model_name.human, number: fixed_asset.number, name: fixed_asset.name, position: position, total: fixed_asset.depreciations.count)
        entry.add_debit(name, exceptional_expenses_account, amount)
        entry.add_credit(name, fixed_asset.allocation_account, amount)
      end
    end
end
