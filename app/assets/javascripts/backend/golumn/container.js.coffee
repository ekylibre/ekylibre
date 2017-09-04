class golumn.Container
  constructor: (id, @name, items, @parent) ->
    @id = ko.observable id
    @toggleItems = ko.observable false
    @items = ko.observableArray(items)
    @count = ko.pureComputed () =>
      @items().length
    @hidden = ko.observable false
    @toggle = () =>
      @hidden(!@hidden())
      return
    @droppable = ko.observable false
    @protect = false

    @toggleItems.subscribe (newValue) =>

      ko.utils.arrayForEach @items(), (item) =>
        item.checked newValue
