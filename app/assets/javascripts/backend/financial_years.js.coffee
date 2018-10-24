((E, $) ->
  $(document).on 'change', '#confirm-revised-accounts', ->
    lock_btn = $('#lock-btn')
    lock_btn.attr('disabled', !this.checked)

) ekylibre, jQuery
