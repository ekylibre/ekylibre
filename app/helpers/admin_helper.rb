module AdminHelper

  def bar_chart(values, options = {})
    render :partial => "admin/charts/bar_chart", :locals => {:values => values}
  end

  def pie_chart(values, options = {})
    render :partial => "admin/charts/pie_chart", :locals => {:values => values}
  end

end
