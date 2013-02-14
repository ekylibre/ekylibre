class ActionDispatch::Routing::Mapper

  def dashboards(options = {})
    configuration = {:path => "dashboards"}.merge(options)
    for menu in Ekylibre.menu.with_menus.sort{|a,b| -a.hierarchy.size <=> -b.hierarchy.size}
      h = menu.hierarchy.collect{|m| m.name }[1..-1]
      next if h.empty?
      get configuration[:path] + "/" + h.join("/"), :to => "dashboards#" + h.join("_"), :as => h.join("_")+"_dashboard"
    end
  end


  # Create unroll routes for all scope by default for the current_ressource
  def unroll_all(options = {})
    begin
      for unroll in ((((@scope[:module].blank? ? "" : @scope[:module].to_s + "/") + @scope[:controller].to_s + "_controller").camelcase.constantize.unrolls)||[])
        get(unroll)
      end
    rescue # Exception => e
      # Migrate mode
      # puts "#{e.class.name}: #{e.message}\n" + e.backtrace.join("\n")
    ensure
      return nil
    end
  end


end
