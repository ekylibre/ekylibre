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

      @groups = ko.observableArray []
      @containers = ko.observableArray []
      @animals = ko.observableArray []

      @counter = ko.observable 0

      @keeper_id = undefined


      @enableDropZones = (state = false) =>
        ko.utils.arrayForEach @groups(), (group) =>
          group.droppable state
          ko.utils.arrayForEach group.containers(), (container) =>
            container.droppable state unless container.protect

      @moveAnimals = (container, group) =>

        params = {}
        params['new_container'] = container.id() unless container is undefined
        params['parameters'] = true

        # find if any group changed
        for id, item of @selectedItemsIndex
          if item.parent.parent.id != group.id and group isnt undefined
            params['new_group'] = group.id

        E.dialog.open @rebuildUrl(params),
          returns:
            success: (frame, data, status, request) =>
              Turbolinks.visit '#', action: 'replace'

              frame.dialog "close"
              return

            invalid: (frame, data, status, request) ->
              frame.html request.responseText
              return

      # by default, build url to move animals
      @rebuildUrl = =>

        options = Array.from(arguments).shift()

        base_url = options['base_url'] || $('a[data-target=animal_group_changing]').attr('href')
        parameters = options['parameters'] || false

        options = Array.from(arguments).shift()
        options['reference_name'] ||= 'animal'
        options['keeper_id'] = @keeper_id if Object.keys(@selectedItemsIndex).length and @keeper_id

        delete options['parameters']

        base_url += "&#{$.param(options)}" if parameters

        base_url

      @impactOnSelection = =>

        @counter Object.keys(@selectedItemsIndex).length

        $.post $('*[data-keep-animals-path]').first().data('keep-animals-path'), id: Object.keys(@selectedItemsIndex).join(',') , (data) =>
          @keeper_id = data.id if data.id? and data.id

        $.get $('*[data-matching-interventions-path]').first().data('matching-interventions-path'), id: Object.keys(@selectedItemsIndex).join(',')


      @resetSelectedItems = =>
        for id, item  of @selectedItemsIndex
          item.checked(false)


        $.post $('*[data-keep-animals-path]').first().data('keep-animals-path'), id: [], (data) =>
          @keeper_id = undefined if data.id?


        @selectedItemsIndex = {}


  @loadData = (golumn, scope, element) =>
    $.ajax '/backend/animals/load_animals',
      type: 'GET'
      dataType: 'JSON'
      data:
        golumn_id: golumn
        scope: scope
      beforeSend: () ->
        element.addClass("loading")
        return
      complete: () ->
        element.removeClass("loading")
        return
      success: (json_data) ->
        groups = ko.utils.arrayMap json_data.groups, (jGroup) =>

          group = new G.Group(jGroup.id, jGroup.name, jGroup.edit_path, [])

          group.containers ko.utils.arrayMap jGroup.places, (jPlace) =>

            container = new G.Container(jPlace.id, jPlace.name, [], group)

            container.items ko.utils.arrayMap jPlace.animals, (animal) =>
              new G.Item(animal.id, animal.name, animal.status, animal.sex, animal.show_path, container)

            container

          #items without place:
          if jGroup.without_place
            new_container = new G.Container(jGroup.without_place.id, jGroup.without_place.name, [], group)
            new_container.items ko.utils.arrayMap jGroup.without_place.animals, (animal) =>
              new G.Item(animal.id, animal.name, animal.status, animal.sex, animal.show_path, new_container)

            group.containers.push new_container

          group

        if json_data.without_group
          new_group = new G.Group(json_data.without_group.id, json_data.without_group.name, json_data.without_group.edit_path, [])

          #items without place:
          if json_data.without_group.without_place
            new_container = new G.Container(json_data.without_group.without_place.id, json_data.without_group.without_place.name, [], new_group)
            new_container.items ko.utils.arrayMap json_data.without_group.without_place.animals, (animal) =>
              new G.Item(animal.id, animal.name, animal.status, animal.sex, animal.show_path, new_container)

            new_group.containers.push new_container

            groups.push new_group

        window.app.groups = ko.observableArray(groups)

        ko.applyBindings window.app

        return true

      error: (data) ->
        return false

    return

  $(document).on 'click', 'a[data-toggle=dialog]', (e) =>

    dropdown = $(e.currentTarget).closest('.dropdown-menu').siblings('.dropdown-toggle')

    if dropdown?
      dropdown.dropdown('toggle')

    E.dialog.open app.rebuildUrl({base_url: e.currentTarget.getAttribute('href'), parameters: $(e.currentTarget).data('parameters'), reference_name: $(e.currentTarget).data('reference-name')}),
      returns:
        success: (frame, data, status, request) ->

          frame.dialog "close"

          if $(e.currentTarget).data('refresh')
            window.onLoad()

          return

        invalid: (frame, data, status, request) ->
          frame.html request.responseText
          return

    window.app.resetSelectedItems()

    false

  @onLoad = ->
    $("*[data-golumns='animal']").each ->
      golumn_id = $(this).data("golumns")
      ko.unapplyBindings($(document.body))

      scope = $('[data-scoped-items].active').data('scoped-items')

      window.app = new golumn(golumn_id)
      window.loadData(golumn_id, scope, $(this))

  $(document).on 'click', '[data-scoped-items]', (e) =>
    scope = $(e.currentTarget).data('scoped-items')

    $(e.currentTarget).data('scope', true)
    $('[data-toggle=item-scope]').removeClass('active')
    $(e.currentTarget).addClass('active')

    window.onLoad()
    e.preventDefault()


  $(document).ready ->
    # $("*[data-golumns]").mousewheel (event, delta) ->
    #   if $(this).prop("wheelable") != "false"
    #     @scrollLeft -= (delta * 30)
    #     event.preventDefault()

    window.onLoad()
    $('.golumn-columns').scroll () =>
      $('.golumn-items-counter').css('right', - $('.golumn-columns').scrollLeft() )


  ko.unapplyBindings = ($node, remove) =>
    $node.find('*').each () ->
      $(@).unbind()

    if remove
      ko.removeNode $node[0]
    else
      ko.cleanNode $node[0]

) ekylibre, golumn, jQuery
