#= require bootstrap/modal

((E, G, $) ->

  $(document).ajaxSend (e, xhr, options) ->
    token = $('meta[name=\'csrf-token\']').attr('content')
    xhr.setRequestHeader 'X-CSRF-Token', token
    return


  class golumn
    constructor: (id) ->
      @id = id

      @selectedItemsIndex = {}

      @showAnimalDetailsModal = ko.observable false
      @animalDetailsModalOptions = ko.observable false

      @cancelAnimalDetails = () =>
        @animalDetailsModalOptions false
        @showAnimalDetailsModal false

      @groups = ko.observableArray []
      @containers = ko.observableArray []
      @animals = ko.observableArray []


      @enableDropZones = (state = false) =>
        ko.utils.arrayForEach @groups(), (group) =>
          group.droppable state
          ko.utils.arrayForEach group.containers(), (container) =>
            container.droppable state unless container.protect

      @toggleAnimalDetailsModal = (animal) =>
        @animalDetailsModalOptions animal
        @showAnimalDetailsModal true
        return

      @moveAnimals = (container, group) =>

        params = {}
        params['container'] = container.id() unless container is undefined

        # find if any group changed
        for id, item of @selectedItemsIndex
          if item.parent.parent.id != group.id and group isnt undefined
            params['group'] = group.id

        E.dialog.open @rebuildUrl(params),
          returns:
            success: (frame, data, status, request) =>
              Turbolinks.refresh

              frame.dialog "close"
              return

            invalid: (frame, data, status, request) ->
              frame.html request.responseText
              return

      # by default, build url to move animals
      @rebuildUrl = =>
        options = Array.from(arguments).shift()
        options['animals_ids'] ||= Object.keys(@selectedItemsIndex)
        base_url = options['base_url'] || $('a[data-target=animal_group_changing]').attr('href')
        delete options['base_url']

        "#{base_url}&#{$.param(options)}"

      @impactOnSelection = =>

        count = Object.keys(@selectedItemsIndex).length
        $el = $('.interventions-accessor').find('[data-toggle=dropdown]')

        $el.data('name', $el.html()) unless $el.data('name')

        # TODO: set icon or text to explain counting.
        $el.html("#{$el.data('name')} (#{count})")


      @resetSelectedItems = =>
        for id, item  of @selectedItemsIndex
          item.checked(false)

        @selectedItemsIndex = {}


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
        groups = ko.utils.arrayMap json_data, (jGroup) =>

          group = new G.Group(jGroup.id, jGroup.name, [])

          places = ko.utils.arrayMap jGroup.places, (jPlace) =>

            container = new G.Container(jPlace.id, jPlace.name, [], group)

            animals = ko.utils.arrayMap jPlace.animals, (animal) =>
              new G.Item(animal.id, animal.name, animal.picture_path, animal.status, animal.sex_text, animal.identification_number, container)

            container.items animals
            container

          group.containers places

        window.app.groups = ko.observableArray(groups)

        ko.applyBindings window.app

        return true

      error: (data) ->
        return false

    return

  $(document).on 'click', 'a[data-toggle=dialog]', (e) =>
    
    E.dialog.open app.rebuildUrl({base_url: e.currentTarget.getAttribute('href')}),
      returns:
        success: (frame, data, status, request) ->
          frame.dialog "close"
          return

        invalid: (frame, data, status, request) ->
          frame.html request.responseText
          return
    false


  $(document).ready ->
    # $("*[data-golumns]").mousewheel (event, delta) ->
    #   if $(this).prop("wheelable") != "false"
    #     @scrollLeft -= (delta * 30)
    #     event.preventDefault()


    $("*[data-golumns='animal']").each ->
      golumn_id = $(this).data("golumns")
      window.app = new golumn(golumn_id)
      window.loadData(golumn_id, $(this))

) ekylibre, golumn, jQuery
