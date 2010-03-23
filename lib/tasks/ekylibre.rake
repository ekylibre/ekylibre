def hash_to_yaml(hash, depth=0)
  code = ''
  for k, v in hash.to_a.sort{|a,b| a[0].to_s.gsub("_"," ").strip<=>b[0].to_s.gsub("_"," ").strip}
    code += "  "*depth+k.to_s+":"+(v.is_a?(Hash) ? "\n"+hash_to_yaml(v,depth+1) : " '"+v.gsub("'", "''")+"'\n") if v
  end
  code
end

def yaml_to_hash(filename)
  hash = YAML::load(IO.read(filename).gsub(/^(\s*)no:(.*)$/, '\1__no_is_not__false__:\2'))
  return deep_symbolize_keys(hash)
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
    "\n"+hash_to_yaml(value, depth+1)
  else
    "'"+value.to_s.gsub("'", "''")+"'"
  end
end

def hash_diff(hash, ref, depth=0)
  hash ||= {}
  ref ||= {}
  keys = (ref.keys+hash.keys).uniq.sort{|a,b| a.to_s.gsub("_"," ").strip<=>b.to_s.gsub("_"," ").strip}
  code, count, total = "", 0, 0
  for key in keys
    h, r = hash[key], ref[key]
    total += 1 if r.is_a? String
    if r.is_a?(Hash) and (h.is_a?(Hash) or h.nil?)
      scode, scount, stotal = hash_diff(h, r, depth+1)
      code  += "  "*depth+key.to_s+":\n"+scode
      count += scount
      total += stotal
    elsif r and h.nil?
      code  += "  "*depth+"#>"+key.to_s+": "+yaml_value(r)+"\n"
      count += 1
    elsif r and h and r.class == h.class
      code  += "  "*depth+key.to_s+": "+yaml_value(h)+"\n"
    elsif r and h and r.class != h.class
      puts [h,r].inspect
      code  += "  "*depth+key.to_s+": "+(yaml_value(h)+"\n").gsub(/\n/, " #! #{r.class.name} excepted (#{h.class.name+':'+h.inspect})\n")
    elsif h and r.nil?
      code  += "  "*depth+key.to_s+": "+(yaml_value(h)+"\n").to_s.gsub(/\n/, " #!\n")
    elsif r.nil?
      code  += "  "*depth+key.to_s+":\n"
    end
  end  
  return code, count, total
end



desc "Create schema_hash.rb"
task :shash => :environment do
  hash = {}; 
  Company.reflections.select{|k,v| v.macro==:has_many}.each do |k,v| 
    cols={}; 
    v.class_name.constantize.columns.each do |c| 
      cols[c.name]={:null=>c.null, :type=>c.type} 
    end
    hash[k] = cols
  end
  File.open("#{RAILS_ROOT}/db/schema_hash.rb", "wb") do |f|
    f.write("# Auto-generated from Ekylibre\n")
    f.write("EKYLIBRE = "+hash.inspect)
  end
end

