class golumn.Container
  constructor: (id, @name, @items, @parent, trackable = false) ->
    @id = ko.observable id
#    @name = ko.observable name
    @count = ko.pureComputed () =>
      @items().length
    @hidden = ko.observable false
    @toggle = () =>
      @hidden(!@hidden())
      return
    @droppable = ko.observable false
