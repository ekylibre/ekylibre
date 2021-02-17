class ExchangersRegistry
  # @return [Hash{Symbol=>Hash{Symbol=>Hash{Symbol=>Class}}}]
  def list_by_category_and_vendor
    list = ActiveExchanger::Base.exchangers.sort
                                .reject { |_k, v| v.deprecated? }
                                .group_by { |_k, v| v.category }
                                .sort_by { |k, _v| k.tl }
                                .to_h

    list.transform_values do |v|
      v.group_by { |a| a.last.vendor }.transform_values(&:to_h)
    end
  end
end
