(($) ->
  $.toggleCheckboxes = ->
    checkable = $(this)
    if checkable.prop("checked")
      $(checkable.attr("data-show")).slideDown()
      $(checkable.attr("data-hide")).slideUp()
    else
      $(checkable.attr("data-show")).slideUp()
      $(checkable.attr("data-hide")).slideDown()
    return

  $.toggleRadios = ->
    $("input[type='radio'][data-show], input[type='radio'][data-hide]").each $.toggleCheckboxes
    return

  
  # Hide/show blocks depending on check boxes
  $(document).behave "load", "input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", $.toggleCheckboxes
  $(document).behave "change", "input[type='checkbox'][data-show], input[type='checkbox'][data-hide]", $.toggleCheckboxes
  $(document).behave "load", "input[type='radio'][data-show], input[type='radio'][data-hide]", $.toggleCheckboxes
  $(document).behave "change", "input[type='radio'][data-show], input[type='radio'][data-hide]", $.toggleRadios
  return
) jQuery
