(($) ->

  "use strict"

  class I18nExt

    isKeyExist: (key) ->
      return I18n.isSet(key)

    _getTranslation: (key) ->
      translation = I18n.translate(key)
      if ( Object.prototype.toString.call( translation ) == '[object Array]' )
        return this._cleanArray(translation)
      else
        return translation



    _getMonths: (key) ->
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
      return this._getMonths('date.month_names')

    getAbbrDayNames: ->
      return I18n.translate('date.abbr_day_names')

    getAbbrMonthNames: ->
      return this._getMonths('date.abbr_month_names')


  class DateFormat extends I18nExt

    getDefaultFormat: ->
      return I18n.translate('date.formats.default')

    getLegalFormat: ->
      return I18n.translate('date.formats.legal')

    getLongFormat: ->
      return I18n.translate('date.formats.long')



  I18nExt = new I18nExt()
  I18nExt.Dates = new Dates()
  I18nExt.DateFormat = new DateFormat()

  $.extend(I18n, I18nExt)

) jQuery
