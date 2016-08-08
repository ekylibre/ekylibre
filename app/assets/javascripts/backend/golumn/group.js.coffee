class golumn.Group
  constructor: (@id, @name, @containers) ->
    @toggleItems = ko.observable false
    @droppable = ko.observable false

    @toggleItems.subscribe (newValue) =>

      ko.utils.arrayForEach @containers(), (container) =>
        container.toggleItems newValue
