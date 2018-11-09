((E, $) ->
  $(document).ready ->
    $('.lock-table #confirm-revised-accounts').on 'change', ->
      lock_btn = $('#lock-btn')
      lock_btn.attr('disabled', !this.checked)

    $('.close-table #confirm-revised-accounts').on 'change', ->
      close_btn = $('#close-btn')
      close_btn.attr('disabled', !this.checked)

    $('.med-info .signature-trigger').on 'click', ->
      signatureContainer = $(this).closest('.med-info')
      signatureDetails = $(signatureContainer).find('.signature-details')
      chevron = $(signatureContainer).find('.chevron')
      if $(signatureDetails).is(":visible")
        $(chevron).css('transform', 'rotate(0deg)');
      else
        $(chevron).css('transform', 'rotate(90deg)');
      $(signatureDetails).slideToggle();

) ekylibre, jQuery
