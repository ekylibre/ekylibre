#= require jquery

(($) ->
  "use strict"

  # Removes all nodes triggering event on them
  $.fn.deepRemove = (event) ->
    if event == null or event == undefined
      event = 'remove'
    @each ->
      element = $(this)
      allChildren = element.find('*')
      allChildren.detach()
      allChildren.trigger event
      allChildren.remove()
      element.detach()
      element.trigger event
      element.remove()
    $

  # Takes a GET-serialized string, e.g. first=5&second=3&a=b and sets input tags (e.g. input name="first") to their values (e.g. 5)
  $.unparam = (params) ->
    if params == null or params == undefined
      return {}
    # this small bit of unserializing borrowed from James Campbell's "JQuery Unserialize v1.0"
    params = params.split('&')
    unserializedParams = {}
    $.each params, ->
      properties = @split('=')
      if typeof properties[0] != 'undefined' and typeof properties[1] != 'undefined'
        unserializedParams[properties[0].replace(/\+/g, ' ')] = properties[1].replace(/\+/g, ' ')
      return
    unserializedParams

  # Build URL from base url and additional parameters
  $.buildURL = (url, params) ->
    tempArray = url.split('?')
    baseURL = tempArray[0]
    params = $.extend($.unparam(tempArray[1]), params)
    baseURL + '?' + $.param(params)

  return
) jQuery
