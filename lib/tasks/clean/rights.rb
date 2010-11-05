#
desc "Update and sort rights list"
task :rights => :environment do
  print " - Rights: "
  new_right = '__not_used__'

  # Chargement des actions des controllers
  ref = {}
  Dir.glob(Ekylibre::Application.root.join("app", "controllers", "*_controller.rb")) do |x|
    controller_name = x.split("/")[-1].split("_controller")[0]
    ref[controller_name] = actions_in_file(x).sort
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
    # code += "#{right}: # #{::I18n.translate('rights.'+right.to_s)}\n"
    controller, actions = rights[right]['controller'], []
    code += "  controller: #{controller}\n" unless controller.blank?
    if rights[right]["actions"].is_a?(Array)
      actions = rights[right]['actions'].sort
      actions = actions.collect{|x| x.match(/^#{controller}\:\:/) ? x.split('::')[1] : x}.sort unless controller.blank?
      line = "  actions: [#{actions.join(', ')}]"
      if line.length > 80 or line.match(/\#/)
        # if line.match(/\#/)
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

  print "#{deleted} deletable actions, #{created} created actions\n"
end
