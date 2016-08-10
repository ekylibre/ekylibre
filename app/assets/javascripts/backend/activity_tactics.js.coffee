((E, $) ->
  'use strict'

  $(document).on "change keyup", "select[data-procedure-categorie]", (event)->
    select = $(this)
    form = select.closest(".tactic-step")
    procedure_select = form.find(".activity_tactic_steps_procedure_name select")
    procedure_control = form.find(".activity_tactic_steps_procedure_name")
    action_control = form.find(".activity_tactic_steps_action")
    value = select.val()
    action_control.hide()
    if value != ""
      $.ajax
        url: "/backend/activity_tactics/procedures_name.json"
        data:
          name: value
        success: (data, status, request) ->
          procedure_select.html("")
          if jQuery.isEmptyObject(data)
            procedure_control.hide()
          else
            option = $("<option>")
              .html("")
              .attr("value", "")
              .appendTo(procedure_select)
            $.each data, (index, item) ->
              option = $("<option>")
                .html(item)
                .attr("value", index)
                .appendTo(procedure_select)
            procedure_control.show()
    else
      procedure_control.hide()

  $(document).on "change keyup", "select[data-procedure-name]", (event)->
      select = $(this)
      form = select.closest(".tactic-step")
      action_select = form.find(".activity_tactic_steps_action select")
      action_control = form.find(".activity_tactic_steps_action")
      value = select.val()
      if value != ""
        $.ajax
          url: "/backend/activity_tactics/actions.json"
          data:
            name: value
          success: (data, status, request) ->
            action_select.html("")
            if jQuery.isEmptyObject(data)
              action_control.hide()
            else
              option = $("<option>")
                .html("")
                .attr("value", "")
                .appendTo(action_select)
              $.each data, (index, item) ->
                option = $("<option>")
                  .html(item)
                  .attr("value", index)
                  .appendTo(action_select)
              action_control.show()

) ekylibre, jQuery
