(($) ->
  'use strict'
  $(document).ready ->
    $("table").on 'cocoon:after-insert', (event, inserted) ->
      # adds items to new budget
      if inserted.hasClass("budget_nested_fields")
        link_to_add_budget_item = inserted.find("a[data-association='item']")
        #adds items for supports
        $("input[id^='production_supports_attributes_'][id$='destroy'][type='hidden']").each ->
          link_to_add_budget_item.click()
  # adds a budget item when adding a support
  $(document).on 'click keyup', "a[data-association='support']", ->
    $("a[data-association='item']").click()
    return false
  return
) jQuery
