(($) ->
  "use strict"

  $(document).ready () ->
    calculate_sum = (column) ->
      sum = 0
      $("td."+column+"-without-error-correction").each (index, elem) ->
        numval = parseFloat($(elem).html())
        if (typeof(numval) == "number") && !isNaN(numval)
          sum += numval
      sum

    withoutError = (correctedTD) ->
      column = correctedTD.className.split(" ").filter (element) ->
        element == "credit" or element == "debit"
      column = column[0]
      $(correctedTD).next("td."+column+"-without-error-correction").html()

    resetCorrectedValues = () ->
      ['debit', 'credit'].forEach (column) ->
        $("td."+column).each (index, input) ->
          valueWithoutError = withoutError(input)
          $(input).html(valueWithoutError)

    errorRepartition =  (column, sum, error_sum) ->
      precision = parseFloat($("#entry-"+column+".decimal").data("calculate-round"))

      error_sum =  Math.abs(Math.round(error_sum * 10**precision))
      left = error_sum

      $("."+column).each (index, item) ->
          itemval = withoutError(item)
          itemval = parseFloat(itemval) * 10**precision
          toCorrect = itemval / (sum * 10**precision) * error_sum

          if (typeof(itemval) == "number") && !isNaN(itemval)
            toCorrect = itemval / (sum * 10**precision) * error_sum
            toCorrect = Math.ceil(Math.min(left, toCorrect))
            $(item).html(Math.round(itemval + toCorrect) / 10**precision)
            left -= toCorrect

    evening = () ->
      resetCorrectedValues()

      if $("#total").hasClass "valid"
        debit = calculate_sum "debit"
        credit = calculate_sum "credit"

        if debit != credit

          # entry-debit[data-calculate-round] should be equal
          #   to entry-credit[data-calculate-round]

          error_sum = (debit - credit)

          if error_sum != 0
            if error_sum > 0
              errorRepartition("credit", credit, error_sum)
            else
              errorRepartition("debit", debit, error_sum)

    convert = (item, column) ->
      field = $(item).closest("tr").next("tr").find("td."+column)
      precision = field.data("calculate-round")
      new_val = parseFloat($("#journal_entry_real_currency_rate").val()) * parseFloat($(item).val())
      new_val = Math.round(new_val * 10**precision) / 10**precision
      field.html(new_val)
      field.next("td."+column+"-without-error-correction").html(new_val)

    convertAll = () ->
      ['debit', 'credit'].forEach (column) ->
          $(".real-"+column).each (index, item) ->
            convert(item, column)

    if $("#subtotal").length > 0
      ['debit', 'credit'].forEach (column) ->
        $(document).behave "change keyup paste", '.real-'+column,  () ->
          convert(this, column)
          evening()

      $(document).behave "change keyup paste", "#journal_entry_real_currency_rate", () ->
        convertAll()
        evening()

      observer = new MutationObserver (mutations) ->
        mutations.forEach (mutation) ->
          if mutation.addedNodes.length > 0
            convertAll()
            evening()

      observer.observe(document.getElementById("items"), childList: true)

      # to avoid autocalculate messing up our first error calculation.
      setTimeout(evening, 500)

  ) (jQuery)