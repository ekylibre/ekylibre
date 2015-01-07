(($) ->
  'use strict'

  $(document).on 'click keyup', "a[data-budget-add='support']", ->
    $(this).closest('table').find('tr.appendable').each ->
      $(this).find('td:last').before('<td>foo</td>')
    return false

  $(document).on 'click keyup', "a[data-budget-add='expense']", ->
    template = $(this).closest('table').find('tr.expense_template')
    new_expense = template.clone(true)
    new_expense.removeClass('expense_template')
    template.before(new_expense)
    return false

  $(document).on 'click keyup', "a[data-budget-add='revenue']", ->
    template = $(this).closest('table').find('tr.revenue_template')
    new_revenue = template.clone(true)
    new_revenue.removeClass('revenue_template')
    template.before(new_revenue)
    return false

  return
) jQuery
