<%=
window(:title=>title_tag, :orient=>:vertical) do |w|
  w.hbox do |h|
    h.vbox({:align=>:start}, location_tag(:guide))
    h.vbox({:align=>:end}, location_tag(:user))
  end
  w.hbox do |h|
    h.vbox({:flex=>1}, location_tag(:user))
    h.splitter :collapse=>:before
    h.vbox({:flex=>1}) do |v|
      v << flash_tag :error
      v << flash_tag :warning
      v << flash_tag :notice
      v << yield
    end
    h.splitter :collapse=>:after
    h.vbox({:flex=>1}, location_tag(:user))
  end
end
-%>
