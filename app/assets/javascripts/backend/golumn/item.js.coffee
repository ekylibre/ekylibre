class golumn.Item
  constructor: (@id, @name, @img, @status, @sex, @number_id, @parent) ->
    @sexClass = ko.pureComputed () =>
      #TODO get sex key from backend instead of human name
      if @sex == 'Mâle'
        className = "icon-mars"
      if @sex == 'Femelle'
        className = "icon-venus"
      className
    @statusClass = ko.pureComputed () =>
      return "status-#{@status}"

    @stateClass = ko.pureComputed () =>
      klass = @statusClass()
      if @checked()
        klass += ' active'
      klass

    @flagClass = ko.pureComputed () =>
      return "lights-#{@status}"
    @showUrl = ko.pureComputed () =>
      "/backend/animals/#{@id}"

    @checked = ko.observable false
    @checked.subscribe (newValue) =>
      if newValue
        @parent.protect = true
        app.selectedItemsIndex[@id] = @
      else
        @parent.protect = false
        delete app.selectedItemsIndex[@id]

    return