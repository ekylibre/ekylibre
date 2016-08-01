#= require bootstrap/modal

((G, $) ->

  $(document).ajaxSend (e, xhr, options) ->
    token = $('meta[name=\'csrf-token\']').attr('content')
    xhr.setRequestHeader 'X-CSRF-Token', token
    return


  class golumn
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
        variantId: ko.observable ''


      @cancelAnimalDetails = () =>
        @animalDetailsModalOptions false
        @showAnimalDetailsModal false

      @cancelNewGroup = () =>
        @showNewGroupModal false

      @addContainer = =>
        newContainer = new golumn.Container(@newContainer().id, @newContainer().name, @containerModalOptions())
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
                 @animals.push new golumn.Animal(id, name, img, status, sex, num, @moveAnimalModalOptions.container().id, @moveAnimalModalOptions.group().id)


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
          @animals.push new golumn.Animal(id, name, img, status, sex, num, container, group)

        @showMoveAnimalModal false

        @resetAnimalsMoving()

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
        @production_support_list.removeAll()
        @workers_list.removeAll()
        @natures_list.removeAll()

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
            data: {name:group(),variant_id: @newGroupModalOptions.variantId()},
            success: (res) =>
              if res.id
                @groups.push new golumn.Group(res.id, res.name)

              @showNewGroupModal false
              return true

            error: (res) =>
              @showNewGroupModal false
              return false


  @loadData = (golumn, element) =>
    $.ajax '/backend/animals/load_animals',
      type: 'GET'
      dataType: 'JSON'
      data:
        golumn_id: golumn
      beforeSend: () ->
        element.addClass("loading")
        return
      complete: () ->
        element.removeClass("loading")
        return
      success: (json_data) ->
        ko.utils.arrayForEach json_data, (group) =>

          places = []
          ko.utils.arrayForEach group.places, (place) =>

            animals = []
            ko.utils.arrayForEach place.animals, (animal) =>
              animals.push new G.Item(animal.id, animal.name, animal.picture_path, animal.status, animal.sex_text, animal.identification_number)

            places.push new G.Container(place.id, place.name, animals)

          window.app.groups.push new G.Group(group.id, group.name, places)


        ko.applyBindings window.app

        return true

      error: (data) ->
        return false

    return


  $(document).ready ->
    # $("*[data-golumns]").mousewheel (event, delta) ->
    #   if $(this).prop("wheelable") != "false"
    #     @scrollLeft -= (delta * 30)
    #     event.preventDefault()


    $("*[data-golumns='animal']").each ->
      golumn_id = $(this).data("golumns")
      window.app = new golumn(golumn_id)
      window.loadData(golumn_id, $(this))

) golumn, jQuery
