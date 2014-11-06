(($) ->
  "use strict"

  $.refreshDependents = (event) ->
    element = $(this)
    params = {}
    if element.val() isnt null and element.val() isnt `undefined`
      dependents = element.data("dependents")
      paramName = element.data("parameter-name") or element.attr("id") or "value"
      params[paramName] = element.val()
      $(dependents).each (index, item) ->
        # item = $(this)
        console.log "Dependent: ", item
        # Replaces element
        # url = $(item).data("refresh")

        unless $(item).attr("href")?
          if $(item).data("refresh")?
            $(item).attr "href", $(item).data("refresh")
          else if $(item).data("refresh-url")?
            $(item).attr "href", $(item).data("refresh-url")
        unless $(item).attr "data-update"
          $(item).attr "data-update", "self"
        console.log "Dependent: ", item
        $.rails.handleRemote $(item)

        # mode = $(item).data("refresh-mode") or "replace"
        # if url?
        #   $.ajax url,
        #     data: params
        #     success: (data, status, response) ->
        #       console.log "Success"
        #       if mode is "update"
        #         $(item).html response.responseText
        #       else if mode is "update-value"
        #         if element.data("attribute")
        #           $(item).val $.parseJSON(data)[element.data("attribute")]
        #         else
        #           $(item).val response.responseText
        #       else
        #         $(item).replaceWith response.responseText
        #       console.log "Success done"

        #     error: (request, status, error) ->
        #       console.log "FAILURE (Error #{status}): #{error}"
        #       alert "FAILURE (Error #{status}): #{error}"

      return true
    false


  # Refresh dependents on changes
  $(document).on "change emulated:change selector:change", "*[data-dependents]", $.refreshDependents

  # Compensate for changes made with keyboard
  $(document).on "keypress", "select[data-dependents]", $.refreshDependents

  true

) jQuery
