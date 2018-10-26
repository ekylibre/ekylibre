(($) ->
  $(document).ready ->
    $(document).on "keyup", "input.numeric", (e) ->
      currentValue = parseFloat($(this).val() || $(this).attr('placeholder') || 0)
      if e.which == 38
        $(this).val(currentValue + 1)
      if e.which == 40
        $(this).val(currentValue - 1)
) (jQuery)
