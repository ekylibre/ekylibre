class golumn.Container
  constructor: (id, @name, items, @parent) ->
    @id = ko.observable id
    @items = ko.observableArray(items)
    @count = ko.pureComputed () =>
      @items().length
    @hidden = ko.observable false
    @toggle = () =>
      @hidden(!@hidden())
      return
    @droppable = ko.observable false

    @toggleItems = (state) =>

      ko.utils.arrayForEach @items(), (item) =>
        item.checked state
