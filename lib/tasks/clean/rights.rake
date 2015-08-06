namespace :clean do
  desc 'Update and sort rights.yml'
  task rights: :environment do
    print ' - Rights:  '

    # Load list of all actions of all controllers
    ref = Clean::Support.actions_hash

    # Lecture du fichier existant
    old_rights = YAML.load_file(Ekylibre::Access.config_file).deep_symbolize_keys

    read_exp = /\#(list(\_\w+)*|index|show|unroll|picture)$/

    rights = {}
    for resource, interactions in Ekylibre::Access.resources.sort
      rights[resource] ||= {}
      for access in interactions.keys
        old_rights[resource] ||= {}
        old_rights[resource][access] ||= {}
        rights[resource][access] ||= {}
        rights[resource][access][:dependencies] = old_rights[resource][access][:dependencies] || (access == :read ? [] : ["read-#{resource}"])
        actions = (ref["backend/#{resource}"] || []).collect { |a| "backend/#{resource}##{a}" }
        read_actions = actions.select { |x| x.to_s =~ read_exp }
        rights[resource][access][:actions] = old_rights[resource][access][:actions] || (actions.nil? ? [] : (access == :read) ? read_actions : (actions - read_actions))
      end
    end

    all_actions  = ref.collect { |c, l| l.collect { |a| "#{c}##{a}" } }.flatten.compact.uniq.sort
    used_actions = rights.values.collect { |h| h.values.collect { |v| v[:actions] } }.flatten.compact.uniq.sort
    unused_actions     = all_actions - used_actions
    unexistent_actions = used_actions - all_actions

    # Enregistrement du nouveau fichier
    yaml = ''
    if unused_actions.any?
      yaml << "# THESE FOLLOWING ACTIONS ARE PUBLICLY ACCESSIBLE\n"
      for action in unused_actions.sort
        yaml << "#     - \"#{action}\"\n"
      end
    end
    for resource, accesses in rights
      yaml << "\n"
      yaml << "#{resource}:\n"
      for access, details in accesses
        next unless details[:dependencies].any? || details[:actions].any?
        yaml << "  #{access}:\n"
        if details[:dependencies].any?
          yaml << "    dependencies:\n"
          for dependency in details[:dependencies].sort
            yaml << "    - #{dependency}\n"
          end
        end
        if details[:actions].any?
          yaml << "    actions:\n"
          for action in details[:actions].sort
            yaml << "    - \"#{action}\""
            yaml << ' #?' if unexistent_actions.include?(action)
            yaml << "\n"
          end
        end
      end
    end

    File.open(Ekylibre::Access.config_file, 'wb') do |file|
      file.write yaml
    end

    print "#{unused_actions.size.to_s.rjust(3)} public actions, #{unexistent_actions.size.to_s.rjust(3)} deletable actions\n"
  end
end
