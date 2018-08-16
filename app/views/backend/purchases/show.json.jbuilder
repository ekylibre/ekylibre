json.extract! resource, :id, :reconciliation_state

json.amount resource.amount

json_items = resource.items.map do |item|
  item.attributes.slice('id', 'variant_id', 'quantity', 'pretax_amount', 'amount')
end

json.items json_items
