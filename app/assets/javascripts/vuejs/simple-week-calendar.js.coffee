((E, $) ->
  'use strict'


  class SimpleWeekCalendar
    constructor: (selector, datas, createdCallback, methods) ->
      new Vue
        el: selector
        data: datas
        created: ->
          createdCallback(this)
        methods: methods


  E.SimpleWeekCalendar = SimpleWeekCalendar

) ekylibre, jQuery
