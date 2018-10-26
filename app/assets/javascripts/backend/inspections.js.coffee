((E, $) ->
  'use strict'


  $(document).on 'keyup change dp.change', '.inspection_sampled_at #inspection_sampled_at', (event) ->
    selectedValue = $(event.target).val()
    unrollElement = $('.inspection_product input.selector-search')

    unrollRegex = /(unroll\?.*scope.*availables([^&]*)at[^=]*)=([^&]*)/
    unrollPath = $(unrollElement).attr('data-selector')
    unrollPath = unrollPath.replace(unrollRegex, "$1=#{ selectedValue }")

    $(unrollElement).attr('data-selector', unrollPath)
    $(unrollElement).trigger 'selector:set'


) ekylibre, jQuery
