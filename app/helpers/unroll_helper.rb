module UnrollHelper
  def label_item(item, filters, controller)
   UnrollHelper.label_item(item, filters, controller)
  end

  def self.label_item(item, filters, controller)
    "unrolls.#{controller}".t(
      filters
        .map { |f| [f[:name], f[:expression].call(item)] }.to_h
        .merge(default: filters.map { |f| "%{#{f[:name]}}" }.join(', '))
    )
  end
end
