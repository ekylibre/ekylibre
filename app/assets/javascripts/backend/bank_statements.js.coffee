((E, $) ->
  "use strict"

  ### DatePicker ###

  class DatePickerButton
    # Used to display a datepicker on a button click while the date input
    # remains hidden
    constructor: (@container, @onSelect) ->
      @dateInput = @container.find("input[type=date]")
      @dateInput.hide()
      @_initializeDatePicker()
      @_findAndCustomizeButton()

    _initializeDatePicker: ->
      @dateInput.datepicker
        showOn: "button"
        buttonText: @dateInput.data("label")
        onSelect: @onSelect
        dateFormat: "yy-mm-dd"
      @dateInput.attr "autocomplete", "off"

    _findAndCustomizeButton: ->
      @button = @container.find(".ui-datepicker-trigger")
      @button.addClass(classes) if classes = @dateInput.data("classes")

  ### Bank reconciliation ###

  bankReconciliation = null

  $ ->
    precision = parseInt($(".reconciliation-list").data('currency-precision'))
    bankReconciliation = new BankReconciliation(precision)

    datePickerContainer = $(".totals #new-item")
    datePickerOnSelect = $.proxy(bankReconciliation.createBankStatementItem, bankReconciliation)
    new DatePickerButton(datePickerContainer, datePickerOnSelect)

    bankReconciliation.initialize()

    position_space = new RegExp(".*scroll_to=(\\d+).*")
    position = position_space.exec location.search
    if position
      $("#hide-lettered").attr('checked', false)
      $("#hide-lettered").change()

      scrollTo = $("[data-type=bank_statement_item][data-id=#{position[1]}]").parents('.date-section')[0]
      $('.list').scrollTop(scrollTo.offsetTop - $('.list')[0].offsetTop)

  $(document).on "click", ".reconciliation-item[data-type=bank_statement_item] a#delete", ->
    # Remove bank statement item
    button = $(@)
    bankStatementItem = bankReconciliation.closestLine(button)
    bankReconciliation.destroyLine bankStatementItem
    return false

  $(document).on "click", ".reconciliation-item:not(.selected)", (event) ->
    # Select line
    return if $(event.target).is("input,a,form")
    bankReconciliation.selectLine $(@)

  $(document).on "click", ".reconciliation-item.selected", (event) ->
    # Deselect line
    return if $(event.target).is("input,a")
    bankReconciliation.deselectLine $(@)

  $(document).on "click", ".reconciliation-item a#clear", ->
    # Clear reconciliation letter
    button = $(@)
    line = bankReconciliation.closestLine(button)
    bankReconciliation.clearReconciliationLetterFromLine line
    return false

  $(document).on "click", ".reconciliation-item[data-type=journal_entry_item] a#complete", ->
    # Complete journal entry items
    button = $(@)
    line = bankReconciliation.closestLine(button)
    bankReconciliation.completeJournalEntryItems line
    return false

  $(document).on "confirm:complete", "#reset_reconciliation", (e, response) ->
    if response
      bankReconciliation.clearAllReconciliationLetters()

  $(document).on "click", "#auto_reconciliation", ->
    # Automatic reconciliation
    bankReconciliation.autoReconciliate()

  $(document).on "change", "#hide-lettered", ->
    bankReconciliation.uiUpdate()

  $(document).on "datepicker-change", "#set_period", (event, dates) ->
    current_params = document.location.search

    start = dates.date1
    start = "period_start=#{start.getFullYear()}-#{start.getMonth()+1}-#{start.getDate()}"
    param_space = new RegExp("(&|\\?)period_start=[^\&]*")
    if param_space.exec(current_params)
      current_params = current_params.replace(param_space, "$1" + start)
    else
      current_params += (if current_params.length > 0 then '&' else '?') + start

    end = dates.date2
    end = "period_end=#{end.getFullYear()}-#{end.getMonth()+1}-#{end.getDate()}"
    param_space = new RegExp("(&|\\?)period_end=[^\&]*")
    if param_space.exec(current_params)
      current_params = current_params.replace(param_space, "$1" + end)
    else
      current_params += (if current_params.length > 0 then '&' else '?') + end

    document.location.search = current_params

  class BankReconciliation
    constructor: (@precision) ->

    initialize: ->
      @uiUpdate()

    # Accessors

    closestLine: (element) ->
      element.closest @_lines()

    ## NEW BANK STATEMENT ITEMS

    # Add bank statement items

    createBankStatementItem: (date) ->
      return if @_addBankStatementItemInDateSection(date)
      @_insertDateSection date
      @_addBankStatementItemInDateSection date

    _addBankStatementItemInDateSection: (date) ->
      dateSection = $(".date-header p[data-date=#{date}]")
      newItemButton = dateSection.parent(".date-header").find('a')
      return false unless newItemButton.length
      newItemButton.click()
      true

    _insertDateSection: (date) ->
      template = $($(".date-header p[data-date=tmpl-date]")[0]).parents(".date-section")[0].outerHTML
      html = template.replace(/tmpl-date/g, date)
      html = $(html).removeClass('hidden')[0].outerHTML
      dateSections = $(".date-header p[data-date!=tmpl-date]")
      nextDateSection = dateSections.filter(-> $(@).data("date") > date).first()
      if nextDateSection.length
        nextDateSection.parent(".date-section").before html
      else
        $(".reconciliation-list .totals").before html

    # Add bank statement items from selected journal entry items

    completeJournalEntryItems: (clickedLine) ->
      params =
        name: clickedLine.find('.name').first().html()

      selectedJournalEntryItems = @_lines().filter("[data-type=journal_entry_item].selected")
      debit = selectedJournalEntryItems.find(".debit").sum()
      credit = selectedJournalEntryItems.find(".credit").sum()
      balance = debit - credit
      if balance > 0
        params.credit = balance
      else
        params.debit = -balance

      date = @_dateForLine(clickedLine)
      buttonInDateSection = $(".date-header p[data-date=#{date}]").parent(".date-header").find('a')
      buttonInDateSection.one "ajax:beforeSend", (event, xhr, settings) ->
        for key,value of params
          settings.url += "&bank_statement_item[#{key}]=#{value}"
      buttonInDateSection.one "ajax:complete", (event, xhr, status) =>
        # use ajax:complete to ensure elements are already added to the DOM
        return unless status is "success"
        @uiUpdate()
      buttonInDateSection.click()

    # Remove bank statement items

    destroyLine: (line) ->
      if line.data('id')? then @_deleteLine(line) else @_destroyBankStatementItem(line);

    _destroyBankStatementItem: (bankStatementItem) ->
      @_removeLine bankStatementItem
      @_clearLinesWithReconciliationLetter @_reconciliationLetter(bankStatementItem)
      @_reconciliateSelectedLinesIfValid()
      @uiUpdate()

    _removeLine: (line) ->
      form = line.parents('form')
      parent = line.parents('.date-section')
      siblings = parent.find('.reconciliation-item')
      line.deepRemove()
      form.deepRemove() if form?
      if siblings.length <= 1
        parent.deepRemove()

    _isDateSection: (line) ->
      line.hasClass("date-header")

    # Select/deselect lines

    selectLine: (line) ->
      return if @_isLineReconciliated(line) or isNaN(@_idForLine(line))
      line.addClass "selected"
      @_reconciliateSelectedLinesIfValid()
      @uiUpdate()

    deselectLine: (line) ->
      line.removeClass "selected"
      @_reconciliateSelectedLinesIfValid()
      @uiUpdate()

    # Reconciliation methods

    clearAllReconciliationLetters: ->
      letters = []
      @_reconciliatedLines().each (i, e) =>
        letter = @_reconciliationLetter($(e))
        letters.push(letter) unless letters.includes(letter)
      @_clearLinesWithReconciliationLetter(letter) for letter in letters
      @uiUpdate()

    clearReconciliationLetterFromLine: (line) ->
      letter = @_reconciliationLetter(line)
      return unless letter
      @_clearLinesWithReconciliationLetter letter
      @uiUpdate()

    autoReconciliate: ->
      notReconciliated = @_notReconciliatedLines()
      bankItems = notReconciliated.filter("[data-type=bank_statement_item]")
      journalItems = notReconciliated.filter("[data-type=journal_entry_item]")

      bankItems.each (i, e) =>
        date = @_dateForLine($(e))
        credit = @_creditForLine($(e))
        debit = @_debitForLine($(e))
        similarBankItems = @_filterLinesBy(bankItems, date: date, credit: credit, debit: debit)
        return if similarBankItems.length isnt 1
        similarJournalItems = @_filterLinesBy(journalItems, date: date, credit: debit, debit: credit)
        return if similarJournalItems.length isnt 1
        @_letterItems $(e).add(similarJournalItems)
      @uiUpdate()

    _reconciliateSelectedLinesIfValid: ->
      selected = @_lines().filter(".selected")
      return unless @_areLineValidForReconciliation(selected)
      @_letterItems selected

    _areLineValidForReconciliation: (lines) ->
      return false unless lines.length
      journalEntryItems = lines.filter("[data-type=journal_entry_item]")
      journalEntryItemsDebit = journalEntryItems.find(".debit").sum()
      journalEntryItemsCredit = journalEntryItems.find(".credit").sum()
      journalEntryItemsBalance = Math.round((journalEntryItemsDebit - journalEntryItemsCredit) * Math.pow(10, @precision))
      bankStatementItems = lines.filter("[data-type=bank_statement_item]")
      bankStatementItemsDebit = bankStatementItems.find(".debit").sum()
      bankStatementItemsCredit = bankStatementItems.find(".credit").sum()
      bankStatementItemsBalance = Math.round((bankStatementItemsDebit - bankStatementItemsCredit) * Math.pow(10, @precision))
      journalEntryItemsBalance is -bankStatementItemsBalance

    _clearLinesWithReconciliationLetter: (letter) ->
      return unless letter
      @_unletterItems letter

    _reconciliatedLines: ->
      @_lines().filter (i, e) => @_isLineReconciliated($(e))

    _notReconciliatedLines: ->
      @_lines().filter (i, e) => not @_isLineReconciliated($(e))

    _isLineReconciliated: (line) ->
      !!@_reconciliationLetter(line)

    _linesWithReconciliationLetter: (letter) ->
      @_lines().filter (i, e) => @_reconciliationLetter($(e)) is letter

    _reconciliationLetter: (line) ->
      line.find(".details .letter").text()

    # UI UPDATING

    uiUpdate: ->
      @_showOrHideClearButtons()
      @_showOrHideCompleteButtons()
      @_showOrHideNewPaymentButtons()
      @_showOrHideReconciliatedLines()

    _showOrHideClearButtons: ->
      @_showAndHideLinkForCollection 'clear',
        @_reconciliatedLines().find(".details a"),
        @_notReconciliatedLines().find(".details a")

    _showOrHideCompleteButtons: ->
      @_showAndHideLinkForCollection 'complete',
        $("[data-type=journal_entry_item].selected .details a"),
        $("[data-type=journal_entry_item]:not(.selected) .details a")

    _showAndHideLinkForCollection: (linkType, toShow, toHide) ->
      toShow.each ->
        $(this).attr('id', linkType)
        $(this).find('span').html($(this).data("name-#{linkType}"))
      toHide.each ->
        if $(this).attr('id') == linkType
          $(this).find('span').html('')
          $(this).attr('id', '')

    _showOrHideNewPaymentButtons: ->
      selectedBankStatements = @_bankStatementLines().filter(".selected")
      selectedJournalItems   = @_journalEntryLines().filter(".selected")
      if selectedBankStatements.length > 0
        @_updateIdsInButtons()
        $("a.from-selected-bank").show()
        $("a.from-selected-bank").parents('.btn-group').show()
      else
        $("a.from-selected-bank").hide()
        $("a.from-selected-bank").parents('.btn-group').hide()

      if selectedJournalItems.length > 0
        @_updateIdsInButtons()
        $("a.from-selected-journal").show()
        $("a.from-selected-journal").parents('.btn-group').show()
      else
        $("a.from-selected-journal").hide()
        $("a.from-selected-journal").parents('.btn-group').hide()

      unless selectedBankStatements.length > 0 and selectedJournalItems.length > 0
        $("a.from-selected-journal.from-selected-bank").hide()
        $("a.from-selected-journal.from-selected-bank").parents('.btn-group').hide()

    _showOrHideReconciliatedLines: ->
      if $("#hide-lettered").is(":checked")
        @_reconciliatedLines().hide()
      else
        @_reconciliatedLines().show()

    _updateIdsInButtons: ->
      @_updateItemIdsInButtons()
      @_updateEntryIdsInButtons()

    _updateItemIdsInButtons: ->
      @_updateIdsInButtonsFor('.from-selected-bank', 'bank_statement_item')

    _updateEntryIdsInButtons: ->
      @_updateIdsInButtonsFor('.from-selected-journal', 'journal_entry_item')

    _updateIdsInButtonsFor: (selector, type) ->
      selectedLines = @_lines().filter("[data-type=#{type}].selected")
      ids = selectedLines.get().map (line) =>
        @_idForLine(line)
      with_questionmark = new RegExp(".*/\\w+(\\?).*?")
      id_space = new RegExp("(.(?!/)*/\\w+\\?.*?)(&?#{type}_ids\\[\\]=.*)+(&.*)?")
      $(selector).each (i, button) ->
        url = $(button).attr('href')
        if with_questionmark.exec url
          url = url + "&#{type}_ids[]=PLACEHOLDER" unless id_space.exec url
        else
          url = url + "?#{type}_ids[]=PLACEHOLDER" unless id_space.exec url
        url = url.replace(id_space, "$1&#{type}_ids[]=#{ids.join("&#{type}_ids[]=")}$3")
        $(button).attr('href', url)

    # AJAX CALLS

    _letterItems: (lines) ->
      journalLines = lines.filter(":not(.lettered)[data-type=journal_entry_item]")
      journalIds = journalLines.get().map (line) =>
        @_idForLine line
      bankLines = lines.filter(":not(.lettered)[data-type=bank_statement_item]")
      bankIds = bankLines.get().map (line) =>
        @_idForLine line
      url = window.location.pathname.split('/').slice(0, -1).join('/') + '/letter'
      $.ajax url,
        type: 'PATCH'
        dataType: 'JSON'
        data:
          journal_entry_items: journalIds
          bank_statement_items: bankIds
        success: (response) =>
          lines.find(".details .letter").text response.letter
          lines.removeClass "selected"
          lines.addClass "lettered"
          $(lines).find(".debit, .credit").trigger "change"
          @uiUpdate()
          return true
        error: (data) ->
          alert 'Error while lettering the lines.'
          console.log data
          return false

    _unletterItems: (letter) ->
      url = window.location.pathname.split('/').slice(0, -1).join('/') + '/unletter'
      $.ajax url,
        type: 'PATCH'
        dataType: 'JSON'
        data:
          letter: letter
        success: (response) =>
          lines = @_linesWithReconciliationLetter(response.letter)
          lines.find(".details .letter").text ""
          lines.removeClass "lettered"
          $(lines).find(".debit, .credit").trigger "change"
          @uiUpdate()
          return true
        error: (data) ->
          alert 'Error while unlettering the lines.'
          console.log data
          return false

    _deleteLine: (line) ->
      url = (window.location.pathname.split('/').slice(0, -1).concat ['bank-statement-items', line.data('id')]).join('/')
      $.ajax url,
        type: 'DELETE'
        dataType: 'JSON'
        success: (response) =>
          @_destroyBankStatementItem $(".reconciliation-item[data-id=#{response.id}]")
          return true
        error: (data) ->
          alert 'Error while deleting the line.'
          console.log data
          return false

    # HELPER METHODS

    _lines: ->
      $(".reconciliation-item")

    _bankStatementLines: ->
      $(".reconciliation-item[data-type=bank_statement_item]")

    _journalEntryLines: ->
      $(".reconciliation-item[data-type=journal_entry_item]")

    _filterLinesBy: (lines, filters) ->
      { date, debit, credit } = filters
      lines.filter (i, e) =>
        return if @_dateForLine($(e)) isnt date
        @_debitForLine($(e)) is debit && @_creditForLine($(e)) is credit

    _dateForLine: (line) ->
      line.prevAll(".date-header:first").find('p').text()

    _creditForLine: (line) ->
      creditElement = line.find(".credit")
      @_floatValueForTextOrInput(creditElement)

    _debitForLine: (line) ->
      debitElement = line.find(".debit")
      @_floatValueForTextOrInput(debitElement)

    _floatValueForTextOrInput: (element) ->
      value = if element.is("input") then element.val() else element.text()
      parseFloat(value || 0)

    _idForLine: (line) ->
      parseInt($(line).data('id'))

) ekylibre, jQuery
