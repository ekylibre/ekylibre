(($) ->
  'use strict'
  $(document).ready ->
    $("table#budget_visualization").on 'cocoon:after-insert', (event, inserted) ->
      # adds items to new budget
      if inserted.hasClass("budget_nested_fields")
        link_to_add_budget_item = inserted.find("a[data-association='item']")
        #adds items for supports
        $("input[id^='production_supports_attributes_'][id$='destroy'][type='hidden']").each ->
          if $(this).closest('td').is(':visible')
            link_to_add_budget_item.click()
            new_item = link_to_add_budget_item.closest("td").prev()
            new_item.attr('data-support-destroy', $(this).attr('id'))
  # adds a budget item when adding a support
  $(document).on 'click keyup', "a[data-association='support']", ->
    support_destroy_id = $(this).closest("td").prev().find("input[id^='production_supports_attributes_'][id$='destroy'][type='hidden']").attr('id')
    $("a[data-association='item']").each ->
      $(this).click()
      new_item = $(this).closest('td').prev()
      new_item.attr('data-support-destroy', support_destroy_id)
    return false

  # removes items when removing a support
  $(document).on 'click', "a.remove-support", ->
    items_to_remove = $(this).closest('td').find("input[id^='production_supports_attributes_'][id$='destroy'][type='hidden']").attr('id')
    $("tr.budget_nested_fields").each ->
      link_to_remove_item = $(this).find("td[data-support-destroy='#{items_to_remove}']").find("a.remove-item")
      link_to_remove_item.click()
  return
) jQuery
