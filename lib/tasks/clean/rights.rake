namespace :clean do
  desc 'Update and sort rights.yml'
  task rights: :environment do
    print ' - Rights:  '

    # Load list of all actions of all controllers
    ref = Clean::Support.actions_hash

    # Reading of existing file
    old_rights = YAML.load_file(Ekylibre::Access.config_file).deep_symbolize_keys

    read_exp = /\#(list(\_\w+)*|index|show|unroll|picture)$/

    rights = {}
    Ekylibre::Access.resources.sort.each do |resource, interactions|
      rights[resource] ||= {}
      interactions.keys.each do |access|
        old_rights[resource] ||= {}
        old_rights[resource][access] ||= {}
        rights[resource][access] ||= {}
        rights[resource][access][:dependencies] = old_rights[resource][access][:dependencies] || (access == :read ? [] : ["read-#{resource}"])
        rights[resource][access][:deprecated] = true if old_rights[resource][access][:deprecated]
        actions = (ref["backend/#{resource}"] || []).collect { |a| "backend/#{resource}##{a}" }
        read_actions = actions.select { |x| x.to_s =~ read_exp }
        rights[resource][access][:actions] = old_rights[resource][access][:actions] || (actions.nil? ? [] : access == :read ? read_actions : (actions - read_actions))
      end
    end

    all_actions  = ref.collect { |c, l| l.collect { |a| "#{c}##{a}" } }.flatten.compact.uniq.sort
    used_actions = rights.values.collect { |h| h.values.collect { |v| v[:actions] } }.flatten.compact.uniq.sort
    unused_actions     = all_actions - used_actions
    unexistent_actions = used_actions - all_actions

    # Writing of new file
    yaml = ''
    if unused_actions.any?
      yaml << "# THESE FOLLOWING ACTIONS ARE PUBLICLY ACCESSIBLE\n"
      unused_actions.sort.each do |action|
        yaml << "#     - \"#{action}\"\n"
      end
    end
    rights.each do |resource, accesses|
      yaml << "\n"
      yaml << "#{resource}:\n"
      accesses.each do |access, details|
        next unless details[:dependencies].any? || details[:actions].any?
        yaml << "  #{access}:\n"
        yaml << "    deprecated: true\n" if details[:deprecated]
        if details[:dependencies].any?
          yaml << "    dependencies:\n"
          details[:dependencies].sort.each do |dependency|
            yaml << "    - #{dependency}\n"
          end
        end
        next unless details[:actions].any?
        yaml << "    actions:\n"
        details[:actions].sort.each do |action|
          yaml << "    - \"#{action}\""
          yaml << ' #?' if unexistent_actions.include?(action)
          yaml << "\n"
        end
      end
    end

    File.open(Ekylibre::Access.config_file, 'wb') do |file|
      file.write yaml
    end

    print "#{unused_actions.size.to_s.rjust(3)} public actions, #{unexistent_actions.size.to_s.rjust(3)} deletable actions\n"
  end
end
