
def hash_dig(hash, options = {}, &block)
  namespaces = options[:namespaces] || []
  for key, value in hash.sort{|a,b| a[0].to_s <=> b[0].to_s}
    keys = namespaces + [key]
    yield(keys, value)
    hash_dig(value, :namespaces => keys, &block) if value.is_a?(Hash)
  end
  return nil
end


def hash_to_yaml(hash, depth=0)
  code = "\n"
  x = hash.to_a.sort{|a,b| a[0].to_s.gsub("_"," ").strip<=>b[0].to_s.gsub("_"," ").strip}
  x.each_index do |i|
    k, v = x[i][0], x[i][1]
    # code += "  "*depth+k.to_s+":"+(v.is_a?(Hash) ? "\n"+hash_to_yaml(v,depth+1) : " '"+v.gsub("'", "''")+"'\n") if v
    code += "  "*depth+k.to_s+":"+(v.is_a?(Hash) ? hash_to_yaml(v, depth+1) : " "+yaml_value(v))+(i == x.size-1 ? '' : "\n") if v
  end
  code
end

def yaml_to_hash(filename)
  hash = YAML::load(IO.read(filename).gsub(/^(\s*)no:(.*)$/, '\1__no_is_not__false__:\2'))
  return deep_symbolize_keys(hash)
end

def hash_sort_and_count(hash, depth=0)
  hash ||= {}
  code, count = "", 0
  for key, value in hash.sort{|a, b| a[0].to_s <=> b[0].to_s}
    if value.is_a? Hash
      scode, scount = hash_sort_and_count(value, depth+1)
      code += "  "*depth+key.to_s+":\n"+scode
      count += scount
    else
      code += "  "*depth+key.to_s+": "+yaml_value(value, depth+1)+"\n"
      count += 1
    end
  end
  return code, count
end


def hash_count(hash)
  count = 0
  for key, value in hash
    count += (value.is_a?(Hash) ? hash_count(value) : 1)
  end
  return count
end

def sort_yaml_file(filename, log=nil)
  yaml_file = Rails.root.join("config", "locales", ::I18n.locale.to_s, "#{filename}.yml")
  # translation = hash_to_yaml(yaml_to_hash(file)).strip
  translation, total = hash_sort_and_count(yaml_to_hash(yaml_file))
  File.open(yaml_file, "wb") do |file|
    file.write translation.strip
  end
  count = 0
  log.write "  - #{(filename.to_s+'.yml:').ljust(20)} #{(100*(total-count)/total).round.to_s.rjust(3)}% (#{total-count}/#{total})\n" if log
  return total
end

def deep_symbolize_keys(hash)
  hash.inject({}) { |result, (key, value)|
    value = deep_symbolize_keys(value) if value.is_a? Hash
    key = :no if key.to_s == "__no_is_not__false__"
    result[(key.to_sym rescue key) || key] = value
    result
  }
end


def yaml_value(value, depth=0)
  if value.is_a?(Array)
    "["+value.collect{|x| yaml_value(x)}.join(", ")+"]"
  elsif value.is_a?(Symbol)
    ":"+value.to_s
  elsif value.is_a?(Hash)
    hash_to_yaml(value, depth+1)
  elsif value.is_a?(Numeric)
    value.to_s
  else
    # "'"+value.to_s.gsub("'", "''")+"'"
    '"'+value.to_s.gsub("\u00A0", "\\_")+'"'
  end
end

def hash_diff(hash, ref, depth=0)
  hash ||= {}
  ref ||= {}
  keys = (ref.keys+hash.keys).uniq.sort{|a,b| a.to_s.gsub("_"," ").strip<=>b.to_s.gsub("_"," ").strip}
  code, count, total = "", 0, 0
  for key in keys
    h, r = hash[key], ref[key]
    # total += 1 unless r.is_a? Hash
    if r.is_a?(Hash) and (h.is_a?(Hash) or h.nil?)
      scode, scount, stotal = hash_diff(h, r, depth+1)
      code  += "  "*depth+key.to_s+":\n"+scode
      count += scount
      total += stotal
    elsif r and h.nil?
      code  += "  "*depth+"# "+key.to_s+": "+yaml_value(r, depth+1)+"\n"
      count += 1
      total += 1
    elsif r and h and r.class == h.class
      code  += "  "*depth+key.to_s+": "+yaml_value(h, depth+1)+"\n"
      total += 1
    elsif r and h and r.class != h.class
      code  += "  "*depth+key.to_s+": "+(yaml_value(h, depth)+"\n").gsub(/\n/, " #? #{r.class.name} excepted (#{h.class.name+':'+h.inspect})\n")
      total += 1
    elsif h and r.nil?
      code  += "  "*depth+key.to_s+": "+(yaml_value(h, depth)+"\n").to_s.gsub(/\n/, " #?\n")
    elsif r.nil?
      code  += "  "*depth+key.to_s+": #?\n"
    end
  end
  return code, count, total
end





