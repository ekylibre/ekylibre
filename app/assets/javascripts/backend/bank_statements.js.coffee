((E, $) ->
  "use strict"

  ### Bank statement items edit ###

  itemTableRowId = 0
  $(document).on "cocoon:after-insert", "form.new_bank_statement,form.edit_bank_statement", (event, newItem) ->
    # Add HTML to Clear debit/credit when the other one changes
    className = "bank-statement-item-#{itemTableRowId++}"
    newItem.find("tr").addClass(className)
    newItem.find(".debit").data("exclusive-nullify", ".#{className} .credit")
    newItem.find(".credit").data("exclusive-nullify", ".#{className} .debit")

  ### Bank reconciliation ###

  bankReconciliation = null

  $ ->
    nextReconciliationLetters = $(".bank-reconciliation-items").data("next-letters")
    bankReconciliation = new BankReconciliation(nextReconciliationLetters)

    datePickerContainer = $(".add-bank-statement-item-cont")
    datePickerOnSelect = $.proxy(bankReconciliation.createBankStatementItem, bankReconciliation)
    new DatePickerButton(datePickerContainer, datePickerOnSelect)

    bankReconciliation.initialize()

  $(document).on "click", "a.destroy", ->
    # Remove bank statement item
    button = $(@)
    bankStatementItem = bankReconciliation.closestLine(button)
    bankReconciliation.destroyBankStatementItem bankStatementItem
    return false

  $(document).on "click", ".bank-statement-item-type:not(.selected), .journal-entry-item-type:not(.selected)", (event) ->
    # Select line
    return if $(event.target).is("input,a")
    bankReconciliation.selectLine $(@)

  $(document).on "click", ".bank-statement-item-type.selected, .journal-entry-item-type.selected", (event) ->
    # Deselect line
    return if $(event.target).is("input,a")
    bankReconciliation.deselectLine $(@)

  $(document).on "click", ".bank-statement-item-type .clear a, .journal-entry-item-type .clear a", ->
    # Clear reconciliation letter
    button = $(@)
    line = bankReconciliation.closestLine(button)
    bankReconciliation.clearReconciliationLetterFromLine line
    return false

  $(document).on "click", ".journal-entry-item-type .complete a", ->
    # Complete journal entry items
    button = $(@)
    line = bankReconciliation.closestLine(button)
    bankReconciliation.completeJournalEntryItems line
    return false

  $(document).on "change keyup", ".bank-statement-item-type input.debit, .bank-statement-item-type input.credit", ->
    # Debit or credit update
    input = $(@)
    line = bankReconciliation.closestLine(input)
    bankReconciliation.lineUpdated(line)

  $(document).on "submit", "form.reconciliation-form", ->
    # Form submission
    return false unless bankReconciliation.checkValidity()

  $(document).on "click", "#reset_reconciliation", ->
    # Reset reconciliation
    bankReconciliation.clearAllReconciliationLetters()

  $(document).on "click", "#auto_reconciliation", ->
    # Automatic reconciliation
    bankReconciliation.autoReconciliate()

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


  class BankReconciliation
    constructor: (@reconciliationLetters) ->

    initialize: ->
      @autoReconciliate()
      @_uiUpdate()

    # Accessors

    closestLine: (element) ->
      element.closest @_lines()

    # Add bank statement items

    createBankStatementItem: (date) ->
      return if @_addBankStatementItemInDateSection(date)
      @_insertDateSection date
      @_addBankStatementItemInDateSection date

    _insertDateSection: (date) ->
      template = $(".tmpl-date")[0].outerHTML
      html = template.replace(/tmpl-date/g, date)
      dateSections = $(".date-separator:not(.tmpl-date)")
      nextDateSection = dateSections.filter(-> $(@).data("date") > date).first()
      if nextDateSection.length
        nextDateSection.before html
      else
        $(".bank-reconciliation-items tbody").append html

    _addBankStatementItemInDateSection: (date) ->
      buttonInDateSection = $(".#{date} a")
      return false unless buttonInDateSection.length
      buttonInDateSection.click()
      true

    # Add bank statement items from selected journal entry items

    completeJournalEntryItems: (clickedLine) ->
      reconciliationLetter = @_getNextReconciliationLetter()
      params = { letter: reconciliationLetter }

      selectedJournalEntryItems = @_lines().filter(".journal-entry-item-type.selected")
      debit = selectedJournalEntryItems.find(".debit").sum()
      credit = selectedJournalEntryItems.find(".credit").sum()
      balance = debit - credit
      if balance > 0
        params.credit = balance
      else
        params.debit = -balance

      date = @_dateForLine(clickedLine)
      buttonInDateSection = $(".#{date} a")
      buttonInDateSection.one "ajax:beforeSend", (event, xhr, settings) ->
        settings.url += "&#{$.param(params)}"
      buttonInDateSection.one "ajax:complete", (event, xhr, status) =>
        # use ajax:complete to ensure elements are already added to the DOM
        return unless status is "success"
        @_reconciliateLines selectedJournalEntryItems, reconciliationLetter
        @_uiUpdate()
      buttonInDateSection.click()

    # Remove bank statement items

    destroyBankStatementItem: (bankStatementItem) ->
      letter = @_reconciliationLetter(bankStatementItem)
      @_removeLine bankStatementItem
      @_clearLinesWithReconciliationLetter letter
      @_reconciliateSelectedLinesIfValid()
      @_uiUpdate()

    _removeLine: (line) ->
      previous = line.prev("tr")
      next = line.next("tr")
      if @_isDateSection(previous) && (!next.length || @_isDateSection(next))
        previous.deepRemove()
      line.deepRemove()

    _isDateSection: (line) ->
      line.hasClass("date-separator")

    # Select/deselect lines

    selectLine: (line) ->
      return if @_isLineReconciliated(line)
      line.addClass "selected"
      @_reconciliateSelectedLinesIfValid()
      @_uiUpdate()

    deselectLine: (line) ->
      line.removeClass "selected"
      @_reconciliateSelectedLinesIfValid()
      @_uiUpdate()

    # Line update

    lineUpdated: (line) ->
      if @_isLineReconciliated(line)
        letter = @_reconciliationLetter(line)
        @_clearLinesWithReconciliationLetter letter
        @_uiUpdate()
      else if line.is(".selected")
        @_reconciliateSelectedLinesIfValid()
        @_uiUpdate()
      else
        # prevent full UI update on input change
        @_updateReconciliationBalances()

    # Validity

    checkValidity: ->
      initialBalanceValid = @_checkInitialBalanceValidity()
      linesValid = @_checkLinesValidity()
      initialBalanceValid && linesValid

    _checkInitialBalanceValidity: ->
      debitInput = $("#initial_balance_debit")
      creditInput = $("#initial_balance_credit")
      debitValid = !isNaN(debitInput.val())
      creditValid = !isNaN(creditInput.val())
      return true if debitValid && creditValid
      @_markErrorOnInput(debitInput) if !debitValid
      @_markErrorOnInput(debitInput) if !creditValid
      return false

    _markErrorOnInput: (input) ->
      input.addClass "error"
      input.one "change keyup", -> $(@).removeClass "error"

    _checkLinesValidity: ->
      bankStatementItems = @_lines().filter(".bank-statement-item-type")
      invalidLines = bankStatementItems.filter (i, e) => not @_isLineValid($(e))
      return true unless invalidLines.length
      @_markErrorOnLines invalidLines
      return false

    _isLineValid: (line) ->
      nameInput = line.find("input.name")
      debitInput = line.find("input.debit")
      creditInput = line.find("input.credit")
      nameValid = !nameInput.length || !!nameInput.val()
      debitValid = !debitInput.length || !isNaN(debitInput.val())
      creditValid = !creditInput.length || !isNaN(creditInput.val())
      nameValid && debitValid && creditValid

    _markErrorOnLines: (lines) ->
      lines.addClass "error"
      lines.on "change keyup", "input.name, input.debit, input.credit", (e) =>
        input = $(e.currentTarget)
        @closestLine(input).removeClass "error"

    # Reconciliation methods

    clearAllReconciliationLetters: ->
      letters = []
      @_reconciliatedLines().each (i, e) =>
        letter = @_reconciliationLetter($(e))
        letters.push(letter) unless letters.includes(letter)
      @_clearLinesWithReconciliationLetter(letter) for letter in letters
      @_uiUpdate()

    clearReconciliationLetterFromLine: (line) ->
      letter = @_reconciliationLetter(line)
      return unless letter
      @_clearLinesWithReconciliationLetter letter
      @_uiUpdate()

    autoReconciliate: ->
      notReconciliated = @_notReconciliatedLines()
      bankItems = notReconciliated.filter(".bank-statement-item-type")
      journalItems = notReconciliated.filter(".journal-entry-item-type")

      bankItems.each (i, e) =>
        date = @_dateForLine($(e))
        credit = @_creditForLine($(e))
        debit = @_debitForLine($(e))
        similarBankItems = @_filterLinesBy(bankItems, date: date, credit: credit, debit: debit)
        return if similarBankItems.length isnt 1
        similarJournalItems = @_filterLinesBy(journalItems, date: date, credit: debit, debit: credit)
        return if similarJournalItems.length isnt 1
        reconciliationLetter = @_getNextReconciliationLetter()
        @_reconciliateLines $(e).add(similarJournalItems), reconciliationLetter
        @_uiUpdate()

    _reconciliateSelectedLinesIfValid: ->
      selected = @_lines().filter(".selected")
      return unless @_areLineValidForReconciliation(selected)
      letter = @_getNextReconciliationLetter()
      @_reconciliateLines selected, letter

    _reconciliateLines: (lines, letter) ->
      lines.find(".bank-statement-letter:not(input)").text letter
      lines.find("input.bank-statement-letter").val letter
      lines.removeClass "selected"

    _areLineValidForReconciliation: (lines) ->
      return false unless lines.length
      journalEntryItems = lines.filter(".journal-entry-item-type")
      journalEntryItemsDebit = journalEntryItems.find(".debit").sum()
      journalEntryItemsCredit = journalEntryItems.find(".credit").sum()
      journalEntryItemsBalance = journalEntryItemsDebit - journalEntryItemsCredit
      bankStatementItems = lines.filter(".bank-statement-item-type")
      bankStatementItemsDebit = bankStatementItems.find(".debit").sum()
      bankStatementItemsCredit = bankStatementItems.find(".credit").sum()
      bankStatementItemsBalance = bankStatementItemsDebit - bankStatementItemsCredit
      journalEntryItemsBalance is -bankStatementItemsBalance

    _clearLinesWithReconciliationLetter: (letter) ->
      return unless letter
      lines = @_linesWithReconciliationLetter(letter)
      lines.find(".bank-statement-letter:not(input)").text ""
      lines.find("input.bank-statement-letter").val null
      @_releaseReconciliationLetter letter

    _getNextReconciliationLetter: ->
      @reconciliationLetters.shift()

    _releaseReconciliationLetter: (letter) ->
      insertIndex = @reconciliationLetters.findIndex (l) ->
        return true if l.length > letter.length
        (return true if char > letter[index]) for char, index in l
        false
      @reconciliationLetters.splice insertIndex, 0, letter

    _reconciliatedLines: ->
      @_lines().filter (i, e) => @_isLineReconciliated($(e))

    _notReconciliatedLines: ->
      @_lines().filter (i, e) => not @_isLineReconciliated($(e))

    _isLineReconciliated: (line) ->
      !!@_reconciliationLetter(line)

    _linesWithReconciliationLetter: (letter) ->
      @_lines().filter (i, e) => @_reconciliationLetter($(e)) is letter

    _reconciliationLetter: (line) ->
      line.find("input.bank-statement-letter").val()

    # Display update

    _uiUpdate: ->
      @_showOrHideClearButtons()
      @_showOrHideCompleteButtons()
      @_updateReconciliationBalances()

    _showOrHideClearButtons: ->
      @_notReconciliatedLines().find(".clear a").hide()
      @_reconciliatedLines().find(".clear a").show()

    _showOrHideCompleteButtons: ->
      $(".journal-entry-item-type.selected .complete a").show()
      $(".journal-entry-item-type:not(.selected) .complete a").hide()

    _updateReconciliationBalances: ->
      all = @_lines().filter(".bank-statement-item-type")
      allDebit = all.find(".debit").sum()
      allCredit = all.find(".credit").sum()
      allBalance = allDebit - allCredit

      reconciliated = @_reconciliatedLines().filter(".bank-statement-item-type")
      reconciliatedDebit = reconciliated.find(".debit").sum()
      reconciliatedCredit = reconciliated.find(".credit").sum()
      reconciliatedBalance = reconciliatedDebit - reconciliatedCredit

      remainingDebit = allDebit - reconciliatedDebit
      remainingCredit = allCredit - reconciliatedCredit

      @_updateReconciliationBalance reconciliatedDebit, reconciliatedCredit
      @_updateRemainingReconciliationBalance remainingDebit, remainingCredit

      $(".reconciliated-debit").toggleClass("valid", allDebit is reconciliatedDebit)
      $(".reconciliated-credit").toggleClass("valid", allCredit is reconciliatedCredit)
      $(".remaining-reconciliated-debit").toggleClass("valid", remainingDebit is 0)
      $(".remaining-reconciliated-credit").toggleClass("valid", remainingCredit is 0)

    _updateReconciliationBalance: (debit, credit) ->
      $(".reconciliated-debit").text debit.toFixed(2)
      $(".reconciliated-credit").text credit.toFixed(2)

    _updateRemainingReconciliationBalance: (debit, credit) ->
      $(".remaining-reconciliated-debit").text debit.toFixed(2)
      $(".remaining-reconciliated-credit").text credit.toFixed(2)

    # Other methods

    _lines: ->
      $(".bank-statement-item-type,.journal-entry-item-type")

    _filterLinesBy: (lines, filters) ->
      { date, debit, credit } = filters
      lines.filter (i, e) =>
        return if @_dateForLine($(e)) isnt date
        @_debitForLine($(e)) is debit && @_creditForLine($(e)) is credit

    _dateForLine: (line) ->
      line.prevAll(".date-separator:first").data("date")

    _creditForLine: (line) ->
      creditElement = line.find(".credit")
      @_floatValueForTextOrInput(creditElement)

    _debitForLine: (line) ->
      debitElement = line.find(".debit")
      @_floatValueForTextOrInput(debitElement)

    _floatValueForTextOrInput: (element) ->
      value = if element.is("input") then element.val() else element.text()
      parseFloat(value || 0)

) ekylibre, jQuery