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

    @flagClass = ko.pureComputed () =>
      return "lights-#{@status}"
    @showUrl = ko.pureComputed () =>
      "/backend/animals/#{@id}"

    @checked = ko.observable false
    return