def actions_in_file(path, controller)
  actions = []
  File.open(path, "rb:UTF-8").each_line do |line|
    line = line.gsub(/(^\s*|\s*$)/,'')
    if line.match(/^\s*def\s+[a-z0-9\_]+\s*$/)
      actions << line.split(/def\s/)[1].gsub(/\s/,'')
    # elsif line.match(/^\s*formize[\s\(]+\:\w+/)
    #   formize = line.split(/[\s\(\)\,\:]+/)
    #   actions << "formize_"+formize[1]
    # elsif line.match(/^\s*formize([\s\(]+|\s*$)/)
    #   actions << "formize"
    elsif line.match(/^\s*unroll_all[\s\(]+\:\w+/)
      # TODO add unroll of scopes
      actions << "unroll"
    elsif line.match(/^\s*search_for[\s\(]+\:\w+/)
      search_for = line.split(/[\s\(\)\,\:]+/)
      actions << "search_for_"+search_for[1]
    elsif line.match(/^\s*search_for([\s\(]+|\s*$)/)
      actions << "search_for"
    # elsif line.match(/^\s*dy(li|ta)[\s\(]+\:\w+/)
    #   dyxx = line.split(/[\s\(\)\,\:]+/)
    #   actions << dyxx[1]+'_'+dyxx[0]
    elsif line.match(/^\s*autocomplete_for[\s\(]+\:\w+\s*\,\s*\:\w+/)
      list = line.split(/[\s\(\)\,\:]+/)
      actions << "autocomplete_for_#{list[1]}_#{list[2]}"
    elsif line.match(/^\s*list[\s\(]+\:\w+\s*\,/)
      list = line.split(/[\s\(\)\,\:]+/)
      actions << 'list_'+list[1]
    elsif line.match(/^\s*list([\s\(]+|\s*$)/)
      actions << "list"
    # elsif line.match(/^\s*create_kame[\s\(]+\:\w+/)
    #   kame = line.split(/[\s\(\)\,\:]+/)
    #   actions << kame[1]+'_kame'
    elsif line.match(/^\s*manage_restfully_list/)
      actions << 'up'
      actions << 'down'
    elsif line.match(/^\s*manage_restfully/)
      actions << 'new'
      actions << 'create'
      actions << 'edit'
      actions << 'update'
      actions << 'destroy'
    end
  end
  if controller.to_s == "backend/dashboards"
    for menu in Ekylibre.menu.with_menus do
      h = menu.hierarchy.collect{|m| m.name }[1..-1]
      next if h.empty?
      actions << h.join("_")
    end
  end

  return actions
end

def actions_hash
  ref = HashWithIndifferentAccess.new
  controllers = Rails.root.join("app", "controllers")
  Dir.glob(controllers.join("**", "*_controller.rb")).sort.each do |path|
    controller_name = Pathname.new(path).relative_path_from(controllers).to_s.gsub(/\_controller\.rb$/, '')
    ref[controller_name] = actions_in_file(path, controller_name).sort
  end
  return ref
end

# def controllers_hash
#   ref = HashWithIndifferentAccess.new
#   controllers = Rails.root.join("app", "controllers")
#   Dir.glob(controllers.join("**", "*_controller.rb")) do |path|
#     controller_name = Pathname.new(path).relative_path_from(controllers).to_s.gsub(/\_controller\.rb$/, '').split("/")
#     r = ref
#     for namespace in controller_name[0..-2]
#       r[namespace] ||= HashWithIndifferentAccess.new
#       r = r[namespace]
#     end if controller_name.size > 1
#     r[controller_name.last.to_sym] = nil
#   end
#   return ref
# end


def models_in_file
  Dir.glob(Rails.root.join("app", "models", "*.rb")).each { |file| require file }
  list = if ActiveRecord::Base.respond_to? :descendants
           ActiveRecord::Base.send(:descendants)
         elsif ActiveRecord::Base.respond_to? :subclasses
           ActiveRecord::Base.send(:subclasses)
         else
           Object.subclasses_of(ActiveRecord::Base)
         end.select{|x| not x.name.match('::') and not x.abstract_class?}.uniq.sort{|a,b| a.name <=> b.name}
  # if list.empty?
  #   # Return approximative list
  #   Dir.chdir(Rails.root.join("app", "models")) do
  #     list = Dir.glob("*.rb").each{ |file| file.split(".")[0].classify }
  #   end
  # end
  return list
end


def controllers_in_file
  Dir.glob(Rails.root.join("app", "controllers", "**", "*.rb")).each { |file| require file }
  list = if ActionController::Base.respond_to? :descendants
           ActionController::Base.send(:descendants)
         elsif ActionController::Base.respond_to? :subclasses
           ActionController::Base.send(:subclasses)
         else
           Object.subclasses_of(ActionController::Base)
         end.sort{|a,b| a.name <=> b.name}
  # .select{|x| not x.name.match('::') and not x.abstract_class?}
  return list
end
