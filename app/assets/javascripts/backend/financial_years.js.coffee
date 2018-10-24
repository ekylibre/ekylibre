((E, $) ->
  $(document).ready ->
    $('.lock-table #confirm-revised-accounts').on 'change', ->
      lock_btn = $('#lock-btn')
      lock_btn.attr('disabled', !this.checked)

    $('.close-table #confirm-revised-accounts').on 'change', ->
      close_btn = $('#close-btn')
      close_btn.attr('disabled', !this.checked)

) ekylibre, jQuery
