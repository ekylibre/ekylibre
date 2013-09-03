module Backend::ChartsHelper

  OPTIONS = [:colors, :credits, :exporting, :labels, :legend, :loading, :navigation, :pane, :plot_options, :series, :subtitle, :title, :tooltip, :x_axis, :y_axis].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '-') # camelize(:lower)
    hash
  end.freeze

  TYPES = [:line, :spline, :area, :area_spline, :column, :bar, :pie, :scatter, :area_range, :area_spline_range, :column_range].inject({}) do |hash, name|
    hash[name] = name.to_s.gsub('_', '')
    hash
  end.freeze

  for type, absolute_type in TYPES
    code  = "def #{type}_chart(series, options = {}, html_options = {})\n"
    code << "  options[:type] = '#{absolute_type}'\n"
    code << "  return highchart(series, options, html_options)\n"
    code << "end\n"
  end

  def highchart(series, options = {}, html_options = {})
    for name, absolute_name in OPTIONS
      if options.has_key? name
        html_options["data-highchart-#{absolute_name}"] = jsonize(options.delete(name))
      end
    end
    html_options["data-highchart-series"] = jsonize(series)
    html_options["data-highchart"] = jsonize(options)
    return content_tag(:div, nil, html_options)
  end

  def jsonize(hash)
    return hash.deep_transform_keys do |key|
      key.to_s.camelize(:lower)
    end.to_json
  end

end
