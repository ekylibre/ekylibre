# Apache ECharts glue for Ekylibre.
#
# This file is the replacement for chart/highcharts. It exposes:
#   - $.widget "ui.echart"     : jQuery UI widget that reads `data-echarts`
#                                from a DOM node and instantiates an ECharts
#                                chart on it.
#   - $.loadECharts()          : initializes all unloaded `[data-echarts]`
#                                elements in the current document.
#   - $.echartFor(selector)    : returns the ECharts instance bound to the
#                                first matching element (or null). Used by
#                                plugins (e.g. ekylibre-economic) to mutate
#                                a chart's options at runtime.
#
# The Ruby helper (`ChartsHelper`) emits ECharts-shaped JSON in the
# `data-echarts` attribute. A custom `__drilldown` key inside that JSON
# (optional) carries Highcharts-style drilldown series; the widget wires
# them as click handlers + setOption swaps.
#
#= require jquery
#= require jquery_ujs
#= require echarts/dist/echarts.min

(($) ->
  "use strict"

  instances = new WeakMap()

  DEFAULT_TEXT_STYLE =
    fontFamily: "\"Open Sans\", \"Droid Sans\", \"Liberation Sans\", Helvetica, sans-serif"
    fontSize: 13

  DEFAULT_DECIMALS = 2

  # Format a number with `decimals` digits after the decimal mark.
  # French-style separators (space for thousands, comma for decimals)
  # match the rest of the Ekylibre UI. Non-numbers pass through as-is.
  formatNumber = (value, decimals = DEFAULT_DECIMALS) ->
    return value unless typeof value is "number" and isFinite(value)
    sign = if value < 0 then "-" else ""
    abs = Math.abs(value).toFixed(decimals)
    [intPart, decPart] = abs.split(".")
    intFmt = intPart.replace(/\B(?=(\d{3})+(?!\d))/g, " ")
    if decPart? then "#{sign}#{intFmt},#{decPart}" else "#{sign}#{intFmt}"

  # Walk the options tree and turn strings shaped like "function(...) { ... }"
  # into real functions. JSON cannot carry callables, so the Ruby helper
  # serialises them as strings (e.g. bubble's symbolSize) and we revive
  # them here.
  reviveFunctions = (node) ->
    return node unless node?
    if typeof node is "string" and /^\s*function\s*\(/.test(node)
      try
        return new Function("return (#{node})")()
      catch
        return node
    if Array.isArray(node)
      for v, i in node
        node[i] = reviveFunctions(v)
      return node
    if typeof node is "object"
      for own k, v of node
        node[k] = reviveFunctions(v)
      return node
    node

  # Substitute Highcharts/ECharts placeholders in a template string
  # using formatted values. Supports {c}, {b}, {a} — the placeholders
  # the Ruby helper produces via convert_point_format.
  substituteTemplate = (tpl, params) ->
    p = if Array.isArray(params) then params[0] else params
    return tpl unless p?
    value = p.value
    name = p.name or ""
    seriesName = p.seriesName or ""
    formattedValue = formatNumber(value, DEFAULT_DECIMALS)
    tpl
      .replace(/\{c\}/g, formattedValue)
      .replace(/\{b\}/g, name)
      .replace(/\{a\}/g, seriesName)

  # Build a tooltip/label callback from a template string. This wrapper
  # is needed because ECharts' tooltip.valueFormatter is ignored when a
  # tooltip.formatter (even a string template) is set — values would
  # otherwise be substituted raw, with 8-decimal floats.
  buildTemplateFormatter = (tpl) ->
    (params) -> substituteTemplate(tpl, params)

  # Add a small toolbox in the top-right corner of every chart, with a
  # single feature: save-as-image (PNG). Mirrors the Highcharts "export
  # menu" affordance users had before. Callers can opt out or extend
  # by setting their own `toolbox` option.
  applyDefaultToolbox = (opts) ->
    return if opts.toolbox?
    label = "Télécharger l'image"
    try
      if window.I18n?.t?
        label = window.I18n.t("front-end.echarts.save_as_image") or label
    opts.toolbox =
      show: true
      right: 10
      top: 6
      itemSize: 14
      itemGap: 8
      feature:
        saveAsImage:
          show: true
          title: label
          name: "chart"
          pixelRatio: 2
          backgroundColor: "#ffffff"
    return

  # Series whose name starts with "__" are considered internal helpers
  # (e.g. waterfall connector lines). They must render on the chart but
  # never appear in the legend.
  hideInternalSeriesFromLegend = (opts) ->
    return unless Array.isArray(opts.series)
    visible = opts.series
      .filter (s) -> s?.name? and not /^__/.test(s.name)
      .map (s) -> s.name
    if opts.legend
      opts.legend.data ||= visible
    return

  # Apply sensible default formatters so charts don't render raw
  # 8-decimal floating point garbage. When the caller supplies a string
  # template via tooltip.formatter / series.label.formatter, we wrap it
  # in a callback that does substitution AND number formatting.
  applyDefaultFormatters = (opts) ->
    opts.tooltip ||= { show: true }
    fmt = opts.tooltip.formatter
    if typeof fmt is "string"
      opts.tooltip.formatter = buildTemplateFormatter(fmt)
    else if not fmt? and not opts.tooltip.valueFormatter?
      opts.tooltip.valueFormatter = (value) -> formatNumber(value, DEFAULT_DECIMALS)

    # yAxis is the value axis in most cases; xAxis carries values only
    # when the chart is a bar chart (we don't try to detect that here —
    # the helper sets sane axis types). Format integers (no decimals) on
    # axis ticks to keep them readable on dense plots.
    for axisKey in ["yAxis", "xAxis"]
      axes = opts[axisKey]
      continue unless axes
      axes = [axes] unless Array.isArray(axes)
      for ax in axes
        continue unless ax and ax.type is "value"
        ax.axisLabel ||= {}
        ax.axisLabel.formatter ||= (value) -> formatNumber(value, 0)

    if Array.isArray(opts.series)
      for s in opts.series
        continue unless s?.label?.show
        lf = s.label.formatter
        if typeof lf is "string"
          s.label.formatter = buildTemplateFormatter(lf)
        else if not lf?
          s.label.formatter = (params) ->
            v = if params? and "value" of params then params.value else params
            formatNumber(v, DEFAULT_DECIMALS)

    return

  installDrilldown = (chart, spec, baseOption) ->
    # spec: { series: { <id>: [{name, data, type, ...}] } }
    return unless spec? and spec.series?
    seriesById = spec.series

    chart.on "click", (params) ->
      pt = params?.data
      return unless pt? and typeof pt is "object"
      id = pt.drilldown
      return unless id and seriesById[id]
      drillSeries = seriesById[id]
      drillSeries = [drillSeries] unless Array.isArray(drillSeries)
      newSeries = drillSeries.map (s) ->
        $.extend(true, {}, s, { type: s.type or "bar" })
      chart.setOption({ series: newSeries }, true, true)
      showBackButton(chart, baseOption)

    return

  showBackButton = (chart, baseOption) ->
    dom = chart.getDom()
    $dom = $(dom)
    return if $dom.find(".echart-drilldown-back").length > 0
    $btn = $("<button type='button' class='echart-drilldown-back'>‹ Retour</button>")
    $btn.css
      position: "absolute"
      top: "8px"
      right: "8px"
      "z-index": 10
    $btn.on "click", ->
      chart.setOption(baseOption, true, true)
      $btn.remove()
    # Make sure container is positioned so the button anchors correctly.
    if $dom.css("position") is "static"
      $dom.css("position", "relative")
    $dom.append($btn)
    return

  $.widget "ui.echart",
    options: {}

    _create: ->
      raw = @element.data("echarts") or {}
      opts = $.extend(true, {}, @options, raw)
      drilldownSpec = opts.__drilldown
      delete opts.__drilldown if drilldownSpec?

      # Apply default text style if the option does not carry one.
      opts.textStyle = $.extend(true, {}, DEFAULT_TEXT_STYLE, opts.textStyle or {})

      reviveFunctions(opts)
      hideInternalSeriesFromLegend(opts)
      applyDefaultToolbox(opts)
      applyDefaultFormatters(opts)

      @chart = echarts.init(@element[0])
      @chart.setOption(opts)
      instances.set(@element[0], @chart)

      if drilldownSpec?
        installDrilldown(@chart, drilldownSpec, opts)

      @_resizeHandler = => @chart?.resize()
      $(window).on "resize.echart-#{@uuid}", @_resizeHandler
      @element.on "cell:load.echart-#{@uuid}", @_resizeHandler

    _destroy: ->
      $(window).off "resize.echart-#{@uuid}"
      @element.off "cell:load.echart-#{@uuid}"
      instances.delete(@element[0])
      @chart?.dispose()

    uuid: -> @element[0].__echartUuid ||= (Math.random().toString(36).slice(2))

  $.loadECharts = ->
    $("[data-echarts]:not(.echart-loaded)").each ->
      $(this).addClass("echart-loaded").echart()
    return

  $.echartFor = (selector) ->
    el = $(selector)[0]
    return null unless el
    instances.get(el)

  $(document).on "turbolinks:load cocoon:after-insert cell:load", $.loadECharts

) jQuery
