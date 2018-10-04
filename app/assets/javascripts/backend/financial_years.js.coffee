((E, $) ->
  $(document).ready ->
    $.ajax
      url: "/backend/financial-years.json"
      success: (data, status, request) ->
        if data.financial_years_count > 2 && data.are_two_financials_years_opened == true
          $('.btn-new-financial-year').first().attr('disabled',true)

  $(document).on 'change', '#confirm-revised-accounts', ->
    lock_btn = $('#lock-btn')
    lock_btn.attr('disabled', !this.checked)

) ekylibre, jQuery
