module Clean
  module Locales
    class Scrutator
      attr_reader :to_translate, :untranslated

      def initialize
        @to_translate = 0
        @untranslated = 0
      end

      def exp(hash, *keys)
        options = keys.extract_options!
        name = keys.last
        @to_translate += 1
        value = rec(hash, *keys)
        yaml = Clean::Support.pair_to_yaml(name, value || options[:default] || name.to_s.humanize)
        unless value
          @untranslated += 1
          yaml.gsub!(/^/, Clean::Support.missing_prompt)
        end
        yaml
      end

      def rec(hash, *keys)
        key = keys.first
        if hash.is_a?(Hash)
          return rec(hash[key], *keys[1..-1]) if keys.count > 1
          return hash[key]
        end
        nil
      end
    end

    class Translation
      attr_reader :locale

      def initialize(locale, options = {})
        @locale = locale.to_sym
        @log = options[:log] if options[:log]
      end

      def clean!
        if Ekylibre::Plugin.registered_plugins.any?
          raise 'Cannot clean locales if plugins are activated'
        end

        log("Locale #{::I18n.locale_label}:\n")

        ::I18n.locale = @locale
        FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
        %w[help reporting].each do |directory|
          unless locale_dir.join(directory).exist?
            FileUtils.makedirs(locale_dir.join(directory))
          end
        end

        @count = 0
        @total = 0

        clean_access!
        clean_action!
        clean_aggregators!
        clean_file! 'devise'
        clean_file! 'devise.views'
        clean_enumerize!
        clean_file! 'exceptions'
        clean_exchangers!
        clean_file! 'formats'
        clean_file! 'mailers'
        clean_models!
        clean_nomenclatures!
        clean_procedures!
        clean_file! 'support'

        # puts " - Locale: #{::I18n.locale_label} (Reference)"
        log "  - Total:               #{(100 * @count / @total).round.to_s.rjust(3)}% (#{@count}/#{@total})\n"
        puts " - Locale: #{(100 * @count / @total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated"
      end

      # def clean_access!
      #   translate('access.yml') do |ref, translation, s|
      #     s.node :access do      #       s.node :interactions do
      #         Ekylibre::Access.interactions.each do |interaction|
      #           s.expect(interaction)
      #         end
      #       end
      #       s.node :resources do
      #         Ekylibre::Access.resources.keys.each do |resource|
      #           s.expect(resource)
      #         end
      #       end
      #     end
      #   end
      # end

      def clean_access!
        translate('access.yml') do |ref, translation, s|
          translation << "  access:\n"
          ref[:access] ||= {}

          translation << "    interactions:\n"
          ref[:access][:interactions] ||= {}
          Ekylibre::Access.interactions.each do |interaction|
            translation << s.exp(ref, :access, :interactions, interaction).dig(3)
          end

          translation << "    resources:\n"
          ref[:access][:resources] ||= {}
          Ekylibre::Access.resources.keys.each do |resource|
            translation << s.exp(ref, :access, :resources, resource).dig(3)
          end
        end
      end

      def clean_action!
        untranslated = to_translate = 0
        warnings = []
        translation = "#{locale}:\n"

        # Actions
        translation << "  actions:\n"
        # raise controllers_hash.inspect
        Clean::Support.actions_hash(except: [::ApiController, ::Backend::Cells::BaseController]).each do |controller_path, actions|
          existing_actions = begin
                               ::I18n.translate("actions.#{controller_path}").stringify_keys.keys
                             rescue
                               []
                             end
          translateable_actions = []
          translateable_actions += (actions.delete_if { |a| %i[update create picture destroy up down decrement increment duplicate reflect].include?(a.to_sym) || a.to_s.match(/^(list|unroll)(\_|$)/) } | existing_actions).sort
          next unless translateable_actions.any?
          translation << '    ' + controller_path + ":\n"
          translateable_actions.each do |action_name|
            name = ::I18n.translate_or_nil("actions.#{controller_path}.#{action_name}")
            to_translate += 1
            untranslated += 1 if actions.include?(action_name) && name.blank?
            translation << "      #{missing_prompt if name.blank?}#{action_name}: " + Clean::Support.yaml_value(name.blank? ? Clean::Support.default_action_title(controller_path, action_name) : name, 3)
            # translation << ' #?' unless actions.include?(action_name)
            translation << "\n"
          end
        end

        # Errors
        to_translate += Clean::Support.hash_count(::I18n.translate('errors'))
        translation << '  errors:' + Clean::Support.hash_to_yaml(::I18n.translate('errors'), 2) + "\n"

        # Front end
        to_translate += Clean::Support.hash_count(::I18n.translate('front-end'))
        translation << '  front-end:' + Clean::Support.hash_to_yaml(::I18n.translate('front-end'), 2) + "\n"

        # Labels
        translation << "  labels:\n"
        labels = ::I18n.t('labels')
        needed_labels = Clean::Support.look_for_labels(watched_files).each_with_object({}) do |string, hash|
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
              # line.gsub!(/\ *$/, ' #?')
            elsif Clean::Support.text_found?(/#{key.to_s.gsub('_', '.*')}/, watched_files)
              # line.gsub!(/\ *$/, ' #??')
            else
              # line.gsub!(/\ *$/, ' #?!')
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
          # line.gsub!(/\ *$/, ' #?') if unknown_notifications.include?(key)
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
          # line.gsub!(/$/, ' #?') if unknown_preferences.include?(key)
          translation << line + "\n"
        end
        warnings << "#{unknown_preferences.size} unknown preferences" if unknown_preferences.any?

        # REST actions
        translation << "  rest:\n"
        translation << "    actions:\n"
        actions = ::I18n.t('rest.actions')
        actions = {} unless actions.is_a?(Hash)
        unknown_actions = actions.keys
        Clean::Support.look_for_rest_actions.map(&:to_sym).each do |action|
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
          # line.gsub!(/$/, ' #?') if unknown_actions.include?(key)
          translation << line + "\n"
        end
        warnings << "#{unknown_actions.size} unknown REST actions" if unknown_actions.any?

        # Simple form
        to_translate += Clean::Support.hash_count(::I18n.translate('simple_form'))
        translation << '  simple_form:' + Clean::Support.hash_to_yaml(::I18n.translate('simple_form'), 2) + "\n"

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
          # line.gsub!(/$/, ' #?') if unknown_unrolls.include?(key)
          translation << line + "\n"
        end
        warnings << "#{unknown_unrolls.size} unknown unrolls" if unknown_unrolls.any?

        # Finishing...
        write('action.yml', translation, to_translate, untranslated)
      end

      def clean_aggregators!
        # Aggregators
        file = locale_dir.join('aggregators.yml')
        ref = load_file(file)
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
          to_translate += 1
          if (name = ref[:aggregator_parameters][param_name]) && name.present?
            translation << "    #{param_name}: " + Clean::Support.yaml_value(name) + "\n"
          elsif name = I18n.translate_or_nil("labels.#{param_name}") || I18n.translate_or_nil("attributes.#{param_name}")
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
          all_properties += Aggeratio::Base.new(element).properties.reject { |e| e.attr('level').to_s == 'api' }.collect { |e| e.attr('name').to_sym }
        end
        all_properties.uniq!.sort!
        all_properties.each do |property_name|
          to_translate += 1
          if (name = ref[:aggregator_properties][property_name]) && name.present?
            translation << "    #{property_name}: " + Clean::Support.yaml_value(name) + "\n"
          elsif property_name.to_s.underscore != property_name.to_s
            to_translate -= 1
            translation << "    #~ #{property_name}: " + Clean::Support.yaml_value(property_name.to_s.underscore.humanize) + "\n"
          elsif name = I18n.translate_or_nil("attributes.#{property_name}") || I18n.translate_or_nil("labels.#{property_name}") || I18n.translate_or_nil("activerecord.models.#{property_name}")
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
        write(file, translation, to_translate, untranslated)
      end

      def clean_enumerize!
        translate('enumerize.yml') do |ref, translation, s|
          translation << "  enumerize:\n"
          ref[:enumerize] ||= {}
          Clean::Support.models_in_file.each do |model|
            next unless model.respond_to? :enumerized_attributes
            attrs = []
            model.enumerized_attributes.each do |attr|
              next if attr.i18n_scope
              next unless attr.values.any?
              next if model < Ekylibre::Record::Base &&
                      model.nomenclature_reflections.detect { |_k, n| n.foreign_key.to_s == attr.name.to_s }
              attrs << attr
            end
            next unless attrs.any?
            translation << "    #{model.name.underscore}:\n"
            attrs.sort_by(&:name).each do |attr|
              translation << "      #{attr.name}:\n"
              attr.values.sort { |a, b| a <=> b }.each do |value|
                translation << s.exp(ref, :enumerize, model.name.underscore.to_sym, attr.name, value.to_sym).dig(4)
              end
            end
          end
        end
      end

      def clean_exchangers!
        translate('exchangers.yml') do |ref, translation, s|
          translation << "  exchangers:\n"
          ref[:exchangers] ||= {}
          ActiveExchanger::Base.exchangers.values.sort do |a, b|
            a.exchanger_name.to_s <=> b.exchanger_name.to_s
          end.each do |e|
            translation << s.exp(ref, :exchangers, e.exchanger_name).dig(2)
          end
        end
      end

      def clean_models!
        # Models
        untranslated = 0
        to_translate = 0
        warnings = []
        models = HashWithIndifferentAccess.new
        attributes = HashWithIndifferentAccess.new
        ::I18n.translate('attributes').collect { |k, v| attributes[k.to_s] = [v, :unused] }
        ::I18n.translate('activerecord.models').collect { |k, v| models[k.to_s] = [v, :unused] }
        ::I18n.translate('models').collect { |k, v| models[k.to_s] ||= []; models[k.to_s][2] = v }
        Clean::Support.models_in_file.each do |model|
          model_name = model.name.underscore
          if models[model_name]
            models[model_name][1] = :used
          else
            models[model_name] = [model_name.humanize, :undefined]
          end
          model.columns.each do |column|
            column_name = column.name.to_s
            if attributes[column_name]
              attributes[column_name][1] = :used
            elsif !column_name.match(/_id$/)
              attributes[column_name] = [column_name.humanize, :undefined]
            end
          end
          model.instance_methods.each do |method_name|
            attributes[method_name][1] = :used if attributes[method_name]
          end
          model.reflect_on_all_associations.each do |reflection|
            reflection_name = reflection.name.to_s
            unless attributes[reflection_name]
              attributes[reflection_name] = [reflection_name.to_s.humanize, :undefined]
            end
          end
        end
        models.each do |_k, v|
          to_translate += 1 # if v[1]!=:unused
          untranslated += 1 if v[1] == :undefined
        end
        attributes.each do |k, v|
          next if k.to_s =~ /^\_/
          to_translate += 1 # if v[1]!=:unused
          untranslated += 1 if v[1] == :undefined
        end

        translation = "#{locale}:\n"
        translation << "  errors:\n"
        to_translate += Clean::Support.hash_count(::I18n.translate('errors'))
        translation << "    messages: &error_messages" + Clean::Support.hash_to_yaml(::I18n.translate('errors.messages'), 3) + "\n"
        translation << "  activemodel:\n"
        translation << "    errors:\n"
        translation << "      messages:\n"
        translation << "        <<: *error_messages\n"
        translation << "  activerecord:\n"
        to_translate += Clean::Support.hash_count(::I18n.translate('activerecord.attributes'))
        translation << '    attributes:' + Clean::Support.hash_to_yaml(::I18n.translate('activerecord.attributes'), 3) + "\n"
        translation << "    errors:\n"
        translation << "      messages:\n"
        translation << "        <<: *error_messages\n"
        translation << "    models:\n"
        models.sort.each do |model, definition|
          translation << '      '
          translation << missing_prompt if definition[1] == :undefined
          translation << "#{model}: " + Clean::Support.yaml_value(definition[0])
          # translation << ' #?' if definition[1] == :unused
          translation << "\n"
        end
        translation << "  attributes:\n"
        attributes.sort.each do |attribute, definition|
          # unless attribute.to_s.match(%r(_id$))
          translation << '    '
          translation << missing_prompt if definition[1] == :undefined
          translation << "#{attribute}: " + Clean::Support.yaml_value(definition[0])
          # translation << ' #?' if definition[1] == :unused
          translation << "\n"
          # end
        end

        # to_translate += Clean::Support.hash_count(::I18n.translate("enumerize"))
        # translation << "  enumerize:" + Clean::Support.hash_to_yaml(::I18n.translate("enumerize"), 2)+"\n"

        translation << "  models:\n"
        models.sort.each do |model, definition|
          next unless definition[2]
          to_translate += Clean::Support.hash_count(definition[2])
          translation << "    #{model}:" + Clean::Support.yaml_value(definition[2], 2).gsub(/\n/, (definition[1] == :unused ? " #?\n" : "\n")) + "\n"
        end

        write('models.yml', translation, to_translate, untranslated)
      end

      # Nomenclatures
      def clean_nomenclatures!
        file = locale_dir.join('nomenclatures.yml')
        ref = load_file(file)[:nomenclatures]
        translation = "#{locale}:\n"
        translation << "  nomenclatures:\n"
        scrutator = scrut do |s|
          Nomen.load!
          Nomen.names.sort.each do |name| #  { |a, b| a.to_s <=> b.to_s }
            nomenclature = Nomen[name]
            translation << "    #{nomenclature.name}:\n"
            trl = {}

            trl[:name] = s.exp(ref, nomenclature.name, :name, default: name.humanize).dig(3)
            if nomenclature.translateable?
              choices = ''
              item_lists = []
              if nomenclature.property_natures.any?
                trl[:properties] = "      property_natures:\n"
                nomenclature.property_natures.sort { |a, b| a.first.to_s <=> b.first.to_s }.each do |name, property_nature|
                  trl[:properties] << s.exp(ref, nomenclature.name, :property_natures, name.to_sym).dig(4)
                  if property_nature.type == :choice || property_nature.type == :choice_list
                    if property_nature.inline_choices?
                      choices << "#{name}:\n"
                      property_nature.choices.sort_by(&:to_s).each do |choice|
                        choices << s.exp(ref, nomenclature.name, :choices, name.to_sym, choice.to_sym).dig
                      end
                    end
                  elsif property_nature.type == :list && property_nature.choices_nomenclature.nil?
                    item_lists << property_nature.name.to_sym
                  end
                end
              end
              if choices.present?
                choices = "choices:\n" + choices.dig
                trl[:choices] = choices.dig(3)
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
              #           iss << s.exp(ref, nomenclature.name, :item_lists, item.name.to_sym, item_list, i.to_sym).dig
              #         end
              #       end
              #       liss << iss unless iss.blank?
              #     end
              #     lists << "  #{item.name}:\n" + liss.dig(2) unless liss.blank?
              #   end
              #   translation << lists.dig(3)
              # end
              trl[:items] = "      items:\n"
              nomenclature.list.sort { |a, b| a.name.to_s <=> b.name.to_s }.each do |item|
                line = s.exp(ref, nomenclature.name, :items, item.name.to_sym)
                trl[:items] << (item.root? ? line : line.ljust(50) + " #< #{item.parent.name}").dig(4)
              end
              if nomenclature.notions.any?
                trl[:notions] = "      notions:\n"
                nomenclature.notions.each do |notion|
                  trl[:notions] << "        #{notion}:\n"
                  nomenclature.list.sort { |a, b| a.name.to_s <=> b.name.to_s }.each do |item|
                    line = s.exp(ref, nomenclature.name, :notions, notion, item.name.to_sym, default: "#{notion.to_s.humanize} of #{item.name.to_s.humanize}")
                    trl[:notions] << line.dig(5)
                  end
                end
              end
            end

            %i[choices items name notions properties].each do |info|
              translation << trl[info] if trl[info]
            end
          end
        end

        write(file, translation, scrutator.to_translate, scrutator.untranslated)
      end

      # Procedures
      def clean_procedures!
        file = locale_dir.join('procedures.yml')
        ref = load_file(file)
        to_translate = 0
        untranslated = 0

        translation  = "#{locale}:\n"

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

        translation << "  procedure_killable_parameters:\n"
        killables = [
          :is_it_completely_destroyed_by_intervention
        ]
        Procedo.each_product_parameter do |parameter|
          next unless parameter.attribute(:killable)
          key = "is_#{parameter.name}_completely_destroyed_by_#{parameter.procedure.name}".to_sym
          killables << key
          key = "is_#{parameter.name}_completely_destroyed_by_intervention".to_sym
          killables << key unless killables.include? key
        end
        ref[:procedure_killable_parameters] ||= {}
        killables.sort.each do |killable|
          to_translate += 1
          if (found = ref[:procedure_killable_parameters][killable])
            translation << "    #{killable}: " + Clean::Support.yaml_value(found) + "\n"
          else
            translation << "    #{missing_prompt}#{killable}: " + Clean::Support.yaml_value(killable.to_s.humanize + '?') + "\n"
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
        write(file, translation, to_translate, untranslated)
      end

      # Cleans translation from a reference locale
      def clean_from!(reference_locale)
        ::I18n.locale = @locale
        FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
        FileUtils.makedirs(locale_dir.join('help')) unless File.exist?(locale_dir.join('help'))
        log "Locale #{::I18n.locale_label}:\n"
        total = 0
        count = 0
        Dir.glob(Rails.root.join('config', 'locales', reference_locale.to_s, '*.yml')).sort.each do |reference_path|
          file_name = reference_path.split(%r{[\/\\]+})[-1]
          target_path = Rails.root.join('config', 'locales', locale.to_s, file_name)
          unless File.exist?(target_path)
            FileUtils.mkdir_p(target_path.dirname)
            File.open(target_path, 'wb') do |file|
              file.write("#{locale}: {}\n")
            end
          end
          target = Clean::Support.yaml_to_hash(target_path).deep_compact
          reference = Clean::Support.yaml_to_hash(reference_path).deep_compact
          translation, scount, stotal = Clean::Support.hash_diff(target[locale], reference[reference_locale], locale == :english ? :humanize : :localize)
          count += scount
          total += stotal
          log "  - #{(file_name + ':').ljust(20)} #{(stotal.zero? ? 0 : 100 * (stotal - scount) / stotal).round.to_s.rjust(3)}% (#{stotal - scount}/#{stotal})\n"
          File.open(target_path, 'wb') do |file|
            file.write("#{locale}:\n")
            file.write(translation.indent.gsub(/\ +\n/, "\n"))
          end
        end
        log "  - Total:               #{(100 * (total - count) / total).round.to_s.rjust(3)}% (#{total - count}/#{total})\n"

        # # Missing help files
        # # log "  - help: # Missing files\n"
        # for controller, actions in useful_actions
        #   for action in actions
        #     if File.exists?(Rails.root.join('app', 'views', controller.to_s, "#{action}.html.haml")) or (File.exists?("#{Rails.root.to_s}/app/views/#{controller}/_#{action.gsub(%r(_[^_]*$), '')}_form.html.haml") and action.split("_")[-1].match(%r(create|update))
        #       help = "#{Rails.root.to_s}/config/locales/#{locale}/help/#{controller}-#{action}.txt"
        #       # log "    - #{help.gsub(Rails.root.to_s,'.')}\n" unless File.exists?(help)
        #     end
        #   end
        # end

        puts " - Locale: #{(100 * (total - count) / total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated from #{'i18n.name'.t(locale: reference_locale)}" # reference
      end

      protected

      def locale_dir
        Rails.root.join('config', 'locales', @locale.to_s)
      end

      def log(text)
        return unless @log
        @log.write(text)
        @log.flush
      end

      def write(file, translation, total, untranslated = 0)
        file = locale_dir.join(file) if file.is_a?(String)
        File.write(file, translation.strip.gsub(/\ +\n/, "\n"))
        log "  - #{(file.basename.to_s + ':').ljust(20)} #{(100 * (total - untranslated) / total).round.to_s.rjust(3)}% (#{total - untranslated}/#{total})\n"
        @total += total
        @count += total - untranslated
      end

      def scrut
        s = Scrutator.new
        yield s
        s
      end

      def translate(basename)
        file = locale_dir.join(basename)
        ref = load_file(file)
        translation = "#{locale}:\n"
        scrutator = scrut do |s|
          yield(ref, translation, s)
        end
        write(file, translation, scrutator.to_translate, scrutator.untranslated)
      end

      def watched_files
        '{app,config,db,lib,test}/**/*.{rb,haml,erb}'
      end

      def missing_prompt
        Clean::Support.missing_prompt
      end

      def clean_file!(basename)
        yaml_file = locale_dir.join("#{basename}.yml")
        return unless yaml_file.exist?
        translation, total = Clean::Support.hash_sort_and_count(Clean::Support.yaml_to_hash(yaml_file))
        write(yaml_file, translation, total)
      end

      def load_file(file)
        Clean::Support.yaml_to_hash(file)[locale] || {}
      rescue
        {}
      end
    end

    def self.run!(reference = nil)
      Clean::Support.set_search_path!
      reference ||= I18n.default_locale
      log = File.open(Rails.root.join('log', 'clean-locales.log'), 'wb')
      Translation.new(reference, log: log).clean!
      locales = ::I18n.available_locales.delete_if do |l|
        l == reference || l.to_s.size != 3
      end.sort_by(&:to_s)
      locales.each do |locale|
        Translation.new(locale, log: log).clean_from!(reference)
      end
    end
  end
end
