((E, $) ->
  'use strict'


  # Set
  $(document).on "change keyup", "select[data-activity-family]", (event)->
    select = $(this)
    form = select.closest("form")
    support_check   = form.find("#activity_with_supports")
    support_select  = form.find("#activity_support_variety")
    support_control = form.find(".activity_support_variety")
    cultivation_check   = form.find("#activity_with_cultivation")
    cultivation_select  = form.find("#activity_cultivation_variety")
    cultivation_control = form.find(".activity_cultivation_variety")
    value = select.val()
    if value is undefined or value == ""
      support_control.hide()
      support_check.val(0)
      cultivation_control.hide()
      cultivation_check.val(0)
    else
      $.ajax
        url: "/backend/activities/family.json"
        data:
          name: value
        success: (data, status, request) ->
          if data.support_varieties?
            support_select.html("")
            $.each data.support_varieties, (index, item) ->
              option = $("<option>")
                .html(item.label)
                .attr("value", item.value)
                .appendTo(support_select)
            support_control.show()
            support_select.trigger("change")
            support_check.val(1)
          else
            support_control.hide()
            support_check.val(0)
          support_check.trigger("change")

          if data.cultivation_varieties?
            cultivation_select.html("")
            $.each data.cultivation_varieties, (index, item) ->
              option = $("<option>")
                .html(item.label)
                .attr("value", item.value)
                .appendTo(cultivation_select)
            cultivation_control.show()
            cultivation_select.trigger("change")
            cultivation_check.val(1)
          else
            cultivation_control.hide()
            cultivation_check.val(0)
          cultivation_check.trigger("change")


) ekylibre, jQuery
