class FixedAssetDepreciator

  # @param [Array<FixedAsset>] fixed_assets
  # @option [Date] up_to
  # @return [Integer]
  def depreciate(fixed_assets, up_to:)
    return 0 unless can_depreciate?

    depreciations = get_eligible_depreciations(fixed_assets)
    max_depreciation_date = [up_to, last_opened_financial_year.stopped_on].min
    depreciables = depreciations.up_to(max_depreciation_date)

    depreciate_each(depreciables)
  end

  # @param [Array<FixedAssetDepreciation] depreciables
  # @return [Integer]
  def depreciate_each(depreciables)
    Ekylibre::Record::Base.transaction do
      # trusting the bookkeep to take care of the accounting
      count = 0
      depreciables.find_each do |dep|
        dep.update!(accountable: true)
        count += 1
      end
      return count
    end
    0
  end

  def get_eligible_depreciations(assets)
    FixedAssetDepreciation.with_active_asset.not_locked.not_accountable.where(fixed_assets: { id: assets })
  end

  def last_opened_financial_year
    FinancialYear.opened.last
  end

  def can_depreciate?
    last_opened_financial_year.present?
  end
end