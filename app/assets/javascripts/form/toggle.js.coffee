(($) ->
  $.toggleCheckboxes = ->
    checkable = $(this)
    if checkable.prop("checked")
      checkable.formScopedSelect(checkable.data("show")).slideDown()
      checkable.formScopedSelect(checkable.data("hide")).slideUp()
    else
      checkable.formScopedSelect(checkable.data("show")).slideUp()
      checkable.formScopedSelect(checkable.data("hide")).slideDown()
    return

  $.toggleRadios = ->
    $("input[type='radio'][data-show], input[type='radio'][data-hide]").each $.toggleCheckboxes
    return


  # Hide/show blocks depending on check boxes
  $(document).behave "load", "input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", $.toggleCheckboxes
  $(document).on   "change", "input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", $.toggleCheckboxes
  $(document).behave "load", "input[type='radio'][data-show], input[type='radio'][data-hide]", $.toggleCheckboxes
  $(document).on   "change", "input[type='radio'][data-show], input[type='radio'][data-hide]", $.toggleRadios

  return
) jQuery
