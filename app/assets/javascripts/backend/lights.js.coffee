((E, $) ->
  'use strict'

  appendLightsToInput = ($input) ->
    htmlString = "<span class='lights'><span class='go'></span><span class='caution'></span><span class='stop'></span></span><span class='lights-message'></span>"
    $input.closest($input.data('lights')).append(htmlString)

  $(document).ready ->
    $('[data-lights]').each ->
      appendLightsToInput($(this))

  $(document).on "cocoon:after-insert", ".nested-inputs", (e, $newRow) ->
    $newRow.find('[data-lights]').each ->
      appendLightsToInput($(this))

) ekylibre, jQuery
