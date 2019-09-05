# Allows us to label items for the unroll list from both a view or its controller.
module UnrollHelper
  def label_item(item, filters, controller, action_name = "unroll")
    UnrollHelper.label_item(item, filters, controller, action_name)
  end

  def self.label_item(item, filters, controller, action_name = "unroll")
    item_names = filters.map { |f| [f.name, f.value_of(item)] }.to_h
    controller = "#{controller}/#{action_name.gsub /^unroll_/, ''}" if action_name && action_name != 'unroll'

    defaults = [
      "unrolls.#{controller}.default".to_sym,
      "unrolls.#{controller}".to_sym,
      filters.map { |f| "%{#{f.name}}" }.join(', ')
    ]

    "unrolls.#{controller}.#{item.class.name.tableize}".t(item_names.merge(default: defaults))
  end
end
