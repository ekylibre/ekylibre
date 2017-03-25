(($) ->

  setUpdateTriggers = ->
    links = $(this)
    links.each ->
      link = $(this)
      triggerSelector = link.data('update-link-with')
      $(triggerSelector).change ->
        url = link.attr('href')
        triggeredInput = $(this)
        id = triggeredInput.attr 'id'
        value = triggeredInput.val()
        regExp = new RegExp "(\\?|\\&)(#{id})\\=([^&]+)"
        if url.match(regExp)
          url = url.replace(regExp, "$1$2=#{value}")
        else
          if url.indexOf('?') < 0 then url += '?' else url += '&'
          url += "#{id}=#{value}"
        link.attr('href', url)


  $(document).behave 'load', 'a[data-update-link-with]', setUpdateTriggers

  return
) jQuery