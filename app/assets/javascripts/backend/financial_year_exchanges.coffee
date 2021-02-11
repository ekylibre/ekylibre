((E, $) ->
  $(document).on 'click', '.notify-accountant-action', (event) ->
    event.preventDefault()
    exchange_id = $(event.target).parents('tr').data('id')
    url = "/backend/financial-year-exchanges/#{exchange_id}/notify_accountant_modal"
    E.Dialog.open(url)

) ekylibre, jQuery
