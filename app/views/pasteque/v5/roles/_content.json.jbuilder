all_permissions = %w(button.opendrawer button.openmoney button.print fr.pasteque.pos.config.JPanelConfiguration fr.pasteque.pos.customers.CustomersPayment fr.pasteque.pos.panels.JPanelCloseMoney fr.pasteque.pos.panels.JPanelPayments fr.pasteque.pos.panels.JPanelPrinter fr.pasteque.pos.panels.ReprintZTicket fr.pasteque.pos.sales.JPanelTicketEdits fr.pasteque.pos.sales.JPanelTicketSales Menu.BackOffice Menu.ChangePassword payment.cash payment.cheque payment.debt payment.free payment.magcard payment.paper payment.prepaid refund.cash refund.cheque refund.magcard refund.paper refund.prepaid sales.ChangeTaxOptions sales.EditLines sales.EditTicket sales.PrintTicket sales.RefundTicket sales.Total)

permissions = []
if resource.administrator
  permissions = all_permissions
else
  matching = {
    'cash_sessions-open' => 'button.openmoney',
    'cash_sessions-close' => 'fr.pasteque.pos.panels.JPanelCloseMoney',
    'sales-write' => 'fr.pasteque.pos.sales.JPanelTicketEdits',
    'sales-read' => 'fr.pasteque.pos.sales.JPanelTicketSales'
  }.with_indifferent_access
  permissions = resource.rights_array.inject([]) do |array, right|
    array << matching[right] if matching[right]
    array
  end
  permissions += all_permissions - matching.values
end

json.id resource.id.to_s
json.label resource.name
json.permissions permissions.join(' ')
