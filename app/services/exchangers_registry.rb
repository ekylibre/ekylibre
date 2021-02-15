class ExchangersRegistry
  ORDER = {
    accountancy: 0,
    sales: 1,
    purchases: 2,
    stocks: 3,
    plant_farming: 4,
    animal_farming: 5,
    human_resources: 6,
    settings: 7,
    none: 8
  }.freeze

  # @return [Hash{Symbol=>Hash{Symbol=>Hash{Symbol=>Class}}}]
  def list_by_category_and_vendor
    list = ActiveExchanger::Base.exchangers.sort_by { |k, _v| k}.reverse!
                                           .group_by { |_k, v| v.category }
                                           .sort_by { |k, _v| ORDER[k] }
                                           .to_h
    list.transform_values do |v|
      v.group_by { |a| a.last.vendor }.sort_by { |a| a.first.to_s }.to_h.transform_values(&:to_h)
    end
  end
end
