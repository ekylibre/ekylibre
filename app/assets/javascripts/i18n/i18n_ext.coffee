(($) ->

  "use strict"

  class I18nExt

    ###
        Method for get the values of the months when the first value is blank.
    ###
    _sliceMonthList: (key) ->
        translation = I18n.translate(key)
        if ( Object.prototype.toString.call( translation ) == '[object Array]' )
          return translation[1..12]

    ###
        Remove list element if element has his value equal to :
         - null
         - undefined
         - NaN
         - empty string
         - 0
         - false
    ###
    _cleanArray: (list) ->
      return list.filter (n) ->
        if (n)
          return true
        else
          return false


  class Dates extends I18nExt

    getDayNames: ->
      return I18n.translate('date.day_names')

    getMonthNames: ->
      return this._sliceMonthList('date.month_names')

    getAbbrDayNames: ->
      return I18n.translate('date.abbr_day_names')

    getAbbrMonthNames: ->
      return this._sliceMonthList('date.abbr_month_names')

    getOrder: ->
      return I18n.translate('date.order')


  class DateFormat extends I18nExt

    default: ->
      return I18n.translate('date.formats.default')

    legal: ->
      return I18n.translate('date.formats.legal')

    short: ->
      return I18n.translate('date.formats.short')

    long: ->
      return I18n.translate('date.formats.long')

    month: ->
      return I18n.translate('date.formats.month')

    monthLetter: ->
      return I18n.translate('date.formats.month_letter')


  class Datetime extends I18nExt

    am: ->
      return I18n.translate('time.am')

    pm: ->
      return I18n.translate('time.pm')

    periods: ->
      return [this.am(), this.pm()]



  class DatetimeFormat extends I18nExt

    default: ->
      return I18n.translate('time.formats.default')

    long: ->
      return I18n.translate('time.formats.long')

    short: ->
      return I18n.translate('time.formats.short')

    time: ->
      return I18n.translate('time.formats.time')



  I18nExt.ext = new I18nExt()
  I18nExt.ext.dates = new Dates()
  I18nExt.ext.dateFormat = new DateFormat()
  I18nExt.ext.datetime = new Datetime()
  I18nExt.ext.datetimeFormat = new DatetimeFormat()

  $.extend(I18n, I18nExt)

) jQuery
