(($) ->
  "use strict"

  $(document).on "slided", "*[data-regulator]", ->
    element = $(this)
    cell = element.closest("*[data-beehive-cell]")

    expenses = 0
    cell.find("*[data-fake-price]").each ->
      item = $(this)
      expenses += item.data("fake-expense-coeff") * cell.find("##{item.data('fake-price')}").slider("value")

    cell.find(".slider-salary").each ->
      expenses += $(this).slider("value") * 12 * 1.43

    cell.find(".slider-provision").each ->
      expenses += $(this).slider("value")
    console.log "Expenses: #{expenses}"

    if element.hasClass("slider-yield")
      other_revenues = 0
      cell.find("*[data-fake-price]").each ->
        item = $(this)
        if item.data("fake-price") != element.attr("id")
          other_revenues += item.data("fake-revenue")
      console.log "Other revenues: #{other_revenues}"

      # Compute quantity in tons
      item = cell.find("*[data-fake-price='#{element.attr('id')}']")
      console.log "Revenue: #{other_revenues + item.data('fake-revenue')}"
      quantity = element.slider("value") * item.data("fake-work-quantity") * 0.1
      console.log quantity
      revenue = expenses - other_revenues
      price = revenue / quantity;
      item.html("#{Math.round(price)}€/t")
      item.attr("data-fake-revenue", revenue)
      item.data("fake-revenue", revenue)
    else
      total = 0
      cell.find("*[data-fake-price]").each ->
        total += $(this).data("fake-work-quantity")
      cell.find("*[data-fake-price]").each ->
        item = $(this)
        # Compute quantity in tons
        quantity = cell.find("##{item.data('fake-price')}").slider("value") * item.data("fake-work-quantity") * 0.1
        console.log quantity
        revenue = expenses * item.data("fake-work-quantity") / total
        price = revenue / quantity
        item.html("#{Math.round(price)}€/t")
        item.data("fake-revenue", revenue)

    true

  true
) jQuery
