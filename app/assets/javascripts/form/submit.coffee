(($) ->

  $(document).ready ->
    $('#fec-export-submit').on 'click', ->
      id = $('#financial_year_id').val()
      fiscalPosition = $('#fiscal_position').val()
      interval = $("input[type='radio'][name='interval']:checked").val()
      location.href = "/backend/financial-years/#{id}.xml?fiscal_position=#{fiscalPosition}&interval=#{interval}"

) jQuery
