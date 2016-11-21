class golumn.Group
  constructor: (@id, @name, @edit_path, containers) ->
    @containers = ko.observableArray([])
    @toggleItems = ko.observable false
    @droppable = ko.observable false

    @count = ko.pureComputed () =>
      c = 0
      ko.utils.arrayForEach @containers(), (container) =>
        c += container.count()
      c

    @toggleItems.subscribe (newValue) =>

      ko.utils.arrayForEach @containers(), (container) =>
        container.toggleItems newValue
