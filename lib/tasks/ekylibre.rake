def hash_to_yaml(hash, depth=0)
  code = ''
  for k, v in hash.to_a.sort{|a,b| a[0].to_s.gsub("_"," ").strip<=>b[0].to_s.gsub("_"," ").strip}
    code += "  "*depth+k.to_s+":"+(v.is_a?(Hash) ? "\n"+hash_to_yaml(v,depth+1) : " '"+v.gsub("'", "''")+"'\n") if v
  end
  code
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

desc "Create public/stylesheets/dyta-colors.css"
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

  File.open("#{RAILS_ROOT}/public/stylesheets/dyta-colors.css", "wb") do |f|
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
    puts "#{errors} errors"
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
    new_right = '[new_right]'

    # Chargement des actions des controllers
    ref = {}
    Dir.glob("#{RAILS_ROOT}/app/controllers/*_controller.rb") do |x|
      controller_name = x.split("/")[-1].split("_controller")[0]
      actions = []
      file = File.open(x, "r")
      file.each_line do |line|
        line = line.gsub(/(^\s*|\s*$)/,'')
        actions << line.split(/def\s/)[1].gsub(/\s/,'') if line.match(/^\s*def\s+\w+\s*$/)
        # actions << line.gsub(/\s/,'').gsub(/\(?:/,"_").split(/(\,|\))/)[0] if line.match(/^\s*dy(ta|li)[\s\(]+\:\w+/)
        if line.match(/^\s*dy(li|ta)[\s\(]+\:\w+/)
          dyxx = line.split(/[\s\(\)\,\:]+/)
          actions << dyxx[1]+'_'+dyxx[0]
        end
        if line.match(/^\s*manage[\s\(]+\:\w+/)
          prefix = line.split(/[\s\(\)\,\:]+/)[1].singularize
          actions << prefix+'_create'
          actions << prefix+'_update'
          actions << prefix+'_delete'
        end
      end
      ref[controller_name] = actions
    end

    # Lecture du fichier existant
    file = File.open(User.rights_file, "rb")
    rights = []
    file.each_line do |line|
      unless line.match(/\<\<\<|\=\=\=|\>\>\>/)
        right = line.strip.split(/[\:\t\,\;\s]+/).collect{|x| x.strip.lower}
        right[2] = new_right if right.size==2
        rights << right if right.size==3
      end
    end
    file.close

    # Mise en commentaire des actions supprimées
    deleted = 0
    for right in rights
      if right[1].to_s.match(/_dy(ta|li)$/)
        on = right[1].gsub(/^(.*)_(dy(ta|li))$/,'\2_\1')
        r = rights.detect{|x| x[1]==on}
        right[2] = r[2] if r
      end
      unless right[0].match(/^\#/)
        unless ref[right[0]].include?(right[1])
          right[0] = '#'+right[0] 
          deleted += 1
        end
      end
    end

    # Ajout des nouvelles actions
    created = 0
    for controller_name, actions in ref
      for a in actions
        unless rights.select{|r| r[0].gsub(/(\#|\s)/,'')==controller_name and r[1]==a}.size>0
          rights << [controller_name, a, new_right] 
          created += 1
        end
      end
    end

    # Droits non définis et doublons
    to_update = 0
    doubles = 0
    rights.size.times do |i|
      unless rights[i][0].match(/\#/)
        if File.exists?("#{RAILS_ROOT}/app/views/#{rights[i][0]}/#{rights[i][1]}.html.haml") or (File.exists?("#{RAILS_ROOT}/app/views/#{rights[i][0]}/_#{rights[i][1].split("_")[0..-2].join('_')}_form.html.haml") and rights[i][1].split("_")[-1].match(/create|update/))
          help = "#{RAILS_ROOT}/config/locales/#{::I18n.locale}/help/#{rights[i][0]}-#{rights[i][1]}.txt"
          puts "Help file missing: #{help}" unless File.exists?(help) or rights[i][1].match /dy(li|ta)|delete/ or rights[i][0].match /authentication|help/
        end
        to_update += 1 if rights[i][2].to_s.match(/^\w+$/).nil?
        for j in i+1..rights.size-1
          if rights[i][0]==rights[j][0] and rights[i][1]==rights[j][1]
            rights[j][0] = '# '+rights[j][0] 
            doubles += 1
          end
        end
      end
    end

    # Tri
    rights.sort!{|a, b| a[0]+':'+a[2]+':'+a[1]<=>b[0]+':'+b[2]+':'+b[1]}

    # Enregistrement du nouveau fichier
    file = File.open(User.rights_file, "wb") 
    max = []
    rights.each do |right|
      3.times { |i| max[i] = right[i].length if right[i].length>max[i].to_i }
    end
    max[0] = 16
    max[1] = 32
    file.write rights.collect{|x| [0,1,2].collect{|i| x[i].ljust(max[i])}.join(" ").strip}.join("\n")
    file.close

    # Fichier de traduction
    rights_list = rights.collect{|r| r[2].to_s if r[2].match(/^\w+$/) and not r[0].match(/\#/)}.compact.uniq.sort
    translation  = ::I18n.locale.to_s+":\n"
    translation += "  rights:\n"
    for right in rights_list
      translation += "    #{right}: "+::I18n.pretranslate("rights.#{right}")+"\n"
    end
    File.open("#{RAILS_ROOT}/config/locales/#{::I18n.locale}.rights.yml", "wb") do |file|
      file.write translation
    end

    puts "#{deleted} deleted actions, #{created} created actions, #{to_update} actions to update, #{doubles} doubles"
  end


  desc "Update and sort translation files"
  task :locales => :environment do
    classicals = {'fr-FR'=>{:company_id=>'Société', :id=>'ID', :lock_version=>'Version', :updated_at=>'Mis à jour le', :updater_id=>'Modificateur', :created_at=>'Créé le', :creator_id=>'Créateur', :comment=>'Commentaire', :position=>'Position', :name=>'Nom', :parent_id=>'Parent' } }
    models = Dir["#{RAILS_ROOT}/app/models/*.rb"].collect{|m| m.split(/[\\\/\.]+/)[-2]}.sort
    models_names = ''
    models_attributes = ""
    attrs_count, static_attrs_count = 0, 0
    for model in models
      class_name = model.sub(/\.rb$/,'').camelize
      klass = class_name.split('::').inject(Object){ |klass,part| klass.const_get(part) }
      if klass < ActiveRecord::Base && !klass.abstract_class?
        models_names += "      #{model}: "+::I18n.pretranslate("activerecord.models.#{model}")+"\n"
        models_attributes += "\n      # #{::I18n.t("activerecord.models.#{model}")}\n"
        models_attributes += "      #{model}:\n"
        attributes = {}
        for k, v in ::I18n.translate("activerecord.attributes.#{model}")||{}
          attributes[k] = "'"+v.gsub("'","''")+"'" if v
        end
        static_attrs_count += model.camelcase.constantize.columns.size
        for column in model.camelcase.constantize.columns
          attribute = column.name.to_sym
          trans = classicals[::I18n.locale.to_s][attribute]
          pretrans = ::I18n.pretranslate("activerecord.attributes.#{model}.#{attribute}")
          if trans.nil? and pretrans.match(/^\(\(\(/)
            trans = attribute.to_s[0..-4].classify.constantize.human_name rescue nil
          end
          trans = trans.nil? ? pretrans : "'"+trans.gsub("'","''")+"'"
          attributes[attribute] = trans
        end
        # raise Exception.new attributes.inspect
        for attribute, trans in attributes.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
          models_attributes += "        #{attribute}: "+trans+"\n"
        end
        attrs_count += attributes.size
      else
        puts "Skipping #{class_name}"
      end
    end
    activerecord = ::I18n.translate('activerecord').delete_if{|k,v| k.to_s.match(/^models|attributes$/)}
    translation  = ::I18n.locale.to_s+":\n"
    translation += "  activerecord:\n"
    translation += hash_to_yaml(activerecord,2)
    translation += "\n    models:\n"
    translation += models_names
    translation += "\n    attributes:\n"
    translation += models_attributes
    File.open("#{RAILS_ROOT}/config/locales/#{::I18n.locale}.activerecord.yml", "wb") do |file|
      file.write translation
    end

    puts "#{models.size} models, #{static_attrs_count} static attributes, #{attrs_count-static_attrs_count} virtual attributes, #{(attrs_count.to_f/models.size).round(1)} attributes/models"

    controllers = Dir["#{RAILS_ROOT}/app/controllers/*.rb"].collect{|m| m.split(/[\\\/\.]+/)[-2]}.sort
    for controller in controllers
      controller_name = controller.split("_")[0..-2]
      translation  = ::I18n.locale.to_s+":\n"
      for part in [:controllers, :helpers, :views] 
        translation += "\n  #{part}:\n"
        translation += "    #{controller_name}:\n"
        translation += hash_to_yaml(::I18n.translate("#{part}.#{controller_name}"),3)
      end
      File.open("#{RAILS_ROOT}/config/locales/#{::I18n.locale}.pack.#{controller_name}.yml", "wb") do |file|
        file.write translation
      end
    end

    puts "#{controllers.size} controllers"

  end
  

  desc "Clean all files as possible"
  task :all => [:environment, :rights, :locales, :models]


#   desc "Zip test"
#   task :zip => [:environment] do
#     Zip::ZipFile.open("#{RAILS_ROOT}/my.zip", Zip::ZipFile::CREATE) do |zipfile|
#       zipfile.get_output_stream("backup.xml") { |f| f.puts "Hello from ZipFile" }
#       Dir.chdir("#{RAILS_ROOT}/private/NERV") do
#         for file in Dir["*/*/*.pdf"]
#           zipfile.add("prints/"+file,"#{RAILS_ROOT}/private/NERV/#{file}")
#         end
#       end
#     end
#   end
  
end
