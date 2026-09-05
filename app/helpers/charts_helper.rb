# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

module ChartsHelper
  TYPES = %i[line spline area area_spline column bar pie scatter area_range area_spline_range column_range waterfall bubble packedbubble].each_with_object({}) do |name, hash|
    hash[name] = name.to_s.delete('_')
    hash
  end.freeze

  ECHARTS_TYPE_MAP = {
    'line' => 'line',
    'spline' => 'line',
    'area' => 'line',
    'areaspline' => 'line',
    'column' => 'bar',
    'bar' => 'bar',
    'pie' => 'pie',
    'scatter' => 'scatter',
    'bubble' => 'scatter',
    'waterfall' => 'bar'
  }.freeze

  UNSUPPORTED_TYPES = %w[arearange areasplinerange columnrange packedbubble].freeze

  COLORS = {
    aliceblue: '#F0F8FF',
    antiquewhite: '#FAEBD7',
    aqua: '#00FFFF',
    aquamarine: '#7FFFD4',
    azure: '#F0FFFF',
    beige: '#F5F5DC',
    bisque: '#FFE4C4',
    black: '#000000',
    blanchedalmond: '#FFEBCD',
    blue: '#0000FF',
    blueviolet: '#8A2BE2',
    brown: '#A52A2A',
    burlywood: '#DEB887',
    cadetblue: '#5F9EA0',
    chartreuse: '#7FFF00',
    chocolate: '#D2691E',
    coral: '#FF7F50',
    cornflowerblue: '#6495ED',
    cornsilk: '#FFF8DC',
    crimson: '#DC143C',
    cyan: '#00FFFF',
    darkblue: '#00008B',
    darkcyan: '#008B8B',
    darkgoldenrod: '#B8860B',
    darkgray: '#A9A9A9',
    darkgrey: '#A9A9A9',
    darkgreen: '#006400',
    darkkhaki: '#BDB76B',
    darkmagenta: '#8B008B',
    darkolivegreen: '#556B2F',
    darkorange: '#FF8C00',
    darkorchid: '#9932CC',
    darkred: '#8B0000',
    darksalmon: '#E9967A',
    darkseagreen: '#8FBC8F',
    darkslateblue: '#483D8B',
    darkslategray: '#2F4F4F',
    darkslategrey: '#2F4F4F',
    darkturquoise: '#00CED1',
    darkviolet: '#9400D3',
    deeppink: '#FF1493',
    deepskyblue: '#00BFFF',
    dimgray: '#696969',
    dimgrey: '#696969',
    dodgerblue: '#1E90FF',
    firebrick: '#B22222',
    floralwhite: '#FFFAF0',
    forestgreen: '#228B22',
    fuchsia: '#FF00FF',
    gainsboro: '#DCDCDC',
    ghostwhite: '#F8F8FF',
    gold: '#FFD700',
    goldenrod: '#DAA520',
    gray: '#808080',
    grey: '#808080',
    green: '#008000',
    greenyellow: '#ADFF2F',
    honeydew: '#F0FFF0',
    hotpink: '#FF69B4',
    indianred: '#CD5C5C',
    indigo: '#4B0082',
    ivory: '#FFFFF0',
    khaki: '#F0E68C',
    lavender: '#E6E6FA',
    lavenderblush: '#FFF0F5',
    lawngreen: '#7CFC00',
    lemonchiffon: '#FFFACD',
    lightblue: '#ADD8E6',
    lightcoral: '#F08080',
    lightcyan: '#E0FFFF',
    lightgoldenrodyellow: '#FAFAD2',
    lightgray: '#D3D3D3',
    lightgrey: '#D3D3D3',
    lightgreen: '#90EE90',
    lightpink: '#FFB6C1',
    lightsalmon: '#FFA07A',
    lightseagreen: '#20B2AA',
    lightskyblue: '#87CEFA',
    lightslategray: '#778899',
    lightslategrey: '#778899',
    lightsteelblue: '#B0C4DE',
    lightyellow: '#FFFFE0',
    lime: '#00FF00',
    limegreen: '#32CD32',
    linen: '#FAF0E6',
    magenta: '#FF00FF',
    maroon: '#800000',
    mediumaquamarine: '#66CDAA',
    mediumblue: '#0000CD',
    mediumorchid: '#BA55D3',
    mediumpurple: '#9370DB',
    mediumseagreen: '#3CB371',
    mediumslateblue: '#7B68EE',
    mediumspringgreen: '#00FA9A',
    mediumturquoise: '#48D1CC',
    mediumvioletred: '#C71585',
    midnightblue: '#191970',
    mintcream: '#F5FFFA',
    mistyrose: '#FFE4E1',
    moccasin: '#FFE4B5',
    navajowhite: '#FFDEAD',
    navy: '#000080',
    oldlace: '#FDF5E6',
    olive: '#808000',
    olivedrab: '#6B8E23',
    orange: '#FFA500',
    orangered: '#FF4500',
    orchid: '#DA70D6',
    palegoldenrod: '#EEE8AA',
    palegreen: '#98FB98',
    paleturquoise: '#AFEEEE',
    palevioletred: '#DB7093',
    papayawhip: '#FFEFD5',
    peachpuff: '#FFDAB9',
    peru: '#CD853F',
    pink: '#FFC0CB',
    plum: '#DDA0DD',
    powderblue: '#B0E0E6',
    purple: '#800080',
    rebeccapurple: '#663399',
    red: '#FF0000',
    rosybrown: '#BC8F8F',
    royalblue: '#4169E1',
    saddlebrown: '#8B4513',
    salmon: '#FA8072',
    sandybrown: '#F4A460',
    seagreen: '#2E8B57',
    seashell: '#FFF5EE',
    sienna: '#A0522D',
    silver: '#C0C0C0',
    skyblue: '#87CEEB',
    slateblue: '#6A5ACD',
    slategray: '#708090',
    slategrey: '#708090',
    snow: '#FFFAFA',
    springgreen: '#00FF7F',
    steelblue: '#4682B4',
    tan: '#D2B48C',
    teal: '#008080',
    thistle: '#D8BFD8',
    tomato: '#FF6347',
    turquoise: '#40E0D0',
    violet: '#EE82EE',
    wheat: '#F5DEB3',
    white: '#FFFFFF',
    whitesmoke: '#F5F5F5',
    yellow: '#FFFF00',
    yellowgreen: '#9ACD32'
  }.freeze

  def lightness(color)
    color = COLORS[color.downcase.to_sym] unless color.to_s =~ /\A\#[a-fA-F0-9]{6}\z/
    color ||= '#777777'
    r = color[1..2].to_i(16)
    g = color[3..4].to_i(16)
    b = color[5..6].to_i(16)
    0.299 * r + 0.587 * g + 0.114 * b
  end

  def contrasted_color(color)
    if lightness(color) > 160
      '#333333'
    else
      '#FFFFFF'
    end
  end

  def ligthen(color, rate)
    r = color[1..2].to_i(16)
    g = color[3..4].to_i(16)
    b = color[5..6].to_i(16)
    r *= (1 + rate)
    g *= (1 + rate)
    b *= (1 + rate)
    r = 255 if r > 255
    g = 255 if g > 255
    b = 255 if b > 255
    '#' + r.to_i.to_s(16).rjust(2, '0') + g.to_i.to_s(16).rjust(2, '0') + b.to_i.to_s(16).rjust(2, '0')
  end

  TYPES.each do |type, absolute_type|
    define_method "#{type}_highcharts" do |series, options = {}, html_options = {}|
      if UNSUPPORTED_TYPES.include?(absolute_type)
        raise NotImplementedError, "Chart type '#{absolute_type}' is not supported by the ECharts backend yet. Add it to ChartsHelper if needed."
      end

      options = options.dup
      series = series.is_a?(Array) ? series.dup : [series]

      echarts_options = build_echarts_options(absolute_type, series, options)
      echarts_options[:textStyle] ||= {}
      echarts_options[:textStyle][:fontFamily] ||= theme_font_family if respond_to?(:theme_font_family)
      echarts_options[:textStyle][:fontSize]   ||= theme_font_size   if respond_to?(:theme_font_size)
      echarts_options[:color] ||= (respond_to?(:theme_colors) ? theme_colors : nil)
      echarts_options.compact!

      html_options[:data] ||= {}
      html_options[:data][:echarts] = echarts_options.to_json
      content_tag(:div, nil, html_options)
    end
  end

  def normalize_serie(values, x_values, default = 0.0)
    x_values.map do |x|
      (values[x] || default).to_s.to_f
    end
  end

  def formate_and_translate(categories)
    categories.map { |category| category.l(format: "%b %Y") }
  end

  private

    # ------------------------------------------------------------------
    # ECharts options builder
    # ------------------------------------------------------------------
    #
    # Receives the Highcharts-style options hash that views still write,
    # plus the resolved Highcharts type (e.g. 'column', 'spline'),
    # and returns an ECharts-shaped Hash with symbol keys (camelCase).
    #
    # The translation is intentionally pragmatic: it covers the patterns
    # actually used in the codebase (see views and plugins). Exotic
    # Highcharts options not used in any callsite are dropped silently.
    def build_echarts_options(hc_type, series, options)
      echarts_type = ECHARTS_TYPE_MAP[hc_type] || hc_type
      pie_chart = (hc_type == 'pie')

      # Highcharts derives category labels from each data point's :name
      # when the x-axis is type 'category' but no :categories array was
      # supplied. ECharts requires xAxis.data to be set explicitly, so we
      # do the derivation here before reshaping the series.
      derive_categories_from_series!(options, series) unless pie_chart

      result = {}
      result[:title]   = build_title(options[:title], options[:subtitle])
      result[:legend]  = build_legend(options[:legend])
      result[:tooltip] = build_tooltip(options[:tooltip], pie_chart, hc_type)
      unless pie_chart
        result[:xAxis] = build_axis(options[:x_axis], default_type: hc_type == 'bar' ? 'value' : 'category', is_x: true, hc_type: hc_type)
        result[:yAxis] = build_axis(options[:y_axis], default_type: hc_type == 'bar' ? 'category' : 'value', is_x: false, hc_type: hc_type)
        # Ask ECharts to expand the plot grid so that rotated category
        # labels, axis titles and the legend never overflow the canvas.
        result[:grid] = { containLabel: true, left: 10, right: 20, top: 40, bottom: 10 }
      end
      result[:color]   = options[:colors] if options[:colors]

      stacking, data_labels, type_overrides = extract_plot_options(options[:plot_options], hc_type)
      result[:series] = build_series(series, hc_type, echarts_type, stacking, data_labels, type_overrides)

      result[:__drilldown] = options[:drilldown] if options[:drilldown].present?

      result
    end

    def derive_categories_from_series!(options, series)
      xa = options[:x_axis]
      return if xa.is_a?(Array)
      xa = xa.is_a?(Hash) ? xa : {}
      return if xa[:categories].present?
      return unless %w[category].include?(xa[:type].to_s)
      first = series.first
      return unless first.is_a?(Hash) && first[:data].is_a?(Array)
      names = first[:data].map { |p| p.is_a?(Hash) ? p[:name] : nil }
      return if names.compact.empty?
      options[:x_axis] = xa.merge(categories: names)
    end

    def build_title(title, subtitle)
      return nil if title.nil? && subtitle.nil?
      out = {}
      if title.is_a?(Hash)
        out[:text] = title[:text] if title[:text]
        out[:left] = title[:align] if title[:align]
      elsif title.is_a?(String) || title.is_a?(Symbol)
        out[:text] = title.is_a?(Symbol) ? title.tl(default: title.to_s.humanize) : title
      end
      if subtitle.is_a?(Hash)
        out[:subtext] = subtitle[:text] if subtitle[:text]
      elsif subtitle.is_a?(String) || subtitle.is_a?(Symbol)
        out[:subtext] = subtitle.to_s
      end
      out.empty? ? nil : out
    end

    def build_legend(legend)
      return nil if legend.nil? || legend == false
      return { show: true } if legend == true
      if legend.is_a?(Hash)
        show = legend.key?(:enabled) ? legend[:enabled] : true
        out = { show: show ? true : false }
        out[:bottom] = 0 if legend[:align] == 'bottom'
        return out
      end
      nil
    end

    def build_tooltip(tooltip, pie_chart, hc_type = nil)
      out = { show: true }
      # 'item' trigger means: hovering a bar/slice shows ONLY that
      # item's value. 'axis' trigger shows every series at the hovered
      # category — fine for line/area, noisy for waterfall (the
      # placeholder/gain/loss/total series each contribute one entry per
      # category and only one is meaningful at a given x).
      out[:trigger] = if pie_chart || hc_type == 'waterfall'
                        'item'
                      else
                        'axis'
                      end
      if tooltip.is_a?(Hash)
        out[:show] = false if tooltip[:enabled] == false
        out[:trigger] = 'axis' if tooltip[:shared] == true
        if tooltip[:point_format].is_a?(String)
          out[:formatter] = convert_point_format(tooltip[:point_format])
        end
      end
      out
    end

    # Converts a small subset of Highcharts point format placeholders to
    # ECharts placeholders. Best-effort: complex HTML tooltips fall back
    # to a string with {c} substituted in place of {point.y}.
    #
    # Highcharts → ECharts placeholder cheatsheet:
    #   {point.y[:format]}     → {c}    (numeric value)
    #   {point.name}           → {b}    (category name)
    #   {series.name}          → {a}    (series name)
    def convert_point_format(fmt)
      fmt = fmt.to_s
      fmt = fmt.gsub(/\{point\.y[^}]*\}/, '{c}')
      fmt = fmt.gsub(/\{point\.name\}/, '{b}')
      fmt = fmt.gsub(/\{series\.name\}/, '{a}')
      fmt
    end

    def build_axis(axis, default_type:, is_x:, hc_type:)
      return { type: default_type } if axis.nil?

      list = axis.is_a?(Array) ? axis : [axis]
      converted = list.map do |a|
        build_single_axis(a, default_type: default_type, is_x: is_x, hc_type: hc_type)
      end
      list.size == 1 ? converted.first : converted
    end

    def build_single_axis(axis, default_type:, is_x:, hc_type:)
      out = {}
      out[:type] = axis[:type] == 'datetime' ? 'time' : (axis[:type] || default_type)
      out[:type] = 'category' if axis[:categories]
      out[:data] = axis[:categories] if axis[:categories]
      out[:min]  = axis[:min] if axis.key?(:min)
      out[:max]  = axis[:max] if axis.key?(:max)
      if axis[:title].is_a?(Hash) && axis[:title][:text]
        out[:name] = axis[:title][:text]
        out[:nameLocation] = 'middle'
        out[:nameGap] = is_x ? 30 : 50
      end
      if axis[:labels].is_a?(Hash) && axis[:labels][:format]
        out[:axisLabel] = { formatter: axis[:labels][:format] }
      end
      if axis[:opposite]
        out[:position] = is_x ? 'top' : 'right'
      end

      # ECharts thins out category labels automatically when they
      # overlap. For most Ekylibre charts (especially waterfall and
      # stacked columns) we want every label to show. Force interval=0
      # and tilt long labels so they don't collide horizontally.
      if is_x && out[:type] == 'category' && out[:data].is_a?(Array)
        out[:axisLabel] ||= {}
        out[:axisLabel][:interval] = 0 unless out[:axisLabel].key?(:interval)
        labels = out[:data]
        avg_len = labels.empty? ? 0 : (labels.sum { |s| s.to_s.length } / labels.size)
        if !out[:axisLabel].key?(:rotate) && (avg_len > 6 || labels.size > 6)
          out[:axisLabel][:rotate] = 30
        end
      end
      out
    end

    # Returns [stacking_mode, data_labels_enabled, type_overrides_hash]
    # stacking_mode is nil or a string used as ECharts series.stack key.
    # data_labels_enabled is a boolean.
    # type_overrides_hash maps series-type-string → hash of options.
    def extract_plot_options(plot_options, hc_type)
      stacking = nil
      data_labels = false
      type_overrides = {}
      return [stacking, data_labels, type_overrides] unless plot_options.is_a?(Hash)

      relevant_keys = [hc_type, 'series', hc_type.to_sym, :series, :pie, :column, :bar, :area, :line, :scatter, :spline]
      relevant_keys.uniq.each do |key|
        opts = plot_options[key] || plot_options[key.to_s] || plot_options[key.to_sym]
        next unless opts.is_a?(Hash)

        stacking ||= 'group' if opts[:stacking].to_s == 'normal'
        if opts[:data_labels].is_a?(Hash)
          data_labels = true if opts[:data_labels][:enabled]
        end
        type_overrides[key.to_s] ||= opts
      end

      [stacking, data_labels, type_overrides]
    end

    def build_series(series, hc_type, echarts_type, stacking, data_labels, type_overrides)
      if hc_type == 'waterfall'
        return build_waterfall_series(series, data_labels)
      end

      series.map do |raw|
        s = raw.is_a?(Hash) ? raw.deep_dup : { data: raw }
        s[:type] = echarts_type
        s[:smooth] = true if %w[spline areaspline].include?(hc_type)
        s[:areaStyle] = {} if %w[area areaspline].include?(hc_type)
        s[:stack] = stacking if stacking

        # per-series data_labels override (Highcharts allowed it on each
        # series object as well as via plot_options)
        per_series_dl = s.delete(:data_labels)
        if data_labels || (per_series_dl.is_a?(Hash) && per_series_dl[:enabled])
          s[:label] ||= {}
          s[:label][:show] = true
          if per_series_dl.is_a?(Hash) && per_series_dl[:format]
            s[:label][:formatter] = convert_point_format(per_series_dl[:format])
          end
        elsif per_series_dl.is_a?(Hash) && per_series_dl[:enabled] == false
          s[:label] = { show: false }
        end

        # Translate per-point data: Highcharts {name, y, color, ...} →
        # ECharts {name, value, itemStyle: {color}, ...}. Numeric arrays
        # and nested arrays (used by bubble/scatter) pass through as-is.
        s[:data] = translate_data_points(s[:data]) if s[:data]

        # pie-specific tweaks
        if hc_type == 'pie'
          # Highcharts uses size/inner_size; ECharts uses radius as either
          # a single value (regular pie) or [inner, outer] (donut).
          outer = s.delete(:size) || s.delete(:radius)
          inner = s.delete(:inner_size) || s.delete(:innerSize)
          if inner
            s[:radius] = [inner, outer || '80%']
          elsif outer
            s[:radius] = outer
          else
            s[:radius] ||= '70%'
          end
          s[:center] ||= ['50%', '50%']

          pie_overrides = type_overrides['pie'] || {}
          if pie_overrides[:data_labels].is_a?(Hash) && pie_overrides[:data_labels][:format]
            s[:label] ||= {}
            s[:label][:show] = true
            s[:label][:formatter] = convert_point_format(pie_overrides[:data_labels][:format])
          end
        end
        # bubble: symbolSize from third point coordinate
        if hc_type == 'bubble'
          s[:symbolSize] = 'function(val){return Math.sqrt(val[2] || 1) * 5;}'
        end
        s
      end
    end

    # Translates each Highcharts-style data point to its ECharts form.
    # Pass-through for numeric values and arrays (bubble/scatter).
    def translate_data_points(data)
      return data unless data.is_a?(Array)
      data.map { |pt| translate_data_point(pt) }
    end

    def translate_data_point(point)
      return point unless point.is_a?(Hash)
      pt = point.dup
      # y → value (Highcharts → ECharts)
      pt[:value] = pt.delete(:y) if pt.key?(:y) && !pt.key?(:value)
      # color → itemStyle.color
      if (color = pt.delete(:color))
        pt[:itemStyle] = (pt[:itemStyle] || {}).merge(color: color)
      end
      # Highcharts also lets points carry `name`, which ECharts honors.
      pt
    end

    # Highcharts waterfall uses a single series with positive/negative
    # deltas and an optional 'sum'/'intermediateSum' marker. ECharts has
    # no native waterfall; the canonical recipe uses stacked bar series
    # (placeholder + gains + losses + totals) computed from the deltas,
    # plus a connector line so the cascade pattern is recognisable.
    def build_waterfall_series(series, data_labels)
      raw = series.first.is_a?(Hash) ? series.first[:data] : series.first
      raw = [] unless raw.is_a?(Array)

      placeholder = []
      positives   = []
      negatives   = []
      totals      = []
      connectors  = []  # series of {value: tip_height} used to draw a thin connector line
      running     = 0.0

      raw.each_with_index do |point, idx|
        is_sum = point.is_a?(Hash) && (point[:is_sum] || point[:isSum] || point[:isIntermediateSum] || point[:is_intermediate_sum])
        if is_sum
          placeholder << '-'
          positives   << '-'
          negatives   << '-'
          totals      << running
          connectors  << running
        else
          value = point.is_a?(Hash) ? (point[:y] || point[:value]) : point
          value = value.to_f
          if value >= 0
            placeholder << running
            positives   << value
            negatives   << '-'
            totals      << '-'
            running    += value
          else
            placeholder << (running + value)
            positives   << '-'
            negatives   << value.abs
            totals      << '-'
            running    += value
          end
          connectors << running
        end
      end

      label_block = data_labels ? { show: true, position: 'top' } : nil
      [
        # Invisible base that lifts the visible bar to the running total.
        { name: 'placeholder', type: 'bar', stack: 'waterfall',
          itemStyle: { color: 'rgba(0,0,0,0)' },
          emphasis: { itemStyle: { color: 'rgba(0,0,0,0)' } },
          tooltip: { show: false },
          data: placeholder },
        { name: I18n.t('labels.gain', default: 'Gain'),
          type: 'bar', stack: 'waterfall',
          itemStyle: { color: '#7cb342' },
          data: positives, label: label_block }.compact,
        { name: I18n.t('labels.loss', default: 'Perte'),
          type: 'bar', stack: 'waterfall',
          itemStyle: { color: '#e53935' },
          data: negatives, label: label_block }.compact,
        { name: I18n.t('labels.total', default: 'Total'),
          type: 'bar', stack: 'waterfall',
          itemStyle: { color: '#546e7a' },
          data: totals, label: label_block }.compact,
        # Connector line: a thin dashed line linking the top of each bar
        # to the next so the cascade shape is recognisable. Rendered on
        # its own canvas layer (zlevel) so it sits above the bar fills,
        # including the gray total/intermediate-sum bars.
        { name: '__connector', type: 'line',
          symbol: 'none',
          lineStyle: { color: '#9e9e9e', type: 'dashed', width: 1.5 },
          tooltip: { show: false },
          z: 10,
          zlevel: 1,
          silent: true,
          legendHoverLink: false,
          data: connectors }
      ]
    end
end
