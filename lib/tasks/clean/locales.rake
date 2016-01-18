namespace :clean do
  desc 'Update and sort translation files'
  task locales: :environment do
    Clean::Support.set_search_path!

    # needed_labels = Clean::Support.look_for_labels("{app,lib}/**/*.{rb,yml,haml,erb}", "tmp/code/**/*{rb,yml,haml,erb}")
    # puts needed_labels.to_sentence.yellow
    # puts needed_labels.size.to_s.red
    # # raise "Stop"

    stats = {}

    log = File.open(Rails.root.join('log', 'clean-locales.log'), 'wb')

    missing_prompt = '# '

    watched_files = '{app,config,db,lib,test}/**/*.{rb,haml,erb}'

    locale = ::I18n.locale = ::I18n.default_locale
    locale_dir = Rails.root.join('config', 'locales', locale.to_s)
    FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
    for directory in %w(help reporting) # , "profiles"
      FileUtils.makedirs(locale_dir.join(directory)) unless File.exist?(locale_dir.join(directory))
    end
    log.write("Locale #{::I18n.locale_label}:\n")

    acount = atotal = 0

    # Access
    file = locale_dir.join('access.yml')
    ref = begin
            Clean::Support.yaml_to_hash(file)[locale]
          rescue
            {}
          end
    to_translate = 0
    untranslated = 0

    translation  = "#{locale}:\n"
    translation << "  access:\n"
    translation << "    interactions:\n"
    ref[:access] ||= {}
    ref[:access][:interactions] ||= {}
    Ekylibre::Access.interactions.each do |interaction|
      to_translate += 1
      if name = ref[:access][:interactions][interaction]
        translation << "      #{interaction}: " + Clean::Support.yaml_value(name) + "\n"
      else
        translation << "      #{missing_prompt}#{interaction}: " + Clean::Support.yaml_value(interaction.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    translation << "    resources:\n"
    ref[:access] ||= {}
    ref[:access][:resources] ||= {}
    Ekylibre::Access.resources.keys.each do |resource|
      to_translate += 1
      if name = ref[:access][:resources][resource]
        translation << "      #{resource}: " + Clean::Support.yaml_value(name) + "\n"
      else
        translation << "      #{missing_prompt}#{resource}: " + Clean::Support.yaml_value(resource.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    total = to_translate
    log.write "  - #{'access.yml:'.ljust(20)} #{(100 * (total - untranslated) / total).round.to_s.rjust(3)}% (#{total - untranslated}/#{total})\n"
    atotal += to_translate
    acount += total - untranslated

    File.open(file, 'wb') do |file|
      file.write(translation)
    end

    untranslated = to_translate = translated = 0
    warnings = []
    translation = "#{locale}:\n"

    # Actions
    translation << "  actions:\n"
    # raise controllers_hash.inspect
    for controller_path, actions in Clean::Support.actions_hash
      existing_actions = begin
                           ::I18n.translate("actions.#{controller_path}").stringify_keys.keys
                         rescue
                           []
                         end
      translateable_actions = []
      translateable_actions += (actions.delete_if { |a| [:update, :create, :picture, :destroy, :up, :down, :decrement, :increment, :duplicate, :reflect].include?(a.to_sym) || a.to_s.match(/^(list|unroll)(\_|$)/) } | existing_actions).sort
      next unless translateable_actions.any?
      translation << '    ' + controller_path + ":\n"
      for action_name in translateable_actions
        name = ::I18n.hardtranslate("actions.#{controller_path}.#{action_name}")
        to_translate += 1
        untranslated += 1 if actions.include?(action_name) && name.blank?
        translation << "      #{missing_prompt if name.blank?}#{action_name}: " + Clean::Support.yaml_value(name.blank? ? Clean::Support.default_action_title(controller_path, action_name) : name, 3)
        translation << ' #?' unless actions.include?(action_name)
        translation << "\n"
      end
    end

    # Errors
    to_translate += Clean::Support.hash_count(::I18n.translate('errors'))
    translation << '  errors:' + Clean::Support.hash_to_yaml(::I18n.translate('errors'), 2) + "\n"

    # Labels
    translation << "  labels:\n"
    labels = ::I18n.t('labels')
    needed_labels = Clean::Support.look_for_labels(watched_files).inject({}) do |hash, string|
      hash[Regexp.new('\A' + string.split('.').first.gsub('*', '([\w\_]+)') + '\z')] = string.split('.').first
      hash
    end
    unknown_labels = labels.keys
    new_labels = []
    for regexp, string in needed_labels
      unless string =~ /\*/ || labels.key?(string.to_sym)
        labels[string.to_sym] = string.humanize
        new_labels << string.to_sym
      end
    end
    for label in labels.keys
      for regexp, string in needed_labels
        unknown_labels.delete(label) if regexp.match(label)
      end
    end
    to_translate += Clean::Support.hash_count(labels)
    # /(#{labels.keys.join('|')})/

    for key, trans in labels.sort { |a, b| a[0].to_s <=> b[0].to_s }
      line = '    '
      if new_labels.include? key
        untranslated += 1
        line << missing_prompt
      end
      line << "#{key}:" + (trans.is_a?(Hash) ? '' : ' ') + Clean::Support.yaml_value((trans.blank? ? key.to_s.humanize : trans), 2)
      if unknown_labels.include?(key)
        if Clean::Support.text_found?(/#{key}/, watched_files)
          line.gsub!(/\ *$/, ' #?')
        elsif Clean::Support.text_found?(/#{key.to_s.gsub('_', '.*')}/, watched_files)
          line.gsub!(/\ *$/, ' #??')
        else
          line.gsub!(/\ *$/, ' #?!')
        end
      end
      translation << line + "\n"
    end
    warnings << "#{unknown_labels.size} unknown labels" if unknown_labels.any?

    # Notifications
    translation << "  notifications:\n"
    to_translate += Clean::Support.hash_count(::I18n.translate('notifications.levels'))
    translation << '    levels:' + Clean::Support.hash_to_yaml(::I18n.translate('notifications.levels'), 3) + "\n"
    translation << "    messages:\n"
    notifications = ::I18n.t('notifications.messages')
    unknown_notifications = ::I18n.t('notifications.messages').keys
    for key in Clean::Support.look_for_notifications(watched_files)
      unknown_notifications.delete(key)
      notifications[key] = '' if notifications[key].blank?
    end
    to_translate += Clean::Support.hash_count(notifications)
    for key, trans in notifications.sort { |a, b| a[0].to_s <=> b[0].to_s }
      line = '      '
      if trans.blank?
        untranslated += 1
        line += missing_prompt
      end
      line += "#{key}:" + (trans.is_a?(Hash) ? '' : ' ') + Clean::Support.yaml_value((trans.blank? ? key.to_s.humanize : trans), 3)
      line.gsub!(/\ *$/, ' #?') if unknown_notifications.include?(key)
      translation << line + "\n"
    end
    warnings << "#{unknown_notifications.size} unknown notifications" if unknown_notifications.any?

    # Preferences
    translation << "  preferences:\n"
    preferences = ::I18n.t('preferences')
    unknown_preferences = ::I18n.t('preferences').keys
    new_preferences = []
    for preference in Preference.reference.keys.map(&:to_sym)
      if preferences[preference]
        unknown_preferences.delete(preference)
      else
        preferences[preference] = preference.to_s.humanize
        new_preferences << preference
      end
    end
    to_translate += Clean::Support.hash_count(preferences)
    for key, trans in preferences.sort { |a, b| a[0].to_s <=> b[0].to_s }
      line = '    '
      if new_preferences.include? key
        untranslated += 1
        line += missing_prompt
      end
      line += "#{key}: " + Clean::Support.yaml_value((trans.blank? ? key.to_s.humanize : trans), 2)
      line.gsub!(/$/, ' #?') if unknown_preferences.include?(key)
      translation << line + "\n"
    end
    warnings << "#{unknown_preferences.size} unknown preferences" if unknown_preferences.any?

    # REST actions
    translation << "  rest:\n"
    translation << "    actions:\n"
    actions = ::I18n.t('rest.actions')
    actions = {} unless actions.is_a?(Hash)
    unknown_actions = actions.keys
    for action in Clean::Support.look_for_rest_actions.map(&:to_sym)
      if actions.keys.include? action
        unknown_actions.delete(action.to_sym)
      else
        actions[action] = ''
      end
    end
    to_translate += Clean::Support.hash_count(actions)
    for key, trans in actions.sort { |a, b| a[0].to_s <=> b[0].to_s }
      line = '      '
      if trans.blank?
        untranslated += 1
        line += missing_prompt
      end
      line += "#{key}: " + Clean::Support.yaml_value((trans.blank? ? key.to_s.humanize : trans), 3)
      line.gsub!(/$/, ' #?') if unknown_actions.include?(key)
      translation << line + "\n"
    end
    warnings << "#{unknown_actions.size} unknown REST actions" if unknown_actions.any?

    # Unroll
    translation << "  unrolls:\n"
    unrolls = ::I18n.t('unrolls')
    unknown_unrolls = ::I18n.t('unrolls').keys
    controllers = Clean::Support.actions_hash.keys
    for unroll in unrolls.keys.map(&:to_sym)
      unknown_unrolls.delete(unroll) if controllers.include?(unroll.to_s)
    end
    to_translate += Clean::Support.hash_count(unrolls)
    for key, trans in unrolls.sort { |a, b| a[0].to_s <=> b[0].to_s }
      line = '    '
      line += "#{key}: " + Clean::Support.yaml_value((trans.blank? ? key.to_s.humanize : trans), 2)
      line.gsub!(/$/, ' #?') if unknown_unrolls.include?(key)
      translation << line + "\n"
    end
    warnings << "#{unknown_unrolls.size} unknown unrolls" if unknown_unrolls.any?

    # Finishing...
    File.open(locale_dir.join('action.yml'), 'wb') do |file|
      file.write(translation)
    end
    total = to_translate
    log.write "  - #{'action.yml:'.ljust(20)} #{(100 * (total - untranslated) / total).round.to_s.rjust(3)}% (#{total - untranslated}/#{total}) #{warnings.to_sentence}\n"
    atotal += to_translate
    acount += total - untranslated

    # Aggregators
    file = locale_dir.join('aggregators.yml')
    ref = begin
            Clean::Support.yaml_to_hash(file)[locale]
          rescue
            {}
          end
    to_translate = 0
    untranslated = 0

    translation  = "#{locale}:\n"

    # Parameters
    translation << "  aggregator_parameters:\n"
    ref[:aggregator_parameters] ||= {}
    all_parameters = []
    Aggeratio.each do |aggregator|
      all_parameters += aggregator.parameters.map(&:name).map(&:to_sym)
    end
    all_parameters.uniq!.sort!
    all_parameters.each do |param_name|
      to_translate = 1
      if (name = ref[:aggregator_parameters][param_name]) && name.present?
        translation << "    #{param_name}: " + Clean::Support.yaml_value(name) + "\n"
      elsif name = I18n.hardtranslate("labels.#{param_name}") || I18n.hardtranslate("attributes.#{param_name}")
        to_translate -= 1
        translation << "    #~ #{param_name}: " + Clean::Support.yaml_value(name) + "\n"
      else
        translation << "    #{missing_prompt}#{param_name}: " + Clean::Support.yaml_value(param_name.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    # Properties, title...
    translation << "  aggregator_properties:\n"
    ref[:aggregator_properties] ||= {}
    all_properties = []
    Aggeratio.each_xml_aggregator do |element|
      all_properties += Aggeratio::Base.new(element).properties.select { |e| e.attr('level').to_s != 'api' }.collect { |e| e.attr('name').to_sym }
    end
    all_properties.uniq!.sort!
    all_properties.each do |property_name|
      to_translate = 1
      if (name = ref[:aggregator_properties][property_name]) && name.present?
        translation << "    #{property_name}: " + Clean::Support.yaml_value(name) + "\n"
      elsif property_name.to_s.underscore != property_name.to_s
        to_translate -= 1
        translation << "    #~ #{property_name}: " + Clean::Support.yaml_value(property_name.to_s.underscore.humanize) + "\n"
      elsif name = I18n.hardtranslate("attributes.#{property_name}") || I18n.hardtranslate("labels.#{property_name}") || I18n.hardtranslate("activerecord.models.#{property_name}")
        to_translate -= 1
        translation << "    #~ #{property_name}: " + Clean::Support.yaml_value(name) + "\n"
      else
        translation << "    #{missing_prompt}#{property_name}: " + Clean::Support.yaml_value(property_name.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    # Agrgegators
    translation << "  aggregators:\n"
    ref[:aggregators] ||= {}
    Aggeratio.each do |aggregator|
      to_translate += 1
      agg_name = aggregator.aggregator_name.to_sym
      if (name = ref[:aggregators][agg_name]) && name.present?
        translation << "    #{aggregator.aggregator_name}: " + Clean::Support.yaml_value(name) + "\n"
      elsif item = Nomen::DocumentNature[agg_name]
        to_translate -= 1
        translation << "    #~ #{aggregator.aggregator_name}: " + Clean::Support.yaml_value(item.human_name) + "\n"
      else
        translation << "    #{missing_prompt}#{aggregator.aggregator_name}: " + Clean::Support.yaml_value(agg_name.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    # Finishing...
    File.open(file, 'wb') do |file|
      file.write(translation)
    end

    total = to_translate
    if to_translate > 0
      log.write "  - #{'procedures.yml:'.ljust(20)} #{(100 * (total - untranslated) / total).round.to_s.rjust(3)}% (#{total - untranslated}/#{total})\n"
    end
    atotal += to_translate
    acount += to_translate - untranslated
    # count = Clean::Support.sort_yaml_file :aggregators, log
    # atotal += count
    # acount += count

    # Devise
    count = Clean::Support.sort_yaml_file :devise, log
    atotal += count
    acount += count
    count = Clean::Support.sort_yaml_file 'devise.views', log
    atotal += count
    acount += count

    # Enumerize
    count = Clean::Support.sort_yaml_file :enumerize, log
    atotal += count
    acount += count

    # Formats
    count = Clean::Support.sort_yaml_file :formats, log
    atotal += count
    acount += count

    # Models
    untranslated = 0
    to_translate = 0
    warnings = []
    models = HashWithIndifferentAccess.new
    attributes = HashWithIndifferentAccess.new
    ::I18n.translate('attributes').collect { |k, v| attributes[k.to_s] = [v, :unused] }
    ::I18n.translate('activerecord.models').collect { |k, v| models[k.to_s] = [v, :unused] }
    ::I18n.translate('models').collect { |k, v| models[k.to_s] ||= []; models[k.to_s][2] = v }
    models_files = Dir[Rails.root.join('app', 'models', '*.rb')].collect { |m| m.split(/[\\\/\.]+/)[-2] }.sort
    for model_file in models_files
      model_name = model_file.sub(/\.rb$/, '')
      model = model_name.camelize.constantize
      next unless model < ActiveRecord::Base && !model.abstract_class?
      if models[model_name]
        models[model_name][1] = :used
      else
        models[model_name] = [model_name.humanize, :undefined]
              end
      for column in model.columns.collect { |c| c.name.to_s }
        if attributes[column]
          attributes[column][1] = :used
        elsif !column.match(/_id$/)
          attributes[column] = [column.humanize, :undefined]
        end
      end
      for column in model.instance_methods
        attributes[column][1] = :used if attributes[column]
      end
      for column in model.reflect_on_all_associations.map(&:name)
        attributes[column] = [column.to_s.humanize, :undefined] unless attributes[column]
      end
    end
    for k, v in models
      to_translate += 1 # if v[1]!=:unused
      untranslated += 1 if v[1] == :undefined
    end
    for k, v in attributes.delete_if { |k, _v| k.to_s.match(/^\_/) }
      to_translate += 1 # if v[1]!=:unused
      untranslated += 1 if v[1] == :undefined
    end

    translation = "#{locale}:\n"
    translation << "  activerecord:\n"
    to_translate += Clean::Support.hash_count(::I18n.translate('activerecord.attributes'))
    translation << '    attributes:' + Clean::Support.hash_to_yaml(::I18n.translate('activerecord.attributes'), 3) + "\n"
    to_translate += Clean::Support.hash_count(::I18n.translate('activerecord.errors'))
    translation << '    errors:' + Clean::Support.hash_to_yaml(::I18n.translate('activerecord.errors'), 3) + "\n"
    translation << "    models:\n"
    for model, definition in models.sort
      translation << '      '
      translation << missing_prompt if definition[1] == :undefined
      translation << "#{model}: " + Clean::Support.yaml_value(definition[0])
      translation << ' #?' if definition[1] == :unused
      translation << "\n"
    end
    translation << "  attributes:\n"
    for attribute, definition in attributes.sort
      # unless attribute.to_s.match(/_id$/)
      translation << '    '
      translation << missing_prompt if definition[1] == :undefined
      translation << "#{attribute}: " + Clean::Support.yaml_value(definition[0])
      translation << ' #?' if definition[1] == :unused
      translation << "\n"
      # end
    end

    # to_translate += Clean::Support.hash_count(::I18n.translate("enumerize"))
    # translation << "  enumerize:" + Clean::Support.hash_to_yaml(::I18n.translate("enumerize"), 2)+"\n"

    translation << "  models:\n"
    for model, definition in models.sort
      next unless definition[2]
      to_translate += Clean::Support.hash_count(definition[2])
      translation << "    #{model}:" + Clean::Support.yaml_value(definition[2], 2).gsub(/\n/, (definition[1] == :unused ? " #?\n" : "\n")) + "\n"
    end

    File.open(locale_dir.join('models.yml'), 'wb') do |file|
      file.write(translation)
    end
    total = to_translate
    log.write "  - #{'models.yml:'.ljust(20)} #{(100 * (total - untranslated) / total).round.to_s.rjust(3)}% (#{total - untranslated}/#{total}) #{warnings.to_sentence}\n"
    atotal += to_translate
    acount += total - untranslated

    # Nomenclatures
    file = locale_dir.join('nomenclatures.yml')
    ref = begin
            Clean::Support.yaml_to_hash(file)[locale][:nomenclatures]
          rescue
            nil
          end
    ref ||= {}
    translation = "#{locale}:\n"
    translation << "  nomenclatures:\n"
    for name in Nomen.names.sort { |a, b| a.to_s <=> b.to_s }
      nomenclature = Nomen[name]
      translation << "    #{nomenclature.name}:\n"
      translation << Clean::Support.exp(ref, nomenclature.name, :name, default: name.humanize).dig(3)
      next unless nomenclature.translateable?
      choices = ''
      item_lists = []
      if nomenclature.property_natures.any?
        translation << "      property_natures:\n"
        for name, property_nature in nomenclature.property_natures.sort { |a, b| a.first.to_s <=> b.first.to_s }
          translation << Clean::Support.exp(ref, nomenclature.name, :property_natures, name.to_sym).dig(4)
          if property_nature.type == :choice
            if property_nature.inline_choices?
              choices << "#{name}:\n"
              for choice in property_nature.choices.sort { |a, b| a.to_s <=> b.to_s }
                choices << Clean::Support.exp(ref, nomenclature.name, :choices, name.to_sym, choice.to_sym).dig
              end
            end
          elsif property_nature.type == :list && property_nature.choices_nomenclature.nil?
            item_lists << property_nature.name.to_sym
          end
        end
      end
      unless choices.blank?
        choices = "choices:\n" + choices.dig
        translation << choices.dig(3)
      end
      # if item_lists.any?
      #   lists = "item_lists:\n"
      #   for item in nomenclature.list.sort{|a,b| a.name.to_s <=> b.name.to_s}
      #     liss = ""
      #     for item_list in item_lists.sort{|a,b| a.to_s <=> b.to_s}
      #       iss = ""
      #       if is = item.send(item_list)
      #         iss << "#{item_list}:\n"
      #         for i in is
      #           iss << Clean::Support.exp(ref, nomenclature.name, :item_lists, item.name.to_sym, item_list, i.to_sym).dig
      #         end
      #       end
      #       liss << iss unless iss.blank?
      #     end
      #     lists << "  #{item.name}:\n" + liss.dig(2) unless liss.blank?
      #   end
      #   translation << lists.dig(3)
      # end
      translation << "      items:\n"
      for item in nomenclature.list.sort { |a, b| a.name.to_s <=> b.name.to_s }
        line = Clean::Support.exp(ref, nomenclature.name, :items, item.name.to_sym)
        translation << (item.root? ? line : line.ljust(50) + " #< #{item.parent.name}").dig(4)
      end
      next unless nomenclature.notions.any?
      translation << "      notions:\n"
      nomenclature.notions.each do |notion|
        translation << "        #{notion}:\n"
        for item in nomenclature.list.sort { |a, b| a.name.to_s <=> b.name.to_s }
          line = Clean::Support.exp(ref, nomenclature.name, :notions, notion, item.name.to_sym, default: "#{notion.to_s.humanize} of #{item.name.to_s.humanize}")
          translation << line.dig(5)
        end
      end
    end

    File.open(file, 'wb') do |file|
      file.write(translation)
    end

    # Procedures
    file = locale_dir.join('procedures.yml')
    ref = begin
            Clean::Support.yaml_to_hash(file)[locale]
          rescue
            {}
          end
    to_translate = 0
    untranslated = 0

    translation  = "#{locale}:\n"
    translation << "  procedo:\n"
    # translation << "    actions:\n"
    # ref[:procedo] ||= {}
    # ref[:procedo][:actions] ||= {}
    # for type, parameters in Procedo::Action::TYPES.sort { |a, b| a.first <=> b.first }
    #   to_translate += 1
    #   if name = ref[:procedo][:actions][type]
    #     translation << "      #{type}: " + Clean::Support.yaml_value(name) + "\n"
    #   else
    #     translation << "      #{missing_prompt}#{type}: " + Clean::Support.yaml_value("#{type.to_s.humanize} of " + parameters.keys.collect { |p| "%{#{p}}" }.to_sentence(locale: locale)) + "\n"
    #     untranslated += 1
    #   end
    # end

    translation << "  procedure_handlers:\n"
    handlers = []
    Procedo.each_product_parameter do |parameter|
      handlers += parameter.handlers.map(&:name)
    end
    handlers.uniq!
    ref[:procedure_handlers] ||= {}
    handlers.sort.each do |handler|
      to_translate += 1
      if name = ref[:procedure_handlers][handler]
        translation << "    #{handler}: " + Clean::Support.yaml_value(name) + "\n"
      elsif Nomen::Indicator[handler] # Facultative translation
        to_translate -= 1
        translation << "    #~ #{handler}: " + Clean::Support.yaml_value(handler.to_s.humanize) + "\n"
      else
        translation << "    #{missing_prompt}#{handler}: " + Clean::Support.yaml_value(handler.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    translation << "  procedure_parameters:\n"
    parameters = []
    Procedo.each_parameter do |parameter|
      parameters << parameter.name
    end
    parameters.uniq!
    ref[:procedure_parameters] ||= {}
    parameters.sort.each do |parameter|
      to_translate += 1
      if name = ref[:procedure_parameters][parameter]
        translation << "    #{parameter}: " + Clean::Support.yaml_value(name) + "\n"
      else
        translation << "    #{missing_prompt}#{parameter}: " + Clean::Support.yaml_value(parameter.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    translation << "  procedures:\n"
    procedures = Procedo.procedure_names.uniq.map(&:to_sym)
    ref[:procedures] ||= {}
    procedures.sort.each do |procedure|
      to_translate += 1
      if name = ref[:procedures][procedure]
        translation << "    #{procedure}: " + Clean::Support.yaml_value(name) + "\n"
      else
        translation << "    #{missing_prompt}#{procedure}: " + Clean::Support.yaml_value(procedure.to_s.humanize) + "\n"
        untranslated += 1
      end
    end

    # Finishing...
    File.open(file, 'wb') do |file|
      file.write(translation)
    end

    total = to_translate
    log.write "  - #{'procedures.yml:'.ljust(20)} #{(100 * (total - untranslated) / total).round.to_s.rjust(3)}% (#{total - untranslated}/#{total})\n"
    atotal += to_translate
    acount += to_translate - untranslated

    # Support
    count = Clean::Support.sort_yaml_file :support, log
    atotal += count
    acount += count

    # puts " - Locale: #{::I18n.locale_label} (Reference)"
    total = atotal
    count = acount
    log.write "  - Total:               #{(100 * count / total).round.to_s.rjust(3)}% (#{count}/#{total})\n"
    puts " - Locale: #{(100 * count / total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated (Reference)"
    reference_label = ::I18n.locale_name
    stats[::I18n.locale] = { translation_rate: count.to_f / total }

    # Compile complement file
    Clean::Locales.compile_complement(locale)

    for locale in ::I18n.available_locales.delete_if { |l| l == ::I18n.default_locale || l.to_s.size != 3 }.sort { |a, b| a.to_s <=> b.to_s }
      ::I18n.locale = locale
      locale_dir = Rails.root.join('config', 'locales', locale.to_s)
      FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
      FileUtils.makedirs(locale_dir.join('help')) unless File.exist?(locale_dir.join('help'))
      log.write "Locale #{::I18n.locale_label}:\n"
      total = 0
      count = 0
      for reference_path in Dir.glob(Rails.root.join('config', 'locales', ::I18n.default_locale.to_s, '*.yml')).sort
        next if reference_path =~ /\Wcomplement\.yml\z/
        file_name = reference_path.split(/[\/\\]+/)[-1]
        target_path = Rails.root.join('config', 'locales', locale.to_s, file_name)
        unless File.exist?(target_path)
          FileUtils.mkdir_p(target_path.dirname)
          File.open(target_path, 'wb') do |file|
            file.write("#{locale}:\n")
          end
        end
        target = Clean::Support.yaml_to_hash(target_path).deep_compact
        reference = Clean::Support.yaml_to_hash(reference_path).deep_compact
        translation, scount, stotal = Clean::Support.hash_diff(target[locale], reference[::I18n.default_locale], 1, (locale == :english ? :humanize : :localize))
        count += scount
        total += stotal
        log.write "  - #{(file_name + ':').ljust(20)} #{(stotal.zero? ? 0 : 100 * (stotal - scount) / stotal).round.to_s.rjust(3)}% (#{stotal - scount}/#{stotal})\n"
        File.open(target_path, 'wb') do |file|
          file.write("#{locale}:\n")
          file.write(translation)
        end
      end
      log.write "  - Total:               #{(100 * (total - count) / total).round.to_s.rjust(3)}% (#{total - count}/#{total})\n"

      # # Missing help files
      # # log.write "  - help: # Missing files\n"
      # for controller, actions in useful_actions
      #   for action in actions
      #     if File.exists?(Rails.root.join('app', 'views', controller.to_s, "#{action}.html.haml")) or (File.exists?("#{Rails.root.to_s}/app/views/#{controller}/_#{action.gsub(/_[^_]*$/,'')}_form.html.haml") and action.split("_")[-1].match(/create|update/))
      #       help = "#{Rails.root.to_s}/config/locales/#{locale}/help/#{controller}-#{action}.txt"
      #       # log.write "    - #{help.gsub(Rails.root.to_s,'.')}\n" unless File.exists?(help)
      #     end
      #   end
      # end

      puts " - Locale: #{(100 * (total - count) / total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated from #{reference_label}" # reference
      stats[locale] = { translation_rate: (total - count).to_f / total }

      # Compile complement
      Clean::Locales.compile_complement(locale)
    end

    # # Write stats file
    # File.open(Rails.root.join("config", "locales", "statistics.yml"), "wb") do |f|
    #   f.write "# This file contains statistics about translations"
    #   for locale, stat in stats.sort{|a,b| a[0] <=> b[0]}
    #     f.write Clean::Support.hash_to_yaml({locale => {:statistics => stat}})
    #   end
    # end
    log.close
  end
end
