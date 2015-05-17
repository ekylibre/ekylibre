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

      ### #fake data
      json_groups = [{id:1, name: 'Vaches laitières 1'},{id:2, name: 'Vaches laitières 2'}]
      json_containers = [{id:1, name: 'Zone de parcours', group_id:1},{id:2, name:'Zone 2', group_id:1},{id:3, name: 'Zone de parcours 2', group_id:2},{id:4, name:'Zone 3', group_id:2}]
      json_animals = [{id:1, name: 'Ghislaine', img: "Vache.jpg", status: 1, sex: 0, container_id: 1}, {id:2, name: 'Vanille', img: "Vache2.jpg", status: 1, sex: 0, container_id: 1}, {id:3, name: 'Virginie', img: "Vache3.jpg", status: 2, sex: 0, container_id: 2}, {id:4, name: 'Colombe', img: "Vache.jpg", status: 2, sex: 0, container_id: 3}, {id:5, name: 'Coralie', img: "Vache3.jpg", status: 3, sex: 0, container_id: 4}]
      ###

      json_groups = []
      json_containers = []
      json_animals = []
      json_animals = $('.animal-viewport').data 'animals-data'
      json_containers = $('.animal-viewport').data 'animals-containers'
      json_groups = $('.animal-viewport').data 'animals-groups'

      console.log json_animals

      @showAnimalDetailsModal = ko.observable false

      @animalDetailsModalOptions = ko.observable false

      @groups = ko.observableArray ko.utils.arrayMap json_groups, (group) ->
        new dashboardViewModel.Group(group.id, group.name)


      #FIXME: Improve empty group
      @groups.push new dashboardViewModel.Group(0, 'A trier')


      @containers = ko.observableArray ko.utils.arrayMap json_containers, (container) ->
        new dashboardViewModel.Container(container.id, container.name, container.group_id || 0)

      #FIXME: Improve empty container
      @containers.push new dashboardViewModel.Container(0, '', 0)

      @animals = ko.observableArray ko.utils.arrayMap json_animals, (animal) ->
        new dashboardViewModel.Animal(animal.id, animal.name, animal.img, animal.status, animal.sex, animal.number_id, animal.container_id)



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
        if @status == 1
          className = "status-ok"
        if @status == 2
          className = "status-warning"
        if @status == 3
          className = "status-danger"
        className

      @animalFlagClass = ko.pureComputed () =>
        if @status == 1
          className = "flag-ok"
        if @status == 2
          className = "flag-warning"
        if @status == 3
          className = "flag-danger"
        className

      @container_id = ko.observable container_id
      @checked = ko.observable false
      return


  window.app = new dashboardViewModel
  ko.applyBindings window.app
