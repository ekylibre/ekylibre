((E, $) ->
  'use strict'

  $(document).ready ->
    new Vue
      name: 'app'
      data:
        showDate: new Date()
      components: { CalendarView }


  class SimpleCalendar
    constructor: ->

  E.VueSimpleCalendar = SimpleCalendar

) ekylibre, jQuery
