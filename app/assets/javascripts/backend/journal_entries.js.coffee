(($, E) ->
  "use strict"

  E.checkFinancialYearCurrency = () ->
    change_item = $(this).closest('*[data-change-url]')
    date = $(this).val()
    console.log date
    return unless /^\d\d\d\d\-\d\d\-\d\d$/.test(date)
    $.ajax
      url: change_item.data('change-url')
      data:
        on: date
      dataType: "json"
      success: (data, status, request) ->
        if data.from isnt data.to
          change = 'true'
        else
          change = 'false'
        change_item.attr('data-with-change', change)
        change_item.find('#journal_entry_real_currency_rate').val(data.exchange_rate)
        label = change_item.find('label[data-change-label]')
        label.html(label.data('change-label').replace(/\{\{FROM\}\}/, data.from).replace(/\{\{TO\}\}/, data.to))
        change_item.find('.financial-year-currency').html(data.to)
    $.checkDate($(this))

  $(document).on('change keyup', '#journal-entry-form #journal_entry_printed_on', E.checkFinancialYearCurrency)

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

    toggleAutocompletion = () ->
      $.ajax
        url:  '/backend/journal_entries/toggle-autocompletion'
        type: 'patch'
        data:
          autocompletion: $('#preference_entry_autocompletion').is(":checked")
        error: ->
          $('#preference_entry_autocompletion').attr('checked', !$('#preference_entry_autocompletion').is(":checked"))

    $(document).behave "change", "#preference_entry_autocompletion", () ->
      toggleAutocompletion()

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

      observer.observe(document.getElementById("items-table"), childList: true)

      # to avoid autocalculate messing up our first error calculation.
      setTimeout(evening, 500)

) jQuery, ekylibre
