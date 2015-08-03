#= require d3
#= require c3
#

((C, $) ->
  "use strict"

  C.adapters.c3 =
    # Generate chart
    render: (element, options) ->
      console.log options
      unless options.type in ["linear", "time"]
        console.error "C3 does not support this chart type: #{options.type}"
        return null
      params =
        bindto: element.get(0)
        data: {}
        types: {}
      C.adapters.c3.loadAbscissa(options.abscissa, params)
      C.adapters.c3.loadOrdinates(options.ordinates, params)
      C.adapters.c3.series[options.type].load(options.series, params)
      console.log params
      return c3.generate(params)


    # Generates abscissa parameters for C3.js
    loadAbscissa: (abscissa, params) ->
      return unless abscissa?
      x = {}
      if abscissa.label?
        x.label = abscissa.label
      if abscissa.values?
        x.type = "categories"
        x.categories = abscissa.values
      unless $.isEmptyObject x
        params.axis ?= {}
        params.axis.x = x

    # Generates ordinates parameters for C3.js
    loadOrdinates: (ordinates, params) ->
      return unless ordinates?
      unless $.isArray(ordinates)
        ordinates = [ordinates]
      for ordinate, index in ordinates
        y_name = "y"
        if index > 1
          console.warn "C3 engine cannot render more than 2 ordinate axes"
          break
        else if index > 0
          y_name = "#{y_name}#{index}"
        y = {}
        if ordinate.label?
          y.label = ordinate.label
        y.default = [-10, 90]
        unless $.isEmptyObject y
          params.axis ?= {}
          params.axis[y_name] = y

    series:
      _loadType: (serie, params) ->
        return unless serie.type?
        unless serie.type in ["line", "spline", "bar", "step", "step-start", "step-end"]
          console.warn "Unknown serie type: #{serie.type}. Use line instead."
          serie.type = "line"
        if serie.type in ["line", "spline", "bar"]
          params.types[serie.name] = serie.type
        else if serie.type in ["step", "step-start", "step-end"]
          params.types[serie.name] = "step"
          params.line ?= {}
          params.line.step ?= {}
          if serie.type is "step-start"
            params.line.step.type = "step-before"
          else if serie.type is "step-end"
            params.line.step.type = "step-after"
          else
            params.line.step.type = "step"
          params.line.step_type = params.line.step.type



      linear:
        # Generates linear series parameters for C3.js
        load: (series, params) ->
          return unless series
          unless $.isArray series
            series = [series]
          params.data.columns = []
          for serie, index in series
            unless serie.name
              serie.name = "serie#{index}"
            C.adapters.c3.series._loadType(serie, params)
            if serie.label?
              params.data.names ?= {}
              params.data.names[serie.name] = serie.label
            params.data.columns.push [serie.name].concat(serie.values)

      nonlinear:
        # Generates times series parameters for C3.js
        load: (series, params) ->
          return unless series
          params.axis ?= {}
          params.axis.x ?= {}
          params.axis.x.type = 'indexed'
          unless $.isArray series
            series = [series]
          params.data.columns = []
          for serie, index in series
            unless serie.name
              serie.name = "serie#{index}"
            C.adapters.c3.series._loadType(serie, params)
            if serie.label?
              params.data.names ?= {}
              params.data.names[serie.name] = serie.label
            x_serie =
              name: "_x_#{serie.name}"
              values: []
            serie.y_values = []
            for value in series.values
              x_serie.values.push value[0]
              serie.y_values.push value[1]
            params.data.columns.push [serie.name].concat(serie.y_values)
            params.data.columns.push [x_serie.name].concat(x_serie.values)
            params.data.xs ?= {}
            params.data.xs[serie.name] = x_serie.name
            params.axis ?= {}
            params.axis.x ?= {}
            params.axis.x.type ?= "timeseries"
      time:
        # Generates times series parameters for C3.js
        load: (series, params) ->
          return unless series
          params.axis ?= {}
          params.axis.x ?= {}
          params.axis.x.type = 'timeseries'
          unless $.isArray series
            series = [series]
          params.data.columns = []
          for serie, index in series
            unless serie.name
              serie.name = "serie#{index}"
            C.adapters.c3.series._loadType(serie, params)
            if serie.label?
              params.data.names ?= {}
              params.data.names[serie.name] = serie.label
            x_serie =
              name: "_x_#{serie.name}"
              values: []
            serie.y_values = []
            for value in serie.values
              x_serie.values.push value[0]
              serie.y_values.push value[1]
            params.data.xFormat = '%Y-%m-%dT%H:%M:%S'
            params.data.columns.push [serie.name].concat(serie.y_values)
            params.data.columns.push [x_serie.name].concat(x_serie.values)
            params.data.xs ?= {}
            params.data.xs[serie.name] = x_serie.name
            params.axis ?= {}
            params.axis.x ?= {}
            params.axis.x.type ?= "timeseries"

) chart, jQuery
