((E, $) ->
  $(document).ready ->
    $('.lock-table #confirm-revised-accounts').on 'change', ->
      lock_btn = $('#lock-btn')
      lock_btn.attr('disabled', !this.checked)

    $('.close-table #confirm-revised-accounts').on 'change', ->
      if $('.amount_allocated').length
        $('#close-btn').attr('disabled', (!this.checked || (parseFloat(totalSumRemainedToAllocate()) != 0)))
      else
        $('#close-btn').attr('disabled', (!this.checked))


    $('.med-info .signature-trigger').on 'click', ->
      signatureContainer = $(this).closest('.med-info')
      signatureDetails = $(signatureContainer).find('.signature-details')
      chevron = $(signatureContainer).find('.chevron')
      if $(signatureDetails).is(":visible")
        $(chevron).css('transform', 'rotate(0deg)');
      else
        $(chevron).css('transform', 'rotate(90deg)');
      $(signatureDetails).slideToggle();

    $('.exercice_result_allocation').each ->
      fillAmountToAllocate()
      displayTotalSum()

      $(document).on 'input', '.fieldset-fields .amount_allocated input', (event) ->
        displayTotalSum()

  getAllocatedInputAmountSum = () ->
    $('input[type=number].allocation').toArray().reduce(((acc, e) => acc + parseFloat(e.value) || 0), 0)

  displayTotalSum = () ->
    $('.fieldset-fields .amount_allocated').find('span').text(totalSumRemainedToAllocate())
    onAmountChange()

  computeSumToAllocate = () ->
    (Math.abs(balanceBetweenResultsAndCarryForward()) - getAllocatedInputAmountSum()).toFixed(2)


  totalSumRemainedToAllocate = () ->
    sum = computeSumToAllocate()

  fillAmountToAllocate = () ->
    $('.fieldset-fields .amount_allocated').find('span').text(getAmountToAllocate())
    $('.fieldset-fields .amount_allocated').append("<input type='number' name='sum' id='sum' value='#{getAmountToAllocate()}' class='hidden credit_balance' step='any'>")


  balanceBetweenResultsAndCarryForward = () ->
    debitCarryForwardAmount = parseFloat($('.fieldset-fields .previous_debit_balance').val()) || 0
    creditCarryForwardAmount = parseFloat($('.fieldset-fields .previous_credit_balance').val()) || 0
    carryForwardAmount = (creditCarryForwardAmount - debitCarryForwardAmount)

    exerciceResults = parseFloat($('.close-conditions .result').find('.result-amount').attr('data-exercice-results'))

    (carryForwardAmount + exerciceResults).toFixed(2)

  getAmountToAllocate = () ->
    exerciceResults = parseFloat($('.close-conditions .result').find('.result-amount').attr('data-exercice-results'))
    creditCarryForward = parseFloat($('.fieldset-fields .amount_allocated--carry_forward').find('input').val()) || 0
    if $('.previous_debit_balance').length
      Math.abs(exerciceResults - creditCarryForward).toFixed(2)
    else
      Math.abs(exerciceResults + creditCarryForward).toFixed(2)


  onAmountChange = () ->
    $('.fieldset-fields .amount_allocated .allocated-budget').toggleClass('error', totalSumRemainedToAllocate() < 0 )
    $('#close-btn').attr('disabled', (!$('#confirm-revised-accounts').prop('checked') || parseFloat(totalSumRemainedToAllocate()) != 0))


) ekylibre, jQuery
