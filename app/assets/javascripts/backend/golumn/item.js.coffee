class golumn.Item
  constructor: (@id, @name, @status, @sex, @show_path = '', @parent) ->

    @sexClass = ko.pureComputed () =>
      if @sex == 'male' then "icon-mars" else if @sex == 'female' then 'icon-venus' else ''

    @statusClass = ko.pureComputed () =>
      return "status-#{@status}"

    @stateClass = ko.pureComputed () =>
      klass = @statusClass()
      if @checked()
        klass += ' active'
      klass

    @flagClass = ko.pureComputed () =>
      return "lights-#{@status}"

    @checked = ko.observable false
    @checked.subscribe (newValue) =>
      if newValue
        @parent.protect = true
        app.selectedItemsIndex[@id] = @
        app.impactOnSelection()
      else
        @parent.protect = false
        delete app.selectedItemsIndex[@id]
        app.impactOnSelection()

    return