# Add sprockets directives below:
#

visualization.choropleth =

  compute: (layer, data) ->
    property = layer.reference
    choropleth = layer.choropleth
    choropleth.maxValue = data[0][property]
    choropleth.minValue = data[0][property]
    choropleth.grades   = []
    $.each data, (index, zone) ->
      if zone[property] > choropleth.maxValue
        choropleth.maxValue = zone[property]
      if zone[property] < choropleth.minValue
        choropleth.minValue = zone[property]

    console.log "Exact min (#{choropleth.minValue}) and max (#{choropleth.maxValue}) computed"

    # Simplify values
    maxMagnitude = Math.magnitude(choropleth.maxValue)
    minMagnitude = Math.magnitude(choropleth.minValue)
    ref = minMagnitude
    if maxMagnitude.power > minMagnitude.power
      ref = maxMagnitude
    choropleth.power = ref.power
    mag = ref.magnitude
    mag = mag / 10 if mag >= 100
    choropleth.maxValue = Math.ceil2(choropleth.maxValue,  mag * choropleth.round)
    choropleth.minValue = Math.floor2(choropleth.minValue, mag * choropleth.round)
    choropleth.length = choropleth.maxValue - choropleth.minValue

    if choropleth.length == 0
      console.log "Length is null"
      return false
    
    if choropleth.levelNumber > choropleth.length and choropleth.length > 2
      choropleth.levelNumber = choropleth.length

    console.log "Min (#{choropleth.minValue}) and max (#{choropleth.maxValue}) computed"

    start = new visualization.Color(choropleth.startColor)
    stop  = new visualization.Color(choropleth.stopColor)
    
    for g in [1..choropleth.levelNumber]
      level = (g - 1.0) / (choropleth.levelNumber - 1.0)
      grade = 
        color: visualization.Color.toString
          red:   start.red   + (Math.round(stop.red   - start.red)   * level)
          green: start.green + (Math.round(stop.green - start.green) * level)       
          blue:  start.blue  + (Math.round(stop.blue  - start.blue)  * level)
        min: choropleth.minValue + (g-1) * choropleth.length / choropleth.levelNumber
        max: choropleth.minValue +  g    * choropleth.length / choropleth.levelNumber
      grade.minLabel = Math.humanize(grade.min, choropleth.power)
      grade.maxLabel = Math.humanize(grade.max, choropleth.power)
      choropleth.grades.push grade
    console.log "Grades computed"
        
    $.each data, (index, zone) ->
      level = Math.round(choropleth.levelNumber * (zone[property] - choropleth.minValue) / choropleth.length)
      level = choropleth.levelNumber - 1 if level >= choropleth.levelNumber
      level = 0 if level < 0 or isNaN(level)
      zone.fillColor = choropleth.grades[level].color
      
    console.log "Choropleth computed"
    true

  # Build HTML legend for given choropleth computed layer
  legend: (layer) ->
    html  = "<div class='leaflet-legend-item' id='legend-#{layer.name}'>"
    html += "<h3>#{layer.label}</h3>"
    html += "<div class='leaflet-legend-body leaflet-choropleth-scale'>"
    html += "<span class='min-value'>#{layer.choropleth.grades[0].minLabel}</span>"
    html += "<span class='max-value'>#{layer.choropleth.grades[layer.choropleth.levelNumber - 1].maxLabel}</span>"
    html += "<span class='leaflet-choropleth-grades'>"
    $.each layer.choropleth.grades, (index, grade) ->               
      html += "<i class='leaflet-choropleth-grade' style='width: #{100 / layer.choropleth.levelNumber}%; background-color: #{grade.color}' title='#{grade.minLabel} ~ #{grade.maxLabel}'></i>"
    html += "</span>"
    html += "</div>"
    html += "</div>"
    return html
   
