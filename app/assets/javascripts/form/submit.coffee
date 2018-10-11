(($) ->

  $(document).ready ->
    $('#fec-export-submit').on 'click', ->
      id = $('#financial_year_id').val()
      fiscalPosition = $('#fiscal_position').val()
      location.href = "/backend/financial-years/#{id}.xml?fiscal_position=#{fiscalPosition}"

) jQuery
