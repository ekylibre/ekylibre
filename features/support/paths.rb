module NavigationHelpers
  def path_to(page_name)
    case page_name
    
    when /the general dashboard page/
      root_path
    
    when /the login page/
      new_session_path
    
    # Add more page name => path mappings here
    
    else
      raise "Can't find mapping from \"#{page_name}\" to a path."
    end
  end

  def current_path
    URI.parse(current_url).path
  end


end

World(NavigationHelpers)
