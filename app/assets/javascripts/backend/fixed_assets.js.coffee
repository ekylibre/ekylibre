((E, $) ->
  'use strict'

  $(document).on 'change', '.fixed_asset_depreciation_method .radio', (event) ->
    selectedRadioValue = $(event.target).val()

    if selectedRadioValue == "simplified_linear"
      $('#stopped_on_block').css('display', 'none')
    else
      $('#stopped_on_block').css('display', 'block')


) ekylibre, jQuery
