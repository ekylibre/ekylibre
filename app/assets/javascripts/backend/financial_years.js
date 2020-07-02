(function (E, $) {
  function getAllocatedInputAmountSum() {
    return $('input[type=number].allocation').toArray().reduce(((acc, e) => acc + parseFloat(e.value) || 0), 0)
  }

  function displayTotalSum() {
    $('.fieldset-fields .amount_allocated').find('span').text(totalSumRemainedToAllocate().toFixed(2))
    onAmountChange()
  }

  function totalSumRemainedToAllocate() {
    return (Math.abs(balanceBetweenResultsAndCarryForward()) - getAllocatedInputAmountSum())
  }

  function fillAmountToAllocate() {
    const $amountAllocated = $('.fieldset-fields .amount_allocated')
    $amountAllocated.find('span').text(getAmountToAllocate())
    $amountAllocated.append(`<input type='number' name='sum' id='sum' value='${getAmountToAllocate()}' class='hidden credit_balance' step='any'>`)
  }

  function balanceBetweenResultsAndCarryForward() {
    const debitCarryForwardAmount = parseFloat($('.fieldset-fields .previous_debit_balance').val()) || 0
    const creditCarryForwardAmount = parseFloat($('.fieldset-fields .previous_credit_balance').val()) || 0
    const carryForwardAmount = (creditCarryForwardAmount - debitCarryForwardAmount)

    const exerciceResults = parseFloat($('.close-conditions .result').find('.result-amount').attr('data-exercice-results'))

    return (carryForwardAmount + exerciceResults).toFixed(2)
  }


  function getAmountToAllocate() {
    const exerciceResults = parseFloat($('.close-conditions .result').find('.result-amount').attr('data-exercice-results'))
    const creditCarryForward = parseFloat($('.fieldset-fields .amount_allocated--carry_forward').find('input').val()) || 0

    if ($('.previous_debit_balance').length) {
      return Math.abs(exerciceResults - creditCarryForward).toFixed(2)
    } else {
      return Math.abs(exerciceResults + creditCarryForward).toFixed(2)
    }
  }

  function onAmountChange() {
    $('.fieldset-fields .amount_allocated .allocated-budget').toggleClass('error', totalSumRemainedToAllocate() < 0)
    $('#close-btn').attr('disabled', (!$('#confirm-revised-accounts').prop('checked') || totalSumRemainedToAllocate() !== 0))
  }

  $(document).ready(function () {
    $('.lock-table #confirm-revised-accounts').on('change', function () {
      const lock_btn = $('#lock-btn')
      lock_btn.attr('disabled', !$(this).is(':checked'))
    })

    $('.close-table #confirm-revised-accounts').on('change', function () {
      if ($('.amount_allocated').length) {
        $('#close-btn').attr('disabled', !$(this).is(':checked') || (totalSumRemainedToAllocate() !== 0))
      } else {
        $('#close-btn').attr('disabled', !$(this).is(':checked'))
      }
    })

    $('.med-info .signature-trigger').on('click', function () {
      const signatureContainer = $(this).closest('.med-info')
      const signatureDetails = $(signatureContainer).find('.signature-details')
      const chevron = $(signatureContainer).find('.chevron')

      if ($(signatureDetails).is(":visible")) {
        $(chevron).css('transform', 'rotate(0deg)')
      } else {
        $(chevron).css('transform', 'rotate(90deg)')
      }

      $(signatureDetails).slideToggle()
    })

    $('.exercice_result_allocation').each(function () {
      fillAmountToAllocate()
      displayTotalSum()

      $(document).on('input', '.fieldset-fields .amount_allocated input', () => displayTotalSum())
    })
  })

}(ekylibre, jQuery))
