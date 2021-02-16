class ExchangersRegistry
  # @return [Hash{Symbol=>Hash{Symbol=>Hash{Symbol=>Class}}}]
  def list_by_category_and_vendor
    list = ActiveExchanger::Base.exchangers
                                .reject { |_k, v| v.deprecated? }
                                .sort_by { |k, _v| k }.reverse!
                                .group_by { |_k, v| v.category }
                                .sort_by { |k, _v| ORDER[k] }
                                .to_h

    list.transform_values do |v|
      v.group_by { |a| a.last.vendor }.transform_values(&:to_h)
    end
  end
end
