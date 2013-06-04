class ActionDispatch::Routing::Mapper

  def dashboards(options = {})
    configuration = {:path => "dashboards"}.merge(options)
    for mod in Ekylibre::Modules.hash.keys # .sort{|a,b| -a.hierarchy.size <=> -b.hierarchy.size}
      # h = menu.hierarchy.collect{|m| m.name }[1..-1]
      # next if h.empty?
      get configuration[:path] + "/" + mod.to_s, :to => "dashboards##{mod}", :as => "#{mod}_dashboard"
    end
  end


  # Create unroll routes for all scope by default for the current_ressource
  def unroll_all(options = {})
    unless Ekylibre.migrating?
      for unroll in ((((@scope[:module].blank? ? "" : @scope[:module].to_s + "/") + @scope[:controller].to_s + "_controller").camelcase.constantize.unrolls)||[])
        get(unroll)
      end
    end
    return nil
  end


end
