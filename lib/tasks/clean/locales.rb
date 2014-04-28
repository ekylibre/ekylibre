module Clean

  module Locales

    class << self

      ENUMERIZES = Dir.glob(Rails.root.join("app", "models", "*.rb")).sort.inject({}) do |hash, file|
        enumerizes = {}
        File.open(file, "rb:UTF-8").each_line do |line|
          if line =~ /\A\s*enumerize/
            line = line.strip.split(/[\(\,\s\)]+/)
            name = line[1][1..-1].to_sym
            source = line[3].to_s
            if source =~ /\ANomen\:\:/
              elements = source.gsub('Nomen::', '').split('.')
              enumerizes[name] = [:nomen, elements.shift.underscore.to_sym]
              method_name = elements.shift
              if method_name =~ /\Aall(\W|\z)/
                enumerizes[name] << :items
              else
                enumerizes[name] << :choices
                enumerizes[name] << method_name.to_sym
              end
            end
          end
        end
        hash[file.split(/\W/)[-2].to_sym] = enumerizes unless enumerizes.empty?
        hash
      end.freeze

      def compile_complement(locale)
        locale_dir = Rails.root.join("config", "locales", locale.to_s)
        hash = {}
        hash.deep_merge!(Clean::Support.yaml_to_hash(locale_dir.join("models.yml")))
        hash.deep_merge!(Clean::Support.yaml_to_hash(locale_dir.join("aggregators.yml")))
        hash.deep_merge!(Clean::Support.yaml_to_hash(locale_dir.join("procedures.yml")))
        hash.deep_merge!(Clean::Support.yaml_to_hash(locale_dir.join("nomenclatures.yml")))

        complement = {enumerize: {}}
        enumerize = complement[:enumerize]
        for model, enumerizes in ENUMERIZES
          enumerize[model] = {}
          for name, source in enumerizes
            if source.first == :nomen
              if n = hash[locale][:nomenclatures][source[1]]
                if n = n[source[2]] and n.is_a?(Hash)
                  if source[2] == :choices
                    n = n[source[3]]
                  end
                  enumerize[model][name] = n
                end
              end
            else
              puts "#{source.first.inspect} nor supported"
            end
          end
        end

        enumerize[:product_reading] ||= {}
        enumerize[:product_reading][:indicator_name] = Clean::Support.rec(hash, locale, :nomenclatures, :indicators, :items)
        enumerize[:product_nature_variant_reading] ||= {}
        enumerize[:product_nature_variant_reading][:indicator_name] = Clean::Support.rec(hash, locale, :nomenclatures, :indicators, :items)
        enumerize[:production_support_marker] ||= {}
        enumerize[:production_support_marker][:indicator_name] = Clean::Support.rec(hash, locale, :nomenclatures, :indicators, :items)
        enumerize[:intervention] ||= {}
        enumerize[:intervention][:reference_name] = Clean::Support.rec(hash, locale, :procedures)
        enumerize[:intervention_cast] ||= {}
        enumerize[:intervention_cast][:reference_name] = Clean::Support.rec(hash, locale, :variables)
        enumerize[:operation_task] ||= {}
        enumerize[:operation_task][:nature] = Clean::Support.rec(hash, locale, :procedo, :actions)
        enumerize[:listing] ||= {}
        enumerize[:listing][:root_model] = Clean::Support.rec(hash, locale, :activerecord, :models)

        File.open(locale_dir.join("complement.yml"), "wb") do |f|
          f.write "# This file is totally generated from other translations for convenience.\n"
          f.write "# Do not touch this please, it's quite useless.\n"
          f.write Clean::Support.hash_to_yaml(locale => complement)
        end
      end

    end

  end

end


