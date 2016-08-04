class golumn.Container
  constructor: (@id, @name, @items, @parent) ->
    @count = ko.pureComputed () =>
      @items().length
    @hidden = ko.observable false
    @toggle = () =>
      @hidden(!@hidden())
      return
