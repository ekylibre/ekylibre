((E, $) ->
  'use strict'

  $(document).on 'change', '#ledger', (e) ->
    form = $(@).closest("form")
    form.submit()

) ekylibre, jQuery
