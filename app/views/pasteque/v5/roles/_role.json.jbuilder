matching = {
            :'cash_sessions-open'   =>  'perm-button.openmoney',
            :'cash_sessions-close'  =>  'perm-fr.pasteque.pos.panels.JPanelCloseMoney',
            :'sales-write'          =>  'perm-fr.pasteque.pos.sales.JPanelTicketEdits',
            :'sales-read'           =>  'perm-fr.pasteque.pos.sales.JPanelTicketSales'
}.with_indifferent_access

permissions = role.rights_array.inject([]) do |array, right|
  array << matching[right] if matching[right]
  array
end

json.id role.id.to_s
json.label role.name
json.permissions permissions.join(" ")
