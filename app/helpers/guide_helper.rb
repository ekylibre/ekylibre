module GuideHelper
  def guide_link(controller, action)
    link_to content_tag('div', l(controller,action,:title)), {:controller=>controller, :action=>action}, {:class=>:guide}
  end
end
