### OLD INTERFACE ((E, $) ->
  'use strict'
  # Filters supports with given production
  # Hides supports line if needed
  $(document).behave "load selector:set", "#production_id", (event) ->
    production = $(this)
    id = production.selector('value')
    form = production.closest('form')
    url = "/backend/production_supports/unroll?scope[of_currents_campaigns]=true"
    support = form.find("#production_support_id").first()
    if /^\d+$/.test(id)
      url += "&scope[of_productions]=#{id}"
      form.addClass("with-supports")
    else
      form.removeClass("with-supports")
    support.attr("data-selector", url)
    support.data("selector", url)
) ekylibre, jQuery###


#= require bootstrap/modal

$ ->

  ko.bindingHandlers.checkbox = init: (element, valueAccessor, allBindings, data, context) ->
    $element = undefined
    observable = undefined
    observable = valueAccessor()
    if !ko.isWriteableObservable(observable)
      throw 'You must pass an observable or writeable computed'
    $element = $(element)
    $element.on 'click', ->
      observable !observable()
      return
    ko.computed
      disposeWhenNodeIsRemoved: element
      read: ->
        $element.toggleClass 'active', observable()
        return
    return

  ko.bindingHandlers.modal =
    init: (element, valueAccessor) ->
      $(element).modal show: false
      value = valueAccessor()
      if typeof value == 'function'
        $(element).on 'hide.bs.modal', ->
          value false
          return
      ko.utils.domNodeDisposal.addDisposeCallback element, ->
        $(element).modal 'destroy'
        return
      return
    update: (element, valueAccessor) ->
      value = valueAccessor()
      if ko.utils.unwrapObservable(value)
        $(element).modal 'show'
      else
        $(element).modal 'hide'
      return

  class dashboardViewModel
    constructor: (data,dispForm) ->


      @showAnimalDetailsModal = ko.observable false

      @animalDetailsModalOptions = ko.observable false

      @newContainer = ko.observable ''

      @addContainer = =>
        console.log @newContainer()



      @groups = ko.observableArray []
      @containers = ko.observableArray []
      @animals = ko.observableArray []

      json_data = []
#      json_animals = []
#      json_groups = []
#      json_containers = []

#      json_data = $('.animal-viewport').data 'animals-data'
#      json_animals = $('.animal-viewport').data 'animals-data'
#      json_groups = $('.animal-viewport').data 'animals-groups'
#      json_containers = $('.animal-viewport').data 'animals-containers'

#      ko.utils.arrayForEach json_data, (j) =>
#        console.log j.group
#        if j.group
#          @groups.push new dashboardViewModel.Group(j.group.id, j.group.name)
#        if j.places_and_animals and j.places_and_animals.length > 0
#          console.log j.places_and_animals
#          ko.utils.arrayForEach j.places_and_animals, (container) =>
#            if container.place
#              @containers.push new dashboardViewModel.Container(container.place.id, container.place.name, j.group.id)
#            if container.animals
#              ko.utils.arrayForEach $.parseJSON(container.animals), (animal) =>
#                @animals.push new dashboardViewModel.Animal(animal.id, animal.name, '', '', '', animal.identification_number, container.place.id)



#      @groups = ko.observableArray ko.utils.arrayMap json_groups, (group) ->
#        new dashboardViewModel.Group(group.id, group.name)
#
#      @containers = ko.observableArray ko.utils.arrayMap json_containers, (container) ->
#        new dashboardViewModel.Container(container.id, container.name, container.group_id || 0)
#
#      @animals = ko.observableArray ko.utils.arrayMap json_animals, (animal) ->
#        new dashboardViewModel.Animal(animal.id, animal.name, animal.img, animal.status, animal.sex, animal.number_id, animal.container_id)



      #FIXME: Improve empty group
      #@groups.push new dashboardViewModel.Group(0, 'A trier')

      #FIXME: Improve empty container
#      @containers.push new dashboardViewModel.Container(0, '', 0)

      @filteredContainers = (group) =>

        array = ko.utils.arrayFilter window.app.containers(), (c) =>
          c.group_id == group.id
        array


      @toggleAnimalDetailsModal = (animal) =>
        @animalDetailsModalOptions animal
        @showAnimalDetailsModal true
        return


      @animalSortableHelper = (item, event, ui) ->
        console.log 'parent-helper'
        console.log item, event, ui
        children = false

        if item.data('items') != undefined
          console.log 'data:'
          children = item.data('items')

        return children

      @animalMultiMove = (arg) ->
        console.log arg
        console.log arg.item
        return

    @Group: (id, name) ->
      @id = id
      @name = name
      @toggleItems = ko.observable false
      @toggleItems.subscribe (newValue) =>
        #newValue
        container_array = ko.utils.arrayFilter window.app.containers(), (c) =>
          c.group_id == @id

        all_animals = []

        for container in container_array
          animals = ko.utils.arrayFilter window.app.animals(), (a) =>
            a.container_id == container.id

          for a in animals
            all_animals.push a


        for a in all_animals
          a.checked(newValue)

        return

      return

    @Container: (id, name, group_id) ->
      @id = id
      @name = name
      @group_id = group_id

      @animalCount = ko.pureComputed () =>
        array = ko.utils.arrayFilter window.app.animals(), (a) =>
          a.container_id() == @id

        array.length

      @hidden = ko.observable false
      @toggle = () =>
        @hidden(!@hidden())
        return
      return

    @Animal: (id, name, img, status, sex, number_id, container_id) ->
      @id = id
      @name = name
      @img = ko.pureComputed () =>
        img
      @status = status
      @sex = sex
      #@number_id = number_id
      @animalStatusClass = ko.pureComputed () =>
        if @status == 'go'
          className = "status-ok"
        if @status == 'caution'
          className = "status-warning"
        if @status == 'stop'
          className = "status-danger"
        className

      @animalFlagClass = ko.pureComputed () =>
        if @status == 'go'
          className = "flag-ok"
        if @status == 'caution'
          className = "flag-warning"
        if @status == 'stop'
          className = "flag-danger"
        className

      @container_id = ko.observable container_id
      @checked = ko.observable false
      return

  @loadData = () =>
    console.log 'load data'
    $.ajax '/backend/remote_load_animals',
      type: 'GET',
      dataType: 'JSON',
      beforeSend: () ->
        $('#loading').show()
        return
      complete: () ->
        $('#loading').hide()
        return
      success: (json_data) ->
        console.log json_data
        ko.utils.arrayForEach json_data, (j) =>
          console.log j.group
          if j.group
            window.app.groups.push new dashboardViewModel.Group(j.group.id, j.group.name)
          if j.places_and_animals and j.places_and_animals.length > 0
            console.log j.places_and_animals
            ko.utils.arrayForEach j.places_and_animals, (container) =>
              if container.place
                window.app.containers.push new dashboardViewModel.Container(container.place.id, container.place.name, j.group.id)
              if container.animals
                ko.utils.arrayForEach $.parseJSON(container.animals), (animal) =>
                  window.app.animals.push new dashboardViewModel.Animal(animal.id, animal.name, '', '', '', animal.identification_number, container.place.id)
        return true

      error: (data) ->
        console.log data
        return false

    return

  window.app = new dashboardViewModel
  ko.applyBindings window.app
  window.loadData()
  return
