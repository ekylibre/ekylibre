# Allows us to label items for the unroll list from both a view or its controller.
module UnrollHelper
  def label_item(item, filters, controller)
    UnrollHelper.label_item(item, filters, controller)
  end

  def self.label_item(item, filters, controller)
    defaults = filters.map { |f| "%{#{f.name}}" }.join(', ')
    item_names = filters.map { |f| [f.name, f.value_of(item)] }.to_h

    "unrolls.#{controller}".t(item_names.merge(default: defaults))
  end
end
