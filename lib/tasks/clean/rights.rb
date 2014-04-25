# -*- coding: utf-8 -*-
#
desc "Update and sort rights.yml"
task :rights => :environment do
  print " - Rights:  "

  # Load list of all actions of all controllers
  ref = Clean::Support.actions_hash

  # Lecture du fichier existant
  old_rights = YAML.load_file(Ekylibre::Access.reference_file)

  read_exp =  /\#(list(\_\w+)*|index|show|unroll|picture)$/

  rights = {}
  for item in Nomen::EnterpriseResources.list.sort
    rights[item.name] ||= {}
    for access in item.accesses.map(&:to_s)
      old_rights[item.name] ||= {}
      old_rights[item.name][access] ||= {}
      rights[item.name][access] ||= {}
      rights[item.name][access]["depend-on"] = old_rights[item.name][access]["depend-on"] || (access == "read" ? [] : ["read-#{item.name}"])
      actions = (ref["backend/#{item.name}"] || []).collect{|a| "backend/#{item.name}##{a}"}
      read_actions = actions.select{|x| x.to_s =~ read_exp}
      rights[item.name][access]["actions"] = old_rights[item.name][access]["actions"] || (actions.nil? ? [] : (access == "read") ? read_actions : (actions - read_actions))
    end
  end

  all_actions  = ref.collect{|c,l| l.collect{|a| "#{c}##{a}"}}.flatten.compact.uniq.sort
  used_actions = rights.values.collect{|h| h.values.collect{|v| v["actions"]}}.flatten.compact.uniq.sort
  unused_actions     = all_actions - used_actions
  unexistent_actions = used_actions - all_actions
  
  # Enregistrement du nouveau fichier
  yaml = ""
  if unused_actions.any?
    yaml << "# THESE COMMENTED ACTIONS ARE ALL ACCESSIBLE AFTER LOGIN WITHOUT RESTRICTION\n" 
    for action in unused_actions.sort
      yaml << "#     - \"#{action}\"\n"
    end
  end
  for resource, accesses in rights
    yaml << "\n"
    yaml << "#{resource}:\n"
    for access, details in accesses
      next unless details["depend-on"].any? or details["actions"].any?
      yaml << "  #{access}:\n"
      if details["depend-on"].any?
        yaml << "    depend-on:\n"
        for dependency in details["depend-on"].sort
          yaml << "    - #{dependency}\n"
        end
      end
      if details["actions"].any?
        yaml << "    actions:\n"
        for action in details["actions"].sort
          yaml << "    - \"#{action}\""
          yaml << " #?" if unexistent_actions.include?(action)
          yaml << "\n"
        end
      end
    end
  end

  File.open(Ekylibre::Access.reference_file, "wb") do |file|
    file.write yaml
  end

  print "#{unused_actions.size.to_s.rjust(3)} unused actions, #{unexistent_actions.size.to_s.rjust(3)} deletable actions\n"
end
