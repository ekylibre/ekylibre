((E, $) ->
  $(document).ready ->
    $('.lock-table #confirm-revised-accounts').on 'change', ->
      lock_btn = $('#lock-btn')
      lock_btn.attr('disabled', !this.checked)

    $('.close-table #confirm-revised-accounts').on 'change', ->
      close_btn = $('#close-btn')
      close_btn.attr('disabled', !this.checked)

  $(document).ready ->
    return unless $('.edit_financial_year').length
    # original id look like "edit_toto_id"
    id = $('.edit_financial_year')[0].id.split('_').pop()
    $.ajax
      url: "/backend/financial-years/#{id}.json"
      success: (data, status, request) ->
        if data.state != 'opened'
          inputs = $('input').filter(-> this.id.match(/financial_year_*/))
          inputs.each(-> $(this).attr('disabled',true))
          $('input#financial_year_code').attr('disabled',false)

) ekylibre, jQuery