desc "Update and sort translation files"
task :locales => :environment do

  stats = {}

  log = File.open(Rails.root.join("log", "clean-locales.log"), "wb")

  missing_prompt = "# "

  locale = ::I18n.locale = ::I18n.default_locale
  locale_dir = Rails.root.join("config", "locales", locale.to_s)
  FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
  for directory in ["help", "prints"] # , "profiles"
    FileUtils.makedirs(locale_dir.join(directory)) unless File.exist?(locale_dir.join(directory))
  end
  log.write("Locale #{::I18n.locale_label}:\n")


  untranslated = to_translate = translated = 0
  warnings = []
  acount = atotal = 0

  translation  = "#{locale}:\n"

  # Actions
  translation << "  actions:\n"
  # raise controllers_hash.inspect
  for controller_path, actions in Clean::Support.actions_hash
    existing_actions = ::I18n.translate("actions.#{controller_path}").stringify_keys.keys rescue []
    translateable_actions = []
    translateable_actions += (actions.delete_if{ |a| [:update, :create, :picture, :destroy, :up, :down, :decrement, :increment, :duplicate, :reflect].include?(a.to_sym) or a.to_s.match(/^(list|unroll)(\_|$)/)}|existing_actions).sort
    if translateable_actions.any?
      translation << "    " + controller_path + ":\n"
      for action_name in translateable_actions
        name = ::I18n.hardtranslate("actions.#{controller_path}.#{action_name}")
        to_translate += 1
        if actions.include?(action_name)
          untranslated += 1 if name.blank?
        end
        translation << "      #{missing_prompt if name.blank?}#{action_name}: " + Clean::Support.yaml_value(name.blank? ? Clean::Support.default_action_title(controller_path, action_name) : name, 3)
        translation << " #?" unless actions.include?(action_name)
        translation << "\n"
      end
    end
  end

  # Controllers
  # translation << "  controllers:\n"
  # for controller_path, actions in Clean::Support.actions_hash
  #   controller_name = controller_path.split("/").last
  #   name = ::I18n.hardtranslate("controllers.#{controller_path}")
  #   untranslated += 1 if name.blank?
  #   to_translate += 1
  #   translation << "    #{missing_prompt if name.blank?}#{controller_path}: " + Clean::Support.yaml_value(name.blank? ? controller_name.humanize : name, 2) + "\n"
  # end

  # Errors
  to_translate += Clean::Support.hash_count(::I18n.translate("errors"))
  translation << "  errors:"+Clean::Support.hash_to_yaml(::I18n.translate("errors"), 2)+"\n"

  # Labels
  to_translate += Clean::Support.hash_count(::I18n.translate("labels"))
  translation << "  labels:"+Clean::Support.hash_to_yaml(::I18n.translate("labels"), 2)+"\n"

  # Notifications
  translation << "  notifications:\n"
  notifications = ::I18n.t("notifications")
  deleted_notifs = ::I18n.t("notifications").keys
  for controller in Dir[Rails.root.join("app", "controllers", "**", "*.rb")]
    File.open(controller, "rb").each_line do |line|
      if line.match(/([\s\W]+|^)notify(_error|_warning|_success)?(_now)?\(\s*\:\w+/)
        key = line.split(/notify\w*\(\s*\:/)[1].split(/\W/)[0]
        # raise "Notification :#{key} (#{line})"
        deleted_notifs.delete(key.to_sym)
        notifications[key.to_sym] = "" if notifications[key.to_sym].nil? or (notifications[key.to_sym].is_a? String and notifications[key.to_sym].match(/\(\(\(/))
      end
    end
  end
  to_translate += Clean::Support.hash_count(notifications) # .keys.size
  for key, trans in notifications.sort{|a,b| a[0].to_s <=> b[0].to_s}
    line = "    "
    if trans.blank?
      untranslated += 1
      line += missing_prompt
    end
    line += "#{key}: "+Clean::Support.yaml_value((trans.blank? ? key.to_s.humanize : trans), 2)
    line.gsub!(/$/, " #?") if deleted_notifs.include?(key)
    translation << line+"\n"
  end
  warnings << "#{deleted_notifs.size} bad notifications" if deleted_notifs.size > 0

  # Preferences
  to_translate += Clean::Support.hash_count(::I18n.translate("preferences"))
  translation << "  preferences:" + Clean::Support.hash_to_yaml(::I18n.translate("preferences"), 2) + "\n"

  # Unroll
  to_translate += Clean::Support.hash_count(::I18n.translate("unroll"))
  translation << "  unroll:" + Clean::Support.hash_to_yaml(::I18n.translate("unroll"), 2)

  File.open(locale_dir.join("action.yml"), "wb") do |file|
    file.write(translation)
  end
  total = to_translate
  log.write "  - #{'action.yml:'.ljust(20)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total}) #{warnings.to_sentence}\n"
  atotal += to_translate
  acount += total-untranslated


  # Aggregators
  count = Clean::Support.sort_yaml_file :aggregators, log
  atotal += count
  acount += count

  # Devise
  count = Clean::Support.sort_yaml_file :devise, log
  atotal += count
  acount += count
  count = Clean::Support.sort_yaml_file "devise.views", log
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
  ::I18n.translate("attributes").collect{|k, v| attributes[k.to_s] = [v, :unused]}
  ::I18n.translate("activerecord.models").collect{|k, v| models[k.to_s] = [v, :unused]}
  ::I18n.translate("models").collect{|k, v| models[k.to_s] ||= []; models[k.to_s][2] = v}
  models_files = Dir[Rails.root.join("app", "models", "*.rb")].collect{|m| m.split(/[\\\/\.]+/)[-2]}.sort
  for model_file in models_files
    model_name = model_file.sub(/\.rb$/,'')
    model = model_name.camelize.constantize
    if model < ActiveRecord::Base && !model.abstract_class?
      if models[model_name]
        models[model_name][1] = :used
      else
        models[model_name] = [model_name.humanize, :undefined]
      end
      for column in model.columns.collect{|c| c.name.to_s}
        if attributes[column]
          attributes[column][1] = :used
        elsif !column.match(/_id$/)
          attributes[column] = [column.humanize, :undefined]
        end
      end
      for column in model.instance_methods
        attributes[column][1] = :used if attributes[column]
      end
      for column in model.reflections.keys
        attributes[column] = [column.to_s.humanize, :undefined] unless attributes[column]
      end
    end
  end
  for k, v in models
    to_translate += 1 # if v[1]!=:unused
    untranslated += 1 if v[1]==:undefined
  end
  for k, v in attributes.delete_if{|k,v| k.to_s.match(/^\_/)}
    to_translate += 1 # if v[1]!=:unused
    untranslated += 1 if v[1]==:undefined
  end

  translation  = locale.to_s+":\n"
  translation << "  activerecord:\n"
  to_translate += Clean::Support.hash_count(::I18n.translate("activerecord.attributes"))
  translation << "    attributes:" + Clean::Support.hash_to_yaml(::I18n.translate("activerecord.attributes"), 3)+"\n"
  to_translate += Clean::Support.hash_count(::I18n.translate("activerecord.errors"))
  translation << "    errors:" + Clean::Support.hash_to_yaml(::I18n.translate("activerecord.errors"), 3)+"\n"
  translation << "    models:\n"
  for model, definition in models.sort
    translation << "      "
    translation << missing_prompt if definition[1] == :undefined
    translation << "#{model}: "+Clean::Support.yaml_value(definition[0])
    translation << " #?" if definition[1] == :unused
    translation << "\n"
  end
  translation << "  attributes:\n"
  for attribute, definition in attributes.sort
    # unless attribute.to_s.match(/_id$/)
    translation << "    "
    translation << missing_prompt if definition[1] == :undefined
    translation << "#{attribute}: "+Clean::Support.yaml_value(definition[0])
    translation << " #?" if definition[1] == :unused
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

  File.open(locale_dir.join("models.yml"), "wb") do |file|
    file.write(translation)
  end
  total = to_translate
  log.write "  - #{'models.yml:'.ljust(20)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total}) #{warnings.to_sentence}\n"
  atotal += to_translate
  acount += total-untranslated

  # Nomenclatures
  file = locale_dir.join("nomenclatures.yml")
  ref = Clean::Support.yaml_to_hash(file)[locale][:nomenclatures] rescue nil
  ref ||= {}
  translation  = locale.to_s+":\n"
  translation << "  nomenclatures:\n"
  for name in Nomen.names.sort{|a,b| a.to_s <=> b.to_s}
    nomenclature = Nomen[name]
    translation << "    #{nomenclature.name}:\n"
    translation << Clean::Support.exp(ref, nomenclature.name, :name, default: name.humanize).dig(3)
    next unless nomenclature.translateable?
    choices = ""
    item_lists = []
    if nomenclature.property_natures.any?
      translation << "      property_natures:\n"
      for name, property_nature in nomenclature.property_natures.sort{|a,b| a.first.to_s <=> b.first.to_s}
        translation << Clean::Support.exp(ref, nomenclature.name, :property_natures, name.to_sym).dig(4)
        if property_nature.type == :choice
          if property_nature.inline_choices?
            choices << "#{name}:\n"
            for choice in property_nature.choices.sort{|a,b| a.to_s <=> b.to_s}
              choices << Clean::Support.exp(ref, nomenclature.name, :choices, name.to_sym, choice.to_sym).dig
            end
          else
            # choices << "#! #{name}: Choices comes from nomenclature: #{property_nature.choices_nomenclature}\n"
          end
        elsif property_nature.type == :list and property_nature.choices_nomenclature.nil?
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
    for item in nomenclature.list.sort{|a,b| a.name.to_s <=> b.name.to_s}
      line = Clean::Support.exp(ref, nomenclature.name, :items, item.name.to_sym)
      translation << (item.root? ? line : line.ljust(50) + " #< #{item.parent.name}").dig(4)
    end
  end

  File.open(file, "wb") do |file|
    file.write(translation)
  end


  # count = Clean::Support.sort_yaml_file :nomenclatures, log
  # atotal += count
  # acount += count

  # Procedures
  count = Clean::Support.sort_yaml_file :procedures, log
  atotal += count
  acount += count

  # Support
  count = Clean::Support.sort_yaml_file :support, log
  atotal += count
  acount += count

  # puts " - Locale: #{::I18n.locale_label} (Reference)"
  total, count = atotal, acount
  log.write "  - Total:               #{(100*count/total).round.to_s.rjust(3)}% (#{count}/#{total})\n"
  puts " - Locale: #{(100*count/total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated (Reference)"
  reference_label = ::I18n.locale_name
  stats[::I18n.locale] = {:translation_rate => count.to_f/total}


  # Compile complement file
  Clean::Locales.compile_complement(locale)


  for locale in ::I18n.available_locales.delete_if{|l| l == ::I18n.default_locale or l.to_s.size != 3}.sort{|a,b| a.to_s <=> b.to_s}
    ::I18n.locale = locale
    locale_dir = Rails.root.join("config", "locales", locale.to_s)
    FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
    FileUtils.makedirs(locale_dir.join("help")) unless File.exist?(locale_dir.join("help"))
    log.write "Locale #{::I18n.locale_label}:\n"
    total, count = 0, 0
    for reference_path in Dir.glob(Rails.root.join("config", "locales", ::I18n.default_locale.to_s, "*.yml")).sort
      next if reference_path.match(/\Wcomplement\.yml\z/)
      file_name = reference_path.split(/[\/\\]+/)[-1]
      target_path = Rails.root.join("config", "locales", locale.to_s, file_name)
      unless File.exist?(target_path)
        FileUtils.mkdir_p(target_path.dirname)
        File.open(target_path, "wb") do |file|
          file.write("#{locale}:\n")
        end
      end
      target = Clean::Support.yaml_to_hash(target_path)
      reference = Clean::Support.yaml_to_hash(reference_path)
      translation, scount, stotal = Clean::Support.hash_diff(target[locale], reference[::I18n.default_locale], 1, (locale == :english ? :humanize : :localize))
      count += scount
      total += stotal
      log.write "  - #{(file_name+':').ljust(20)} #{(stotal.zero? ? 0 : 100*(stotal-scount)/stotal).round.to_s.rjust(3)}% (#{stotal-scount}/#{stotal})\n"
      File.open(target_path, "wb") do |file|
        file.write("#{locale}:\n")
        file.write(translation)
      end
    end
    log.write "  - Total:               #{(100*(total-count)/total).round.to_s.rjust(3)}% (#{total-count}/#{total})\n"

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

    puts " - Locale: #{(100*(total-count)/total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated from #{reference_label}" # reference
    stats[locale] = {:translation_rate => (total-count).to_f/total}

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
