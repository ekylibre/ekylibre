(($) ->

  $(document).ready ->
    $('#fec-export-submit').on 'click', ->
      id = $('#financial_year_id').val()
      position = $('#fiscal_position').val()
      interval = $("input[type='radio'][name='interval']:checked").val()

      pattern = ///
        (xml|text)_(.*)
      ///

      [format, fiscalPosition] = position.match(pattern)[1..2]

      location.href = "/backend/financial-years/#{id}.#{format}?fiscal_position=#{fiscalPosition}&interval=#{interval}"

) jQuery
