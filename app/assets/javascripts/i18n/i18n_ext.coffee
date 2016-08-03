((E, $) ->

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
      return this._getTranslation('date.day_names')

    getMonthNames: ->
      return this._getTranslation('date.month_names')

    getAbbrDayNames: ->
      return this._getTranslation('date.abbr_day_names')

    getAbbrMonthNames: ->
      return this._getTranslation('date.abbr_month_names')


  class DateFormat extends I18nExt

    getDefaultFormat: ->
      return this._getTranslation('date.formats.default')

    getLegalFormat: ->
      return this._getTranslation('date.formats.legal')

    getLongFormat: ->
      return this._getTranslation('date.formats.long')



  E.I18nExt = new I18nExt()
  E.I18nExt.Dates = new Dates()
  E.I18nExt.DateFormat = new DateFormat()

) ekylibre, jQuery