def annotate_one_file(file_name, info_block)
  puts "------------------------- "+ file_name.inspect
  unless File.exist?(file_name)
    File.open(file_name, "w") { |f| f.puts "# Generated" }
  end
  if File.exist?(file_name)
    content = File.read(file_name)
    lines = "\nEkylibre - Simple ERP\nCopyright (C) 2009 Brice Texier, Thibaud Mérigon\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n".split(/[\r\n]+/).compact

    for line in lines
      unless line.match(/^\s*$/)
        #  puts line.inspect
        content.gsub!(/^#{line}$/, '#') 
      end
    end
    content.gsub!(/^Copyright.*$/, '#') 
    
    content.gsub!(/\#\n\#\n\s*\n\s*(\n\s*)?\#\n\#/, "#")
    content.gsub!(/\#\n\#\n\s*\n\s*(\n\s*)?\#\n\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")
    #    content.gsub!(/\#\s+\#/, "#")

    # puts content
    # Remove old schema info
    # content.sub!(/^# #{PREFIX}.*?\n(#.*\n)*\n/, '')
    
    
    # Write it back
    File.open(file_name, "wb") { |f| f.puts(content) }
  end
end

desc ""
task :lig do
  models = []
  Dir.chdir("app/models") do 
    models = Dir["**/*.rb"].sort
  end
  
  info =  "\nEkylibre - Simple ERP\nCopyright (C) 2009 Brice Texier, Thibaud Mérigon\n\nThis program is free software: you can redistribute it and/or modify\nit under the terms of the GNU General Public License as published by\nthe Free Software Foundation, either version 3 of the License, or\nany later version.\n\nThis program is distributed in the hope that it will be useful,\nbut WITHOUT ANY WARRANTY; without even the implied warranty of\nMERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\nGNU General Public License for more details.\n\nYou should have received a copy of the GNU General Public License\nalong with this program.  If not, see <http://www.gnu.org/licenses/>.\n\n"
  models.each do |m|
    cn = m.sub(/\.rb$/,'')
    class_name = m.sub(/\.rb$/,'').camelize
    begin
      
      #      klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
      #      if klass < ActiveRecord::Base && !klass.abstract_class?
      puts "Annotating #{class_name}"
      
      model_file_name = File.join("app/models", cn + ".rb")
      annotate_one_file(model_file_name, info)
      
      fixture_file_name = File.join("test/fixtures", cn.pluralize + ".yml")
      annotate_one_file(fixture_file_name, info)

      unit_file_name = File.join("test/unit", cn + "_test.rb")
      annotate_one_file(unit_file_name, info)

      #      else
      #        puts "Skipping #{class_name}"
      #      end
    rescue Exception => e
      puts "Unable to annotate #{class_name}: #{e.message}"
    end
  end

end


def color_to_array(color)
  values = []
  for i in 0..3
    values << color.to_s[2*i..2*i+1].to_s.to_i(16).to_f
  end
  values
end

def array_to_css(color)
  code = '#'
  for x in 0..2
    code += color[x].to_i.to_s(16)
  end
  code.upcase
end

def color_merge(c1, c2)
  r = []
  t = c2[3].to_f/255.to_f
  for i in 0..2
    r << c1[i]*(1-t)+c2[i]*t
  end
  r << 255.to_f
  # puts [array_to_css(c1), array_to_css(c2), c2[3], t, r].inspect
  r
end

desc "Create dyta-colors.css for the default theme"
task :dytacolor do
  
  dims = [
          {:__default__=>"D1DAFFFF", :notice=>"D8FFA3FF", :warning=>"FFE0B3FF", :error=>"FFAD87FF"}, # tr
          # {:__default__=>"E1E6FFFF", :notice=>"D8FFA3FF", :warning=>"FFE0B3FF", :error=>"FFC8BFFF"}, # tr
          {:__default__=>"FFFFFF00", :odd=>"FFFFFF70", :even=>"FFFFFF40"}, # tr
          # {:__default__=>"FFFFFF00", :act=>"AE702234", :sorted=>"1410FF20"} # td
          {:__default__=>"FFFFFF00", :act=>"FF860022", :sorted=>"00128410"} # td
          #                                 FFDDDD60             1410FF20 00128fff
         ]
  hover = color_to_array("00447730")
  dims[0][:advance]     = dims[0][:notice]
  dims[0][:late]        = dims[0][:warning]
  dims[0][:verylate]    = dims[0][:error]
  dims[0][:enough]      = dims[0][:notice]
  dims[0][:minimum]     = dims[0][:warning]
  dims[0][:critic]      = dims[0][:error]
  dims[0][:balanced]           = dims[0][:notice]
  dims[0][:unbalanced]         = dims[0][:error]
  dims[0][:pointable]          = dims[0][:notice]
  dims[0][:unpointabled]       = dims[0][:warning]
  dims[0][:unpointable]        = dims[0][:error]
  dims[0][:letter]             = dims[0][:notice]
  dims[0]['letter-unbalanced'] = dims[0][:warning]

  code = ''

  for k0, v0 in dims[0].sort{|a,b| a[0].to_s<=>b[0].to_s}
    raise Exception.new("Color must given for :#{k0}") if v0.nil?
    dim0 = (k0==:__default__ ? '' : '.'+k0.to_s)
    code += "\n/* #{k0.to_s.camelcase} */\n"
    base = color_to_array(v0)
    for k1, v1 in dims[1].sort{|a,b| a[0].to_s<=>b[0].to_s}
      raise Exception.new("Color must given for :#{k1}") if v1.nil?
      dim1 = (k1==:__default__ ? '' : '.'+k1.to_s)
      inter = color_merge(base, color_to_array(v1))
      for k2, v2 in dims[2].sort{|a,b| a[0].to_s<=>b[0].to_s}
        raise Exception.new("Color must given for :#{k2}") if v2.nil?
        dim2 = (k2==:__default__ ? '' : '.'+k2.to_s)
        last = color_merge(inter, color_to_array(v2))
        code += "table.dyta tr#{dim0}#{dim1} td#{dim2} {background:#{array_to_css(last)}}\n"
        code += "table.dyta tr#{dim0}#{dim1}:hover td#{dim2} {background:#{array_to_css(color_merge(last, hover))}}\n"
      end
    end
  end

  File.open("#{RAILS_ROOT}/public/templates/tekyla/stylesheets/dyta-colors.css", "wb") do |f|
    f.write("/* Auto-generated from Ekylibre (rake dytacolor) */\n")
    f.write(code)
  end
end


namespace :clean do

  desc "Update models list file in lib/"
  task :models => :environment do
    
    Dir.glob(RAILS_ROOT + '/app/models/*.rb').each { |file| require file }
    models = Object.subclasses_of(ActiveRecord::Base).select{|x| not x.name.match('::')}.sort{|a,b| a.name <=> b.name}
    models_code = "EKYLIBRE_MODELS = ["+models.collect{|m| ":"+m.name.underscore}.join(", ")+"]\n"
    
    symodels = models.collect{|x| x.name.underscore.to_sym}

    errors = 0
    require "#{RAILS_ROOT}/lib/models.rb"
    # refs = defined?(EKYLIBRE_REFERENCES) ? EKYLIBRE_REFERENCES : {}
    refs = EKYLIBRE_REFERENCES
    refs_code = ""
    for model in models
      m = model.name.underscore.to_sym
      cols = []
      model.columns.sort{|a,b| a.name<=>b.name}.each do |column|
        c = column.name.to_sym
        if c.to_s.match(/_id$/)
          val = (refs[m].is_a?(Hash) ? refs[m][c] : nil)
          val = ((val.nil? or val.blank?) ? "''" : val.inspect)
          if c == :parent_id
            val = ":#{m}"
          elsif [:creator_id, :updater_id].include? c
            val = ":user"
          elsif symodels.include? c.to_s[0..-4].to_sym
            val = ":#{c.to_s[0..-4]}"
          end
          errors += 1 if val == "''"
          cols << "    :#{c} => #{val}"
        end
      end
      refs_code += "\n  :#{m} => {\n"+cols.join(",\n")+"\n  },"
    end
    puts " - Models: #{errors} errors"
    refs_code = "EKYLIBRE_REFERENCES = {"+refs_code[0..-2]+"\n}\n"

    File.open("#{RAILS_ROOT}/lib/models.rb", "wb") do |f|
      f.write("# Autogenerated from Ekylibre (rake clean:models or rake clean:all)\n")
      f.write("# List of all models\n")
      f.write(models_code)
      f.write("\n# List of all references\n")
      f.write(refs_code)
    end

  end

  desc "Update and sort rights list"
  task :rights => :environment do
    new_right = '__not_used__'

    # Chargement des actions des controllers
    ref = {}
    Dir.glob("#{RAILS_ROOT}/app/controllers/*_controller.rb") do |x|
      controller_name = x.split("/")[-1].split("_controller")[0]
      actions = []
      file = File.open(x, "r")
      file.each_line do |line|
        line = line.gsub(/(^\s*|\s*$)/,'')
        if line.match(/^\s*def\s+\w+\s*$/)
          actions << line.split(/def\s/)[1].gsub(/\s/,'') 
        elsif line.match(/^\s*dy(li|ta)[\s\(]+\:\w+/)
          dyxx = line.split(/[\s\(\)\,\:]+/)
          actions << dyxx[1]+'_'+dyxx[0]
        elsif line.match(/^\s*manage[\s\(]+\:\w+/)
          prefix = line.split(/[\s\(\)\,\:]+/)[1].singularize
          actions << prefix+'_create'
          actions << prefix+'_update'
          actions << prefix+'_delete'
        end
      end
      ref[controller_name] = actions.sort
    end

    # Lecture du fichier existant
    rights = YAML.load_file(User.rights_file)

    # Expand actions
    for right, attributes in rights
      attributes['actions'].each_index do |index|
        unless attributes['actions'][index].match(/\:\:/)
          attributes['actions'][index] = attributes['controller'].to_s+"::"+attributes['actions'][index] 
        end
      end if attributes['actions'].is_a? Array
    end
    rights_list  = rights.keys.sort
    actions_list = rights.values.collect{|x| x["actions"]||[]}.flatten.uniq.sort

    # Ajout des nouvelles actions
    created = 0
    for controller, actions in ref
      for action in actions
        uniq_action = controller+"::"+action
        unless actions_list.include?(uniq_action)
          rights[new_right] ||= {}
          rights[new_right]["actions"] ||= []
          rights[new_right]["actions"] << uniq_action
          created += 1
        end
      end
    end

    # Commentaire des actions supprimées
    deleted = 0
    for right, attributes in rights
      attributes['actions'].each_index do |index|
        uniq_action = attributes["actions"][index]
        controller, action = uniq_action.split(/\W+/)[0..1]
        unless ref[controller].include?(action)
          attributes["actions"][index] += " # UNEXISTENT ACTION !!!"
          deleted += 1
        end
      end if attributes['actions'].is_a?(Array)
    end

    # Enregistrement du nouveau fichier
    code = ""
    for right in rights.keys.sort
      code += "# #{::I18n.translate('rights.'+right.to_s)}\n"
      code += "#{right}:\n"
      controller, actions = rights[right]['controller'], []
      code += "  controller: #{controller}\n" unless controller.blank?
      if rights[right]["actions"].is_a?(Array)
        actions = rights[right]['actions'].sort
        actions = actions.collect{|x| x.match(/^#{controller}\:\:/) ? x.split('::')[1] : x}.sort unless controller.blank?
        line = "  actions: [#{actions.join(', ')}]"
        if line.length > 80 or line.match(/\#/)
          code += "  actions:\n"
          for action in actions
            code += "  - #{action}\n"
          end
        else
          code += line+"\n"
        end
      end
    end
    File.open(User.rights_file, "wb") do |file|
      file.write code
    end

    puts " - Rights: #{deleted} deleted actions, #{created} created actions"
  end



  desc "Update and sort translation files"
  task :locales => :environment do
    log = File.open("#{RAILS_ROOT}/config/locales/translations.log", "wb")

    # Load of actions
    all_actions = {}
    for right, attributes in YAML.load_file(User.rights_file)
      for full_action in attributes['actions']
        controller, action = (full_action.match(/\:\:/) ? full_action.split(/\W+/)[0..1] : [attributes['controller'].to_s, full_action])
        all_actions[controller] ||= []
        all_actions[controller] << action unless action.match /dy(li|ta)|delete/
      end if attributes['actions'].is_a? Array
    end
    all_actions.delete("authentication")
    all_actions.delete("help")

    locale = ::I18n.locale = ::I18n.default_locale
    locale_dir = "#{RAILS_ROOT}/config/locales/#{locale}"
    File.makedirs(locale_dir) unless File.makedirs(locale_dir)
    File.makedirs(locale_dir+"/help") unless File.makedirs(locale_dir+"/help")
    log.write("- Locale #{::I18n.locale_label}:\n")

    # Activerecord
    models = Dir["#{RAILS_ROOT}/app/models/*.rb"].collect{|m| m.split(/[\\\/\.]+/)[-2]}.sort
    default_attributes = ::I18n.translate("activerecord.default_attributes")
    models_names, plurals_names, models_attributes = '', '', ''
    attrs_count, static_attrs_count = 0, 0
    for model in models
      class_name = model.sub(/\.rb$/,'').camelize
      klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
      if klass < ActiveRecord::Base && !klass.abstract_class?
        models_names  += "      #{model}: "+::I18n.pretranslate("activerecord.models.#{model}")+"\n"
        plurals_names += "      #{model}: "+::I18n.pretranslate("activerecord.models_plurals.#{model}")+"\n"
        models_attributes += "\n      # #{::I18n.t("activerecord.models.#{model}")}\n"
        models_attributes += "      #{model}:\n"
        attributes = {}
        for k, v in ::I18n.translate("activerecord.attributes.#{model}")||{}
          attributes[k] = "'"+v.gsub("'","''")+"'" if v
        end
        static_attrs_count += klass.columns.size
        for column in klass.columns
          attribute = column.name.to_sym
          trans = default_attributes[attribute]
          pretrans = ::I18n.pretranslate("activerecord.attributes.#{model}.#{attribute}")
          if trans.nil? and pretrans.match(/^\(\(\(/)
            trans = attribute.to_s[0..-4].classify.constantize.human_name rescue nil
          end
          trans = trans.nil? ? pretrans : "'"+trans.gsub("'","''")+"'"
          attributes[attribute] = trans
        end
        # Add reflections in attributes
        #raise Exception.new klass.reflections.inspect
        for reflection, details in klass.reflections
          attribute = reflection.to_sym
          trans   = ::I18n.hardtranslate("activerecord.attributes.#{model}.#{attribute}")
          trans ||= ::I18n.hardtranslate("activerecord.attributes.#{model}.#{attribute}_id")
          trans ||= ::I18n.hardtranslate("activerecord.models_plurals.#{attribute.to_s.singularize}")
          trans ||= ::I18n.hardtranslate("activerecord.models_plurals.#{model}_#{attribute.to_s.singularize}")
          attributes[attribute] = (trans.nil? ? "(((#{attribute.to_s.upper})))" : "'"+trans.gsub("'","''")+"'")
        end
        for x in [:creator, :updater]
          attributes[x] ||= "'"+default_attributes[x].gsub("'","''")+"'"
        end

        # Sort attributes and build yaml
        for attribute, trans in attributes.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
          models_attributes += "        #{attribute}: "+trans+"\n"
        end
        attrs_count += attributes.size
      else
        # puts "Skipping #{class_name}"
      end
    end
    activerecord = ::I18n.translate('activerecord').delete_if{|k,v| k.to_s.match(/^models|attributes$/)}
    translation  = locale.to_s+":\n"
    translation += "  activerecord:\n"
    translation += hash_to_yaml(activerecord, 2)
    translation += "\n    models:\n"
    translation += models_names
    translation += "\n    models_plurals:\n"
    translation += plurals_names
    translation += "\n    default_attributes:\n"
    translation += hash_to_yaml(default_attributes, 3)
    translation += "\n    attributes:\n"
    translation += models_attributes
    File.open("#{RAILS_ROOT}/config/locales/#{locale}/activerecord.yml", "wb") do |file|
      file.write translation
    end
    log.write "  - Models (#{models.size}, #{static_attrs_count} static attributes, #{attrs_count-static_attrs_count} virtual attributes, #{(attrs_count.to_f/models.size).round(1)} attributes/models)\n"

    # Packs
    controllers = Dir["#{RAILS_ROOT}/app/controllers/*.rb"].collect{|m| m.split(/[\\\/\.]+/)[-2]}.sort
    for controller in controllers
      controller_name = controller.split("_")[0..-2]
      translation  = locale.to_s+":\n"
      for part in [:controllers, :helpers, :views] 
        translation += "\n  #{part}:\n"
        translation += "    #{controller_name}:\n"
        translation += hash_to_yaml(::I18n.translate("#{part}.#{controller_name}"),3)
      end
      File.open("#{RAILS_ROOT}/config/locales/#{locale}/pack.#{controller_name}.yml", "wb") do |file|
        file.write translation
      end
    end
    log.write "  - Packs (#{controllers.size})\n"

    # Parameters
    translation  = locale.to_s+":\n"
    translation += "  parameters:\n"
    translation += hash_to_yaml(::I18n.translate("parameters"), 2)
    File.open("#{RAILS_ROOT}/config/locales/#{locale}/parameters.yml", "wb") do |file|
      file.write(translation)
    end
    log.write "  - Parameters\n"
    
    # Notifications
    notifications = ::I18n.t("notifications")
    deleted_notifs = ::I18n.t("notifications").keys
    for controller in Dir["#{RAILS_ROOT}/app/controllers/*.rb"]
      file = File.open(controller, "r")
      file.each_line do |line|
        if line.match(/([\s\W]+|^)notify\(\s*\:\w+/)
          key = line.split(/notify\(\s*\:/)[1].split(/\W/)[0]
          deleted_notifs.delete(key.to_sym)
          notifications[key.to_sym] = "" if notifications[key.to_sym].nil? or notifications[key.to_sym].match(/\(\(\(/)
        end
      end
    end
    File.open("#{RAILS_ROOT}/config/locales/#{locale}/notifications.yml", "wb") do |file|
      file.write locale.to_s+":\n"
      file.write "  notifications:\n"
      for key, translation in notifications.sort{|a,b| a[0].to_s<=>b[0].to_s}
        file.write "    #{key}: #{translation.blank? ? '((('+key.to_s.upper+')))' : '\''+translation.gsub(/\'/, '\'\'')+'\''} #{deleted_notifs.include?(key) ? '# NOT USED !!!' : ''}\n"
      end
    end
    log.write "  - Notifications (#{notifications.size}, #{deleted_notifs.size} bad notifications)\n"

    # Rights
    rights = YAML.load_file(User.rights_file)
    translation  = locale.to_s+":\n"
    translation += "  rights:\n"
    for right in rights.keys.sort
      translation += "    #{right}: "+::I18n.pretranslate("rights.#{right}")+"\n"
    end
    File.open("#{RAILS_ROOT}/config/locales/#{locale}/rights.yml", "wb") do |file|
      file.write translation
    end
    log.write "  - Rights (#{rights.keys.size})\n"

    log.write "  - help: # Missing files\n"
    for controller, actions in all_actions
      for action in actions
        if File.exists?("#{RAILS_ROOT}/app/views/#{controller}/#{action}.html.haml") or (File.exists?("#{RAILS_ROOT}/app/views/#{controller}/_#{action.gsub(/_[^_]*$/,'')}_form.html.haml") and action.split("_")[-1].match(/create|update/))
          help = "#{RAILS_ROOT}/config/locales/#{locale}/help/#{controller}-#{action}.txt"
          log.write "    - #{help.gsub(RAILS_ROOT,'.')}\n" unless File.exists?(help)
        end
      end
    end
    
    puts " - Locale: #{::I18n.locale_label} (Default)"




    for locale in ::I18n.available_locales.delete_if{|l| l==::I18n.default_locale or l.to_s.size!=3}.sort{|a,b| a.to_s<=>b.to_s}
      ::I18n.locale = locale
      locale_dir = "#{RAILS_ROOT}/config/locales/#{locale}"
      File.makedirs(locale_dir) unless File.makedirs(locale_dir)
      File.makedirs(locale_dir+"/help") unless File.makedirs(locale_dir+"/help")
      log.write "- Locale #{::I18n.locale_label}:\n"
      total, count = 0, 0
      for reference_path in Dir.glob("#{RAILS_ROOT}/config/locales/#{::I18n.default_locale}/*.yml").sort
        file_name = reference_path.split(/[\/\\]+/)[-1]
        target_path = "#{RAILS_ROOT}/config/locales/#{locale}/#{file_name}"
        unless File.exist?(target_path)
          File.open(target_path, "wb") do |file|
            file.write("#{locale}:\n")
          end
        end
        target = yaml_to_hash(target_path)
        reference = yaml_to_hash(reference_path)
        translation, scount, stotal = hash_diff(target[locale], reference[::I18n.default_locale], 1)
        count += scount
        total += stotal
        log.write "  - #{file_name}: #{(100*(stotal-scount)/stotal).round}% (#{stotal-scount}/#{stotal})\n"
        File.open(target_path, "wb") do |file|
          file.write("#{locale}:\n")
          file.write(translation)
        end
      end
      log.write "  - total: #{(100*(total-count)/total).round}% (#{total-count}/#{total}) done.\n"
      # Missing help files
      log.write "  - help: # Missing files\n"
      for controller, actions in all_actions
        for action in actions
          if File.exists?("#{RAILS_ROOT}/app/views/#{controller}/#{action}.html.haml") or (File.exists?("#{RAILS_ROOT}/app/views/#{controller}/_#{action.gsub(/_[^_]*$/,'')}_form.html.haml") and action.split("_")[-1].match(/create|update/))
            help = "#{RAILS_ROOT}/config/locales/#{locale}/help/#{controller}-#{action}.txt"
            log.write "    - #{help.gsub(RAILS_ROOT,'.')}\n" unless File.exists?(help)
          end
        end
      end
      puts " - Locale: #{::I18n.locale_label} #{(100*(total-count)/total).round}% translated"
    end

    log.close
    

  end
  

  desc "Clean all files as possible"
  task :all => [:environment, :rights, :models, :locales]

  
end
