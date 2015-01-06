(($) ->

  # Interpolate data value with attribute values
  $.fn.extend
    interpolatedData: (dataName) ->
      element = $(this)
      data = element.data(dataName)
      return null unless data?
      return data unless typeof data == 'string'
      return element.data(dataName).replace /\{\{(\w+)\}\}/i, (str, p1, offset, s) ->
        element.attr(p1)

  # Toggle check boxes and radio buttons target
  $.toggleCheckboxes = ->
    checkable = $(this)
    if checkable.prop("checked")
      checkable.formScopedSelect(checkable.interpolatedData("show")).slideDown()
      checkable.formScopedSelect(checkable.interpolatedData("hide")).slideUp()
    else
      checkable.formScopedSelect(checkable.interpolatedData("show")).slideUp()
      checkable.formScopedSelect(checkable.interpolatedData("hide")).slideDown()
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
