#= require twitter/typeahead
#= require formize/behave

(($) ->

  $.loadTypeahead = ->
    element = $(this)
    wrapper = element.closest('.twitter-typeahead')
    if wrapper.length <= 0
      completer = new Bloodhound
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value')
        queryTokenizer: Bloodhound.tokenizers.whitespace
        # prefetch: element.data('autocomplete')
        remote:
          url: element.data('autocomplete') + "?q=%QUERY"
          wildcard: '%QUERY'
      element.typeahead null,
        source: completer,
        limit: 10
      element.attr('typeaheadloaded', 'yes')
    return

  $(document).ready ->
    $("input[data-autocomplete]").each ->
      $.loadTypeahead.call(this)

  $(document).on "page:load cocoon:after-insert dialog:show", ->
    $("input[data-autocomplete]").each ->
      $.loadTypeahead.call(this)

  return
) jQuery
