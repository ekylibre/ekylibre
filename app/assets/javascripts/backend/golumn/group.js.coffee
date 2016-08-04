class golumn.Group
  constructor: (@id, @name, @containers) ->
    @toggleItems = ko.observable false
#    @toggleItems.subscribe (newValue) =>
#
#      container_array = ko.utils.arrayFilter window.app.containers(), (c) =>
#        c.group_id() == @id
#
#      ko.utils.arrayForEach container_array, (c) =>
#        ko.utils.arrayForEach window.app.animals(), (a) =>
#          if a.container_id() == c.id and a.group_id() == @id
#            a.checked newValue
