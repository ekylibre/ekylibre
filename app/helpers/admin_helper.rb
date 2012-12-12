module AdminHelper

  def bar_chart(values, options = {})
    # id = rand(1000_000_000).to_s(36) + rand(1000_000_000).to_s(36)
    # return content_tag(:div, "", "data-chart" => "bar", "data-values" => values.to_json, :id => id)
    render :partial => "admin/cells/bar_chart", :locals => {:values => values}
  end

end
