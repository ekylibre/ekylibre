# frozen_string_literal: true

class FixedAssetDepreciator
  # WARNING : this method validate depreciations and bookkeep them and not generate depreciations

  # @param [Array<FixedAsset>] fixed_assets
  # @option [Date] up_to
  # @return [Integer]
  def depreciate(fixed_assets, up_to:)
    return 0 unless can_depreciate?

    # generate depreciation if needed
    generate_depreciations(fixed_assets)
    # get depreciations eligible for bookkeep
    depreciations = get_eligible_depreciations(fixed_assets)
    max_depreciation_date = [up_to, last_opened_financial_year.stopped_on].min
    depreciables = depreciations.up_to(max_depreciation_date)

    depreciate_each(depreciables)
  end

  # @param [Array<FixedAssetDepreciation] depreciables
  # @return [Integer]
  # set accountable = true to pass in the bookkeep method of the asset model
  def depreciate_each(depreciables)
    ApplicationRecord.transaction do
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

  def generate_depreciations(assets)
    assets.each do |asset|
      asset.depreciate! if asset.depreciations.count == 0
    end
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
