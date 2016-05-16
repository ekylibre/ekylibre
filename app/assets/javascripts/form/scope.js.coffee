(($) ->

  # This method scope css selection inside a form or the value of data-scoper attribute
  $.fn.extend
    formScopedSelect: (selection) ->
      reference = $(this)
      if reference.length == 1
        scoper = reference.closest(reference.data("closest") || reference.data("scoper") || "form")
        if scoper.size() > 0
          return scoper.find(selection)
        else
          return $(selection)
      else
        console.log("You must call formScopedSelect on '1 element' object, not like: ", reference)

  return
) jQuery
