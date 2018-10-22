((E, $) ->
  $(document).ready ->
    return unless $('.btn-new-financial-year').length
    $.ajax
      url: "/backend/financial-years.json"
      success: (data, status, request) ->
        if data.are_two_financials_years_opened > 1
          $('.btn-new-financial-year').first().attr('disabled',true)

  $(document).ready ->
    if ($('.lock-table').find('#confirm-revised-accounts').length)
      $('#confirm-revised-accounts').change ->
        $('#lock-btn').attr('disabled', !this.checked)

    if ($('.close-table').find('#confirm-revised-accounts').length)
      $('#confirm-revised-accounts').change ->
        $('#close-btn').attr('disabled', !this.checked)

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
