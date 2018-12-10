class GainAndLossFixedAssetPrinter < GeneralFixedAssetPrinter

  def compute_dataset
    # TODO

    to = @period == 'all' ? FinancialYear.current.stopped_on : Date.parse(@period.split('_').last)
    fixed_assets = FixedAsset.sold_or_scrapped.start_before(to)

    # assets = fixed_assets.map do |fixed_asset|

    # end

    # { total_net_book_value: ,
    #   total_sold_amount: ,
    #   total_gain_or_loss: ,
    #   assets: assets }
  end

  def run_pdf
    dataset = compute_dataset
  end
end
