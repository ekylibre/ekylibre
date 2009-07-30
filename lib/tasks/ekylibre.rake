def hash_to_yaml(hash, depth=0)
  code = ''
  for k, v in hash.to_a.sort{|a,b| a[0].to_s.gsub("_"," ").strip<=>b[0].to_s.gsub("_"," ").strip}
    code += "  "*depth+k.to_s+":"+(v.is_a?(Hash) ? "\n"+hash_to_yaml(v,depth+1) : " '"+v.gsub("'", "''")+"'\n") if v
  end
  code
end

namespace :clean do

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
        actions << line.split(/def\s/)[1].gsub(/\s/,'') if line.match(/^\s*def\s+\w+\s*$/)
        actions << line.gsub(/\s/,'').gsub(/\(?:/,"_").split(/(\,|\))/)[0] if line.match(/^\s*dy(ta|li)[\s\(]+\:\w+/)
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
        if File.exists?("#{RAILS_ROOT}/app/views/#{rights[i][0]}/#{rights[i][1]}.html.haml") or (File.exists?("#{RAILS_ROOT}/app/views/#{rights[i][0]}/_#{rights[i][1].split("_")[0]}_form.html.haml") and rights[i][1].split("_")[-1].match(/create|update/))
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
    classicals = {'fr-FR'=>{:company_id=>'Société', :id=>'ID', :lock_version=>'Version', :updated_at=>'Mis à jour le', :updater_id=>'Modificateur', :created_at=>'Créé le', :creator_id=>'Créateur', :comment=>'Commentaire' } }
    models = Dir["#{RAILS_ROOT}/app/models/*.rb"].collect{|m| m.split(/[\\\/\.]+/)[-2]}.sort
    models_names = ''
    models_attributes = ""
    attrs_count, static_attrs_count = 0, 0
    for model in models
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
        trans = trans.nil? ? ::I18n.pretranslate("activerecord.attributes.#{model}.#{attribute}") : "'"+trans.gsub("'","''")+"'"
        attributes[attribute] = trans
      end
      # raise Exception.new attributes.inspect
      for attribute, trans in attributes.to_a.sort{|a,b| a[0].to_s<=>b[0].to_s}
        models_attributes += "        #{attribute}: "+trans+"\n"
      end
      attrs_count += attributes.size
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
  task :all => [:environment, :rights, :locales]


  desc "Zip test"
  task :zip => [:environment] do
    Zip::ZipFile.open("#{RAILS_ROOT}/my.zip", Zip::ZipFile::CREATE) do |zipfile|
      zipfile.get_output_stream("backup.xml") { |f| f.puts "Hello from ZipFile" }
      Dir.chdir("#{RAILS_ROOT}/private/NERV") do
        for file in Dir["*/*/*.pdf"]
          zipfile.add("prints/"+file,"#{RAILS_ROOT}/private/NERV/#{file}")
        end
      end
    end
  end
  
end
