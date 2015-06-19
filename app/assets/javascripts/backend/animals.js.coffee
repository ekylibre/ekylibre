#= require bootstrap/modal

(($) ->

  $(document).ajaxSend (e, xhr, options) ->
    token = $('meta[name=\'csrf-token\']').attr('content')
    xhr.setRequestHeader 'X-CSRF-Token', token
    return

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
    constructor: (id) ->
      @id = id

      @showAnimalDetailsModal = ko.observable false
      @showNewContainerModal = ko.observable false
      @showMoveAnimalModal = ko.observable false
      @showNewGroupModal = ko.observable false

      @animalDetailsModalOptions = ko.observable false
      @containerModalOptions = ko.observable false

      @newContainer = ko.observable ''

      @moveAnimalModalOptions =
        animals: ko.observableArray []
        started_at: ko.observable ''
        stopped_at: ko.observable ''
        worker: ko.observable undefined
        variant: ko.observable undefined
        production_support: ko.observable undefined
        group: ko.observable undefined
        container: ko.observable undefined
        alert: ko.observable false
        checkNature: ko.observable false

      @moveAnimalModalOptions.checkNature.subscribe (value) =>
        if value != 1
          @moveAnimalModalOptions.variant undefined

      @newGroupModalOptions =
        group: ko.observable ''


      @cancelAnimalDetails = () =>
        @animalDetailsModalOptions false
        @showAnimalDetailsModal false

      @cancelNewGroup = () =>
        @showNewGroupModal false

      @addContainer = =>
        newContainer = new dashboardViewModel.Container(@newContainer().id, @newContainer().name, @containerModalOptions())
        @containers.push newContainer

        if @droppedAnimals().length > 0
          #Send animals by values instead of observableArray reference
          animals = []
          ko.utils.arrayForEach @droppedAnimals(), (a) =>
            animals.push a

          @toggleMoveAnimalModal(animals,newContainer);



        @resetContainerAdding()


      @containers_list = ko.observableArray []
      @workers_list = ko.observableArray []
      @natures_list = ko.observableArray []
      @production_support_list = ko.observableArray []


      @groups = ko.observableArray []
      @containers = ko.observableArray []
      @animals = ko.observableArray []


      @drop = ko.observable
      @hoverdrop = ko.observable
      @droppedAnimals = ko.observableArray []




      @displayedContainers = (group) =>

        c = ko.utils.arrayFilter @containers(), (c) =>
          c.group_id() == group.id

        return @sortContainerByPosition c


      @sortContainerByPosition = (containers) =>
        containers.sort (a,b) =>
          if a.position() == b.position()
            res = 0
          else if a.position() < b.position()
            res = -1
          else
            res = 1
          return res

      @toggleAnimalDetailsModal = (animal) =>
        @animalDetailsModalOptions animal
        @showAnimalDetailsModal true
        return

      @toggleNewGroupModal = () =>
        @showNewGroupModal true
        return

      @toggleNewContainerModal = (group) =>
        @containerModalOptions group.id
        @showNewContainerModal true
        #Be sure only one modal is displayed
        @showMoveAnimalModal false
        $.ajax '/backend/animals/load_containers',
          type: 'GET',
          dataType: 'JSON',
          success: (json_data) ->
            ko.utils.arrayForEach json_data, (j) =>
              window.app.containers_list.push j
            return true

      @toggleMoveAnimalModal = (animals, container) =>
        @moveAnimalModalOptions.animals animals
        @moveAnimalModalOptions.container container
        group = ko.utils.arrayFirst @groups(), (g) =>
          g.id == container.group_id()
        @moveAnimalModalOptions.group group

        @showMoveAnimalModal true
        $.ajax '/backend/animals/load_workers',
          type: 'GET',
          dataType: 'JSON',
          success: (json_data) ->
            ko.utils.arrayForEach json_data, (j) =>
              window.app.workers_list.push j
            return true

        $.ajax '/backend/animals/load_natures',
          type: 'GET',
          dataType: 'JSON',
          success: (json_data) ->
            ko.utils.arrayForEach json_data, (j) =>
              window.app.natures_list.push j
            return true

        $.ajax '/backend/animals/load_production_supports',
          type: 'GET',
          dataType: 'JSON',
          data: {group_id: group.id},
          success: (json_data) ->
            ko.utils.arrayForEach json_data, (j) =>
              window.app.production_support_list.push j
            return true

      @moveContainer = (container, sourceGroup, sourceIndex, targetGroup, targetIndex) =>
        #Allow to update multiple containers
        offset = container.length || 1

        #update target group
        container.group_id targetGroup.id
        container.position targetIndex

        supContainers = ko.utils.arrayFilter @containers(), (c) =>
          c.group_id() == targetGroup.id and c.position() > targetIndex and c.id != container.id

        ko.utils.arrayForEach supContainers, (f) =>
          f.position f.position()+offset

        infContainers = ko.utils.arrayFilter @containers(), (c) =>
          c.group_id() == targetGroup.id and c.position() <= targetIndex and c.id != container.id

        ko.utils.arrayForEach infContainers, (f) =>
          f.position f.position()-offset

        if sourceGroup != targetGroup
          #two swaps, we need to reorganize source group without removed container and change the owner group

          supContainers = ko.utils.arrayFilter @containers(), (c) =>
            c.group_id() == sourceGroup.id and c.position() > sourceIndex and c.id != container.id

          ko.utils.arrayForEach supContainers, (f) =>
            f.position f.position()-offset

        #update preferences
        @updatePreferences();


      @moveAnimals = () =>

        animals_id = ko.utils.arrayMap @moveAnimalModalOptions.animals(), (a) =>
          return a.id

#        if animals_id.length > 0 and @moveAnimalModalOptions.container() != undefined and @moveAnimalModalOptions.group() != undefined and @moveAnimalModalOptions.worker() != undefined and @moveAnimalModalOptions.started_at() != '' and @moveAnimalModalOptions.stopped_at() != '' and @moveAnimalModalOptions.production_support() != undefined
        if animals_id.length > 0 and @moveAnimalModalOptions.container() != undefined and @moveAnimalModalOptions.group() != undefined and @moveAnimalModalOptions.worker() != undefined and @moveAnimalModalOptions.started_at() != '' and @moveAnimalModalOptions.stopped_at() != ''

          data =
            animals_id: animals_id.join(',')
            container_id: @moveAnimalModalOptions.container().id
            worker_id: @moveAnimalModalOptions.worker().id
            started_at: @moveAnimalModalOptions.started_at()
            stopped_at: @moveAnimalModalOptions.stopped_at()

          if @moveAnimalModalOptions.group().id != @moveAnimalModalOptions.animals()[0].group_id()
            data['group_id'] = @moveAnimalModalOptions.group().id

          if @moveAnimalModalOptions.variant()
             data['variant_id'] =  @moveAnimalModalOptions.variant().id

          if @moveAnimalModalOptions.production_support()
            data['production_support_id'] = @moveAnimalModalOptions.production_support().id

          $.ajax '/backend/animals/change',
            type: 'PUT',
  #          type: 'GET',
            dataType: 'JSON',
            data: data,
            success: (res) =>
              @showMoveAnimalModal false

              # maj
              ko.utils.arrayForEach @moveAnimalModalOptions.animals(), (a) =>
                 id = a.id
                 name = a.name
                 img = a.img
                 status = a.status
                 sex = a.sex
                 num = a.number_id
                 @animals.remove a
                 @animals.push new dashboardViewModel.Animal(id, name, img, status, sex, num, @moveAnimalModalOptions.container().id, @moveAnimalModalOptions.group().id)


              @resetAnimalsMoving()


              return true

            error: (res) =>
              @showMoveAnimalModal false
              alert res.statusText
              @cancelAnimalsMoving()
              return false
        else
          @moveAnimalModalOptions.alert true

      @cancelAnimalsMoving = () =>

        ko.utils.arrayForEach @moveAnimalModalOptions.animals(), (a) =>
          id = a.id
          name = a.name
          img = a.img
          status = a.status
          sex = a.sex
          num = a.number_id
          container = a.container_id()
          group = a.group_id()
          @animals.remove a
          @animals.push new dashboardViewModel.Animal(id, name, img, status, sex, num, container, group)

        @showMoveAnimalModal false

        @resetAnimalsMoving

      @resetAnimalsMoving = () =>
        @moveAnimalModalOptions.animals.removeAll()

        @moveAnimalModalOptions.container undefined
        @moveAnimalModalOptions.started_at ''
        @moveAnimalModalOptions.stopped_at ''
        @moveAnimalModalOptions.worker undefined
        @moveAnimalModalOptions.variant undefined
        @moveAnimalModalOptions.group undefined
        @moveAnimalModalOptions.alert false
        @moveAnimalModalOptions.checkNature false

      @cancelContainerAdding = () =>
        @resetContainerAdding()


      @resetContainerAdding = () =>
        @newContainer = ko.observable false
        @containerModalOptions = ko.observable false
        @containers_list.removeAll()
        @showNewContainerModal false
        @droppedAnimals.removeAll()

      @updatePreferences = () =>

        data = []

        ko.utils.arrayForEach @groups(), (g) =>
          group = {id: g.id, containers: []}
          curContainers = ko.utils.arrayFilter @containers(), (c) =>
            c.group_id() == g.id

          containers = ko.utils.arrayMap curContainers, (c) =>
            {id: c.id, position: c.position()}

          containers = containers.sort (a,b)->
            if a.position > b.position
              return 1
            else
              return -1

          ko.utils.arrayForEach containers, (item) ->
            group.containers.push item.id
          data.push group

        $.ajax
          url: "/backend/golumns/#{@id}"
          type: 'PATCH'
          data:
            positions: data

      @showAddGroup = (item) =>
        return item() == @groups().length-1

      @addGroup = () =>
        if group = @newGroupModalOptions.group

          $.ajax '/backend/animals/add_group',
            type: 'PUT',
#            type: 'GET',
            dataType: 'JSON',
            data: {name:group()},
            success: (res) =>
              if res.id
                @groups.push new dashboardViewModel.Group(res.id, res.name)

              @showNewGroupModal false
              return true

            error: (res) =>
              @showNewGroupModal false
              return false


    @Group: (id, name) ->
      @id = id
      @name = name
      @toggleItems = ko.observable false
      @toggleItems.subscribe (newValue) =>

        container_array = ko.utils.arrayFilter window.app.containers(), (c) =>
          c.group_id() == @id

        ko.utils.arrayForEach container_array, (c) =>
          ko.utils.arrayForEach window.app.animals(), (a) =>
            if a.container_id() == c.id and a.group_id() == @id
              a.checked newValue

      return

    @Container: (id, name, group_id) ->
      @id = id
      @name = name
      @group_id = ko.observable group_id

      @animalCount = ko.pureComputed () =>
        array = ko.utils.arrayFilter window.app.animals(), (a) =>
          a.container_id() == @id && a.group_id() == @group_id()

        array.length

      @hidden = ko.observable false
      @toggle = () =>
        @hidden(!@hidden())
        return

      @position = ko.observable 0
      return

    @Animal: (id, name, img, status, sex, number_id, container_id, group_id) ->
      @id = id
      @name = name
      @img = ko.pureComputed () =>
        img
      @status = status
      @sex = sex
      @animalSexClass = ko.pureComputed () =>
        #TODO get sex key from backend instead of human name
        if @sex == 'Mâle'
          className = "icon-mars"
        if @sex == 'Femelle'
          className = "icon-venus"
        className
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
      @group_id = ko.observable group_id
      @checked = ko.observable false

      return

  @loadData = (golumn) =>
    $.ajax '/backend/animals/load_animals',
      type: 'GET',
      dataType: 'JSON',
      data: {golumn_id: golumn},
      beforeSend: () ->
        $('#loading').show()
        return
      complete: () ->
        $('#loading').hide()
        return
      success: (json_data) ->
        ko.utils.arrayForEach json_data, (j) =>
          if j.group
            window.app.groups.push new dashboardViewModel.Group(j.group.id, j.group.name)
          if j.places_and_animals and j.places_and_animals.length > 0
            ko.utils.arrayForEach j.places_and_animals, (container) =>
              if container.place
                window.app.containers.push new dashboardViewModel.Container(container.place.id, container.place.name, j.group.id)
              if container.animals
                ko.utils.arrayForEach $.parseJSON(container.animals), (animal) =>
                  window.app.animals.push new dashboardViewModel.Animal(animal.id, animal.name, '', animal.status, animal.sex_text, animal.identification_number, container.place.id, j.group.id)

          if j.others

            window.app.groups.push new dashboardViewModel.Group(0, 'A classer')
            window.app.containers.push new dashboardViewModel.Container(0, 'A classer', 0) #305 = vaches laitières

            ko.utils.arrayForEach j.others, (other) =>
              if other.animal
                animal = $.parseJSON(other.animal)
                window.app.animals.push new dashboardViewModel.Animal(animal.id, animal.name, '', animal.status, animal.sex_text, animal.identification_number, 0, 0)


        ko.applyBindings window.app

        return true

      error: (data) ->
        return false

    return


  $(document).ready ->
    $("*[data-golumns='animal']").each ->

      golumn_id = $(this).data("golumns")
      window.app = new dashboardViewModel(golumn_id)

      window.loadData(golumn_id)

) jQuery
