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
  # for right, attributes in rights
  #   raise "Right :#{right} must have attributes like :actions" unless attributes
  #   attributes['actions'].each_index do |index|
  #     unless attributes['actions'][index].match(/\#/)
  #       attributes['actions'][index] = attributes['controller'].to_s+"#"+attributes['actions'][index]
  #     end
  #   end if attributes['actions'].is_a? Array
  #   attributes['controller'] = nil unless ref.keys.include?(attributes['controller'])
  # end
  rights_list  = rights.keys.sort
  actions_list = rights.values.flatten.compact.uniq.sort

  # Search unused actions
  unused_actions = []
  for controller, actions in ref
    for action in actions
      uniq_action = controller + "#" + action
      unused_actions << uniq_action unless actions_list.include?(uniq_action)
    end
  end

  # Commentaire des actions supprimées
  deleted = 0
  unexistent_actions = []
  for right, actions in rights
    actions.each_with_index do |uniq_action, index|
      controller, action = uniq_action.split(/\#/)[0..1]
      unless ref[controller].is_a?(Array) and ref[controller].include?(action)
        unexistent_actions << uniq_action
        deleted += 1
      end
    end if actions.is_a?(Array)
  end

  # Enregistrement du nouveau fichier
  yaml = ""
  yaml << "# Unused actions in rights\n" unless unused_actions.empty?
  for action in unused_actions.sort
    yaml << "# - \"#{action}\"\n"
  end
  for right in rights.keys.sort
    yaml << "\n"
    yaml << "# #{::I18n.translate('rights.'+right.to_s, :locale => :eng)}\n"
    yaml << "#{right}:\n"
    if rights[right].is_a?(Array) and !rights[right].empty?
      for action in rights[right].uniq.sort
        yaml << "- \"#{action}\""
        yaml << " #?" if unexistent_actions.include?(action)
        yaml << "\n"
      end
    end
  end
  File.open(User.rights_file, "wb") do |file|
    file.write yaml
  end

  print "#{unused_actions.size.to_s.rjust(3)} unused actions, #{deleted.to_s.rjust(3)} deletable actions\n"
end
