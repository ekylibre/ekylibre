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

  getIdsFromUrl = (url, paramNameArgument) ->
    if url.indexOf('?') > 1
      parametersWithValues = url.split('?')[1]
      parametersWithValuesArray = parametersWithValues.split('&')
      for parameterWithValue in parametersWithValuesArray
        parameterName = parameterWithValue.split('=')[0]
        if parameterName == paramNameArgument
          parameterValue = parameterWithValue.split('=')[1]
          return parameterValue.split(',').map(Number)
    return []


  addOrRemoveIdFromIds = (id, ids, checkboxState) ->
    if checkboxState.is(':checked')
      ids.push(id)
    else
      index = ids.indexOf(id)
      ids.splice(index, 1)

    return ids


  updateUrlWithIds = (url, ids, paramName) ->
    if url.indexOf(paramName) < 0
      if url.indexOf('?') < 0 then url += '?' else url += '&'
      url += "#{paramName}=#{ids.join(',')}"
    else 
      idsArray = url.split(paramName)[1]
      optionalParameters = ""
      if idsArray.indexOf('&') > 0
        indexOptionalParameters = idsArray.indexOf('&')
        optionalParameters = idsArray.substring(index)
        idsArray = idsArray.split('&')[0]
      
      idsArray = idsArray.substring(1)

      paramToSplit = ""
      if url.indexOf("?#{paramName}") > 0 then paramToSplit = '?' else paramToSplit += '&'
      paramToSplit += paramName
      url = url.split("#{paramToSplit}")[0]

      if url.indexOf('?') < 0 then url += '?' else url += '&'
      url += "#{paramName}=#{ids.join(',')}"
      url += optionalParameters

  displayActionButton = (dataShowCondition, count, elementDisplayOnClick) ->
    if dataShowCondition == 'zero-or-one'
      debugger
      if count == 0
        $(elementDisplayOnClick).hide()

      if count == 1
        $(elementDisplayOnClick).show()

    else if dataShowCondition == 'one-or-two'
      if count <= 1
        $(elementDisplayOnClick).hide()

      if count >= 2
        totalDebit = $('#total-debit').text()
        totalCredit = $('#total-credit').text()
        if totalCredit != totalDebit
          $(elementDisplayOnClick).show()


  completeUrlWithIds = ->
    links = $(this)
    links.each ->
      link = $(this)
      paramName = $(link).attr('data-complete-link-with-ids')
      checkboxes = $('.list td input[type="checkbox"]')

      $(checkboxes).change ->
        url = link.attr('href')

        ids = getIdsFromUrl url, paramName
        id = parseInt($(this).closest('tr').attr('id').substring(1))

        ids = addOrRemoveIdFromIds id, ids, $(this)
      
        url = updateUrlWithIds url, ids, paramName

        link.attr('href', url)

        if link.attr('data-display-class-on-click')
          elementDisplayOnClick = '.' + link.attr('data-display-class-on-click')

          displayActionButton link.attr('data-show-if-check-count'), ids.length, elementDisplayOnClick


  $(document).behave 'load', 'a[data-complete-link-with-ids]', completeUrlWithIds

  return
) jQuery
