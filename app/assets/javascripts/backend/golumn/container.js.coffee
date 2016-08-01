class golumn.Container
  constructor: (@id, @name, items) ->
    @items = ko.observableArray(items)
    @count = ko.pureComputed () =>
      @items().length
    @hidden = ko.observable false
    @toggle = () =>
      @hidden(!@hidden())
      return
