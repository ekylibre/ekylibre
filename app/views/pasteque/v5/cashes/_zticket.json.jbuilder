json.cashId zticket.cash_id
json.openCash zticket.noticed_start_amount
json.closeCash zticket.noticed_stop_amount
json.ticketCount zticket.ticket_count
json.custCount zticket.customers_count
json.paymentCount zticket.payment_count
json.cs zticket.consolidated_sales
json.payments(zticket.payments) do |payment|
  json.id payment.id
  json.type payment._type
  json.amount payment.amount
  json.currencyId payment.currency
  json.currencyAmount payment.currency_amount
end
json.taxes(zticket.taxes) do |tax|
  json.id tax.id
  json.base tax.base
  json.amount tax.amount
end
json.catSales(zticket.category_sales) do |sale|
  json.id sale.id
  json.amount sale.amount
end
