((E, $) ->

  I18n.defaultLocale = $('html').data('lang-iso3')
  I18n.locale = I18n.defaultLocale
  I18n.rootKey = 'front-end'

) ekylibre, jQuery