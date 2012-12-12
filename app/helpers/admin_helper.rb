module AdminHelper

  def bar_chart(values, options = {})
    render :partial => "admin/charts/bar_chart", :locals => {:values => values}
  end

  def pie_chart(values, options = {})
    render :partial => "admin/charts/pie_chart", :locals => {:values => values}
  end

  def pie_piece_path(x, y, radius, angle_start, angle_stop)
    # M 320,240 L 414.96396989003193,208.66560320151174 A 100,100,0,0,1, 361.91765204166643,330.7904755319289Z
    path = "M#{x},#{y}"
    x1 = 
    path << "L#{x + radius.to_f*Math.cos(angle_start*Math::PI/180.0)},#{y + radius.to_f*Math.sin(angle_start*Math::PI/180.0)}"
    path << "A#{radius},#{radius},#{angle_start},0,1,#{x + radius.to_f*Math.cos(angle_stop*Math::PI/180.0)},#{y + radius.to_f*Math.sin(angle_stop*Math::PI/180.0)}"
    path << "Z"
    return path
  end

end
