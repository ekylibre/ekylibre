((E, $) ->
  'use strict'

  getAccountNumberDigits = ->
    parseInt($('#preferences_account_number_digits_value').val())

  $(document).ready ->
    return unless $('.company-edit-form').length
    accountNumberDigitsInitial = getAccountNumberDigits()
    $('.company-edit-form input[type="submit"]').click (event) ->
      confirmMessage = $('.company-edit-form').data('confirm-account-digits')
      if (getAccountNumberDigits() != accountNumberDigitsInitial) && !confirm(confirmMessage)
        event.preventDefault()
        return false

) ekylibre, jQuery
