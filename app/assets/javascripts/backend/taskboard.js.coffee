# This module permits to execute actions on taskboard

((E, $) ->
  'use strict'

  class Taskboard

    constructor: (selector, fixHeader) ->
      @selector = selector
      @taskboard = $("#{selector}")
      @taskboardHeaders = $(@taskboard).find('.headers')
      @taskboardLines = $(@taskboard).find('.lines')
      @taskboardOffset = @taskboard.offset()

      if (fixHeader)
        this.addFixedHeaderEvent()

    getTaskboard: ->
      return @taskboard

    getTaskboardOffset: ->
      return @taskboardOffset


    getHeaders: ->
      return @taskboardHeaders

    getHeaderByIndex: (index) ->
      return this.getHeaders().find(".taskboard-header[data-column-index=\"#{index}\"]")

    getHeaderTitle: (selector) ->
      return $(selector).find('.column-title')

    getHeaderActions: ->
      return @taskboardHeaders.find('.column-actions')

    getHeaderAction: (headerAction) ->
      return $(headerAction).find('.column-actions')

    getHeaderIcons: (headerSelector) ->
      return this.getHeaderAction(headerSelector).find('.picto')

    hiddenHeaderIcons: (headerSelector) ->
      this.getHeaderIcons(headerSelector).addClass('picto--invisible');

    displayHeaderIcons: (headerSelector) ->
      this.getHeaderIcons(headerSelector).removeClass('picto--invisible');


    getLines: ->
      return @taskboardLines


    getTasksBlocks: ->
      return this.getLines().find('.tasks')

    getTasks: ->
      return this.getLines().find('.task')

    getSelectFieldsTasks: ->
      return this.getTasks().find('.task-select-field')

    getTaskSelectField: (taskSelector) ->
      return $(taskSelector).find('.task-select-field')


    getCheckedSelectFieldsCount: (selector) ->
      return $(selector).closest('.tasks').find('.task-select-field input[type="checkbox"]:checked').length

    getTaskColumnIndex: (selector) ->
      return $(selector).closest('.tasks').attr('data-column-index')

    getTaskColors: (taskSelector) ->
      return $(taskSelector).find('.task-colors')

    getTaskTexts: (taskSelector) ->
      return $(taskSelector).find('.task-text')

    getTaskDatas: (taskSelector) ->
      return $(taskSelector).find('.task-datas')

    getTaskActions: (taskSelector) ->
      return $(taskSelector).find('.task-actions')



    addFixedHeaderEvent: ->
      taskboardTopOffset = this.getTaskboardOffset().top

      instance = this

      $("#content").scroll( ->

        scroll = $('#content').scrollTop()

        if (scroll >= taskboardTopOffset)
          instance.getHeaders().addClass('headers--fixed')
          instance.getHeaders().css('top', $('#content').offset().top)
          instance.getHeaders().css('width', instance.getTaskboard().css('width'))
        else
          instance.getHeaders().removeClass('headers--fixed')

      )

    addTaskClickEvent: (callback) ->
      this.getTasks().on('click', (event) ->
        callback(event)
      )

    addSelectTaskEvent: (callback) ->
      this.getSelectFieldsTasks().find('input[type="checkbox"]').on('change', (event) ->
        callback(event)
      )


  E.taskboard = Taskboard

) ekylibre, jQuery
