# This module permits to execute actions on taskboard

((E, $) ->
  'use strict'

  class Taskboard

    constructor: (selector, fixHeader) ->
      @selector = selector
      @taskboard = $("#{selector}")
      @taskboardHeaders = $(@taskboard).find('.taskboard-header')
      @tasks = $(@taskboard).find('.tasks')
      @taskboardOffset = @taskboard.offset()

      if (fixHeader)
        this.addFixedHeaderEvent()

    getTaskboard: ->
      return @taskboard

    getTaskboardOffset: ->
      return @taskboardOffset

    getColumns: () ->
      return this.getTaskboard().find('.taskboard-column')

    getColumnIndex: (selector) ->
      return $(selector).closest('.taskboard-column').attr('data-column-index')

    getColumnByIndex: (index) ->
      return $(".taskboard-column[data-column-index=\"#{index}\"]")

    getHeaders: ->
      return @taskboardHeaders

    getHeaderByIndex: (index) ->
      return this.getColumnByIndex(index).find('.taskboard-header')

    getHeaderTitle: (selector) ->
      return $(selector).find('.title')

    getHeaderActions: ->
      return @taskboardHeaders.find('.actions')

    getHeaderAction: (headerAction) ->
      return $(headerAction).find('.actions')

    getHeaderIcons: (headerSelector) ->
      return this.getHeaderAction(headerSelector).find('.picto')

    hiddenHeaderIcons: (headerSelector) ->
      this.getHeaderIcons(headerSelector).addClass('picto--invisible');

    displayHeaderIcons: (headerSelector) ->
      this.getHeaderIcons(headerSelector).removeClass('picto--invisible');

    getTasksBlocks: ->
      return @tasks

    getTasks: ->
      return this.getTasksBlocks().find('.task')

    getSelectFieldsTasks: ->
      return this.getTasks().find('.task-select-field')

    getTaskSelectField: (taskSelector) ->
      return $(taskSelector).find('.task-select-field')


    getCheckedSelectedFields: (selector) ->
      return $(selector).closest('.tasks').find('.task-select-field input[type="checkbox"]:checked')

    getCheckedSelectFieldsCount: (selector) ->
      return this.getCheckedSelectedFields(selector).length

    getCheckedTasks: (selector) ->
      return this.getCheckedSelectedFields(selector).closest('.task')

    getTasksByIndex: (index) ->
      return this.getColumnByIndex(index).find('.tasks')

    getSelectedTasksByColumnSelector: (selector) ->
      columnIndex = this.getColumnIndex(selector)
      columnTasks = this.getTasksByIndex(columnIndex)

      return this.getCheckedTasks(columnTasks)

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

      $('#content').scroll( ->

        scroll = $('#content').scrollTop()

        if (scroll >= taskboardTopOffset)
          instance.getHeaders().addClass('taskboard-header--fixed')
          instance.getHeaders().css('top', $('#content').offset().top)
          instance.getHeaders().css('width', instance.getColumns().outerWidth())
        else
          instance.getHeaders().removeClass('taskboard-header--fixed')
          instance.getHeaders().css('top', 'initial')
          instance.getHeaders().css('width', 'initial')
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
