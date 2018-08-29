((E, $) ->
  'use strict'

  $(document).ready ->
    return unless $('.edit_account').length
    url = $('form').attr('action')
    $.ajax
      url: "#{url}.json"
      success: (data, status, request) ->
        if data.has_auxiliary_accounts
          $('.account_nature input[type=radio]').attr('disabled',true)
          $('.account_number input[type=text]').attr('disabled',true)
        else
          $('.account_nature input[type=radio]').attr('disabled',false)
          $('.account_number input[type=text]').attr('disabled',false)

) ekylibre, jQuery
