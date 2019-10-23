((E, $) ->

  $(document).on "load change", "input[data-always-check]", ->
    $input = $(this)
    $target = $($input.data('always-check'))
    checked = $input.is ':checked'
    $target.attr('disabled', checked)
    $target.get(0).checked = true if checked

) ekylibre, jQuery
