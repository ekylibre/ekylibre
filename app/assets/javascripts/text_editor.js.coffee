((E, $) ->
  E.insertInto = (input, repdeb, repfin, middle) ->
    if repfin == 'undefined'
      repfin = ' '
    if middle == 'undefined'
      middle = ' '
    input.focus()
    insText = undefined
    pos = undefined

    ### pour l'Explorer Internet ###

    if typeof document.selection != 'undefined'

      ### Insertion du code de formatage ###

      range = document.selection.createRange()
      insText = range.text
      if insText.length <= 0
        insText = middle
      range.text = repdeb + insText + repfin

      ### Ajustement de la position du curseur ###

      range = document.selection.createRange()
      if insText.length == 0
        range.move 'character', -repfin.length
      else
        range.moveStart 'character', repdeb.length + insText.length + repfin.length
      range.select()
    else if typeof input.selectionStart != 'undefined'

      ### Insertion du code de formatage ###

      start = input.selectionStart
      end = input.selectionEnd
      insText = input.value.substring(start, end)
      if insText.length <= 0
        insText = middle
      input.value = input.value.substr(0, start) + repdeb + insText + repfin + input.value.substr(end)

      ### Ajustement de la position du curseur ###

      if insText.length == 0
        pos = start + repdeb.length
      else
        pos = start + repdeb.length + insText.length + repfin.length
      input.selectionStart = pos
      input.selectionEnd = pos
    else

      ### requête de la position d'insertion ###

      re = new RegExp('^[0-9]{0,3}$')
      while !re.test(pos)
        pos = prompt('Insertion à la position (0..' + input.value.length + ') :', '0')
      if pos > input.value.length
        pos = input.value.length

      ### Insertion du code de formatage ###

      insText = prompt('Veuillez entrer le texte à formater :')
      if insText.length <= 0
        insText = middle
      input.value = input.value.substr(0, pos) + repdeb + insText + repfin + input.value.substr(pos)
    return


  $(document).on 'click', 'a[data-insert-into][data-insert]', (event) ->
    element = $(this)
    data = element.data('insert')
    $(element.data('insert-into')).each (index) ->
      E.insertInto this, '', '', data
      return
    false

) ekylibre, jQuery
