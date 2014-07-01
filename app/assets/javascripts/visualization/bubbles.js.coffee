# Add sprockets directives below:
#

visualization.bubbles =
  compute: (layer, data) ->
    return false
    
    return true

  legend: (layer) ->
    html  = "<div class='leaflet-legend-item' id='legend-#{layer.name}'>"
    html += "</div>"
    return html
