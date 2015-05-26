json.cashId resource.cash_id
json.openCash resource.noticed_start_amount
json.closeCash resource.noticed_stop_amount
json.ticketCount resource.ticket_count
json.custCount resource.customers_count
json.paymentCount resource.payment_count
json.cs resource.consolidated_sales
json.payments(resource.payments) do |payment|
  json.id payment.id
  json.type payment._type
  json.amount payment.amount
  json.currencyId payment.currency
  json.currencyAmount payment.currency_amount
end
json.taxes(resource.taxes) do |tax|
  json.id tax.id
  json.base tax.base
  json.amount tax.amount
end
json.catSales(resource.category_sales) do |sale|
  json.id sale.id
  json.amount sale.amount
end
