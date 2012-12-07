class ActionDispatch::Routing::Mapper

  def dashboards(options = {})
    configuration = {:path => "dashboards"}.merge(options)
    for menu in Ekylibre.menu.with_menus.sort{|a,b| -a.hierarchy.size <=> -b.hierarchy.size}
      h = menu.hierarchy.collect{|m| m.name }[1..-1]
      next if h.empty?
      get configuration[:path] + "/" + h.join("/"), :to => "dashboards#" + h.join("_"), :as => h.join("_")+"_dashboard"
    end
  end

end
