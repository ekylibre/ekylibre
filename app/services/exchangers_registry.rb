class ExchangersRegistry

  # @return [Hash{Symbol=>Hash{Symbol=>Hash{Symbol=>Class}}}]
  def list_by_category_and_vendor
    list = ActiveExchanger::Base.exchangers.sort.group_by { |_k, v| v.category }

    list.transform_values do |v|
      v.group_by { |a| a.last.vendor }.transform_values(&:to_h)
    end.sort
  end
end
