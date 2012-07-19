# -*- coding: utf-8 -*-
#
desc "Update and sort rights.yml"
task :rights => :environment do
  print " - Rights: "
  # new_right = '__not_used__'

  # Load list of all actions of all controllers
  ref = actions_hash

  # Lecture du fichier existant
  rights = YAML.load_file(User.rights_file)

  # Expand actions
  for right, attributes in rights
    raise "Right :#{right} must have attributes like :actions" unless attributes
    attributes['actions'].each_index do |index|
      unless attributes['actions'][index].match(/\:\:/)
        attributes['actions'][index] = attributes['controller'].to_s+"::"+attributes['actions'][index] 
      end
    end if attributes['actions'].is_a? Array
    attributes['controller'] = nil unless ref.keys.include?(attributes['controller'])
  end
  rights_list  = rights.keys.sort
  actions_list = rights.values.collect{|x| x["actions"]||[]}.flatten.uniq.sort

  # Search unused actions
  unused_actions = []
  for controller, actions in ref
    for action in actions
      uniq_action = controller+"::"+action
      unused_actions << uniq_action unless actions_list.include?(uniq_action)
    end
  end

  # Commentaire des actions supprimées
  deleted = 0
  for right, attributes in rights
    attributes['actions'].each_index do |index|
      uniq_action = attributes["actions"][index]
      controller, action = uniq_action.split(/\W+/)[0..1]
      unless ref[controller].is_a?(Array) and ref[controller].include?(action)
        attributes["actions"][index] += " # NONEXISTENT ACTION !!!"
        deleted += 1
      end
    end if attributes['actions'].is_a?(Array)
  end

  # Enregistrement du nouveau fichier
  yaml = ""
  yaml += "# Unused actions in rights\n" unless unused_actions.empty?
  for action in unused_actions.sort
    yaml += "#   - #{action}\n"
  end
  for right in rights.keys.sort
    yaml += "# #{::I18n.translate('rights.'+right.to_s)}\n"
    yaml += "#{right}:\n"
    # yaml += "#{right}: # #{::I18n.translate('rights.'+right.to_s)}\n"
    controller, actions = rights[right]['controller'], []
    yaml += "  controller: #{controller}\n" unless controller.blank?
    if rights[right]["actions"].is_a?(Array)
      actions = rights[right]['actions'].sort
      actions = actions.collect{|x| x.match(/^#{controller}\:\:/) ? x.split('::')[1] : x}.sort unless controller.blank?
      line = "  actions: [#{actions.join(', ')}]"
      if line.length > 0 or line.match(/\#/)
        # if line.match(/\#/)
        yaml += "  actions:\n"
        for action in actions
          yaml += "  - #{action}\n"
        end
      else
        yaml += line+"\n"
      end
    end
  end
  File.open(User.rights_file, "wb") do |file|
    file.write yaml
  end

  print "#{unused_actions.size.to_s.rjust(3)} unused actions, #{deleted.to_s.rjust(3)} deletable actions\n"
end
