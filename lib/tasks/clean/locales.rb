#
desc "Update and sort translation files"
task :locales => :environment do
  log = File.open(Rails.root.join("log", "clean-locales.log"), "wb")

  missing_prompt = "# "

  # Load of actions
  all_actions = HashWithIndifferentAccess.new
  for right, actions in YAML.load_file(User.rights_file)
    for uniq_action in actions
      controller, action = uniq_action.split(/\#/)[0..1]
      all_actions[controller] ||= []
      all_actions[controller] << action
    end if actions.is_a? Array
  end
  useful_actions = all_actions.dup
  useful_actions.delete("help")

  locale = ::I18n.locale = ::I18n.default_locale
  locale_dir = Rails.root.join("config", "locales", locale.to_s)
  FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
  for directory in ["help", "prints", "profiles"]
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
  for controller_name, actions in actions_hash
    existing_actions = ::I18n.translate("actions.#{controller_name}").stringify_keys.keys rescue []
    translateable_actions = []
    translateable_actions += (actions.delete_if{|a| [:update, :create, :destroy, :up, :down, :decrement, :increment, :duplicate, :reflect].include?(a.to_sym) or a.to_s.match(/^(list|unroll)(\_|$)/)}|existing_actions).sort if controller_name != "backend/interfacers"
    if translateable_actions.size > 0
      translation << "    " + controller_name + ":\n"
      for action_name in translateable_actions
        name = ::I18n.hardtranslate("actions.#{controller_name}.#{action_name}")
        to_translate += 1
        if actions.include?(action_name)
          untranslated += 1 if name.blank?
        end
        translation << "      #{missing_prompt if name.blank?}#{action_name}: " + yaml_value(name.blank? ? "#{action_name}#{'_'+controller_name.singularize unless action_name.match(/^list/)}".humanize : name, 3)
        translation << " #?" unless actions.include?(action_name)
        translation << "\n"
      end
    end
  end

  # Controllers
  translation << "  controllers:\n"
  for controller_name, actions in actions_hash
    name = ::I18n.hardtranslate("controllers.#{controller_name}")
    untranslated += 1 if name.blank?
    to_translate += 1
    translation << "    #{missing_prompt if name.blank?}#{controller_name}: " + yaml_value(name.blank? ? controller_name.humanize : name, 2) + "\n"
  end

  # Errors
  to_translate += hash_count(::I18n.translate("errors"))
  translation << "  errors:"+hash_to_yaml(::I18n.translate("errors"), 2)+"\n"

  # Labels
  to_translate += hash_count(::I18n.translate("labels"))
  translation << "  labels:"+hash_to_yaml(::I18n.translate("labels"), 2)+"\n"

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
  to_translate += hash_count(notifications) # .keys.size
  for key, trans in notifications.sort{|a,b| a[0].to_s<=>b[0].to_s}
    line = "    "
    if trans.blank?
      untranslated += 1
      line += missing_prompt
    end
    line += "#{key}: "+yaml_value((trans.blank? ? key.to_s.humanize : trans), 2)
    line.gsub!(/$/, " #?") if deleted_notifs.include?(key)
    translation << line+"\n"
  end
  warnings << "#{deleted_notifs.size} bad notifications" if deleted_notifs.size > 0

  # Preferences
  to_translate += hash_count(::I18n.translate("preferences"))
  translation << "  preferences:"+hash_to_yaml(::I18n.translate("preferences"), 2) + "\n"

  # Unroll
  to_translate += hash_count(::I18n.translate("unroll"))
  translation << "  unroll:"+hash_to_yaml(::I18n.translate("unroll"), 2)

  File.open(locale_dir.join("action.yml"), "wb") do |file|
    file.write(translation)
  end
  total = to_translate
  log.write "  - #{'action.yml:'.ljust(20)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total}) #{warnings.to_sentence}\n"
  atotal += to_translate
  acount += total-untranslated


  # Countries
  count = sort_yaml_file :countries, log
  atotal += count
  acount += count

  # Currencies
  currencies_ref = YAML.load_file(I18n.currencies_file)
  currencies = YAML.load_file(locale_dir.join("currencies.yml"))[locale.to_s]
  translation  = locale.to_s+":\n"
  translation << "  currencies:\n"
  to_translate, untranslated = 0, 0
  for currency, details in currencies_ref.sort
    to_translate += 1
    if currencies["currencies"][currency].blank?
      translation << "    #{missing_prompt}#{currency}: #{yaml_value(details['iso_name'])}\n"
      untranslated += 1
    else
      translation << "    #{currency}: "+yaml_value(::I18n.translate("currencies.#{currency}"))+"\n"
    end
  end
  translation << "  # Override here default formatting options for each currency IF NEEDED\n"
  translation << "  # Ex.: number.currency.formats.XXX.format\n"
  translation << "  number:\n"
  translation << "    currency:\n"
  translation << "      formats:\n"
  for currency, details in currencies_ref.sort
    x = hash_count(::I18n.hardtranslate("number.currency.formats.#{currency}")||{})
    to_translate += x
    if x > 0
      translation << "        #{currency}:"+hash_to_yaml(::I18n.hardtranslate("number.currency.formats.#{currency}")||{}, 5)+"\n"
#    else
#      translation << "        #{missing_prompt}#{currency}:\n"
    end
  end
  File.open(locale_dir.join("currencies.yml"), "wb") do |file|
    file.write translation
  end
  total = to_translate
  log.write "  - #{'currencies.yml:'.ljust(20)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total})\n"
  atotal += total
  acount += total-untranslated


  # Languages
  count = sort_yaml_file :languages, log
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
  to_translate += hash_count(::I18n.translate("activerecord.attributes"))
  translation << "    attributes:"+hash_to_yaml(::I18n.translate("activerecord.attributes"), 3)+"\n"
  to_translate += hash_count(::I18n.translate("activerecord.errors"))
  translation << "    errors:"+hash_to_yaml(::I18n.translate("activerecord.errors"), 3)+"\n"
  translation << "    models:\n"
  for model, definition in models.sort
    translation << "      "
    translation << missing_prompt if definition[1] == :undefined
    translation << "#{model}: "+yaml_value(definition[0])
    translation << " #?" if definition[1] == :unused
    translation << "\n"
  end
  translation << "  attributes:\n"
  for attribute, definition in attributes.sort
    # unless attribute.to_s.match(/_id$/)
    translation << "    "
    translation << missing_prompt if definition[1] == :undefined
    translation << "#{attribute}: "+yaml_value(definition[0])
    translation << " #?" if definition[1] == :unused
    translation << "\n"
    # end
  end

  to_translate += hash_count(::I18n.translate("enumerize"))
  translation << "  enumerize:"+hash_to_yaml(::I18n.translate("enumerize"), 2)+"\n"

  translation << "  models:\n"
  for model, definition in models.sort
    next unless definition[2]
    to_translate += hash_count(definition[2])
    translation << "    #{model}:" + yaml_value(definition[2], 2).gsub(/\n/, (definition[1] == :unused ? " #?\n" : "\n")) + "\n"
  end

  File.open(locale_dir.join("models.yml"), "wb") do |file|
    file.write(translation)
  end
  total = to_translate
  log.write "  - #{'models.yml:'.ljust(20)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total}) #{warnings.to_sentence}\n"
  atotal += to_translate
  acount += total-untranslated


  # Rights
  rights = YAML.load_file(User.rights_file)
  translation  = locale.to_s+":\n"
  translation << "  rights:\n"
  untranslated = 0
  for right in rights.keys.sort
    name = ::I18n.hardtranslate("rights.#{right}")
    if name.blank?
      untranslated += 1
      translation << "    #{missing_prompt}#{right}: #{yaml_value(right.humanize, 2)}\n"
    else
      translation << "    #{right}: #{yaml_value(name, 2)}\n"
    end
  end
  File.open(locale_dir.join("rights.yml"), "wb") do |file|
    file.write translation
  end
  total = rights.keys.size
  log.write "  - #{'rights.yml:'.ljust(20)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total})\n"
  atotal += total
  acount += total-untranslated


  # Support
  count = sort_yaml_file :support, log
  atotal += count
  acount += count

  # Devise
  count = sort_yaml_file :devise, log
  atotal += count
  acount += count

  count = sort_yaml_file "devise.views", log
  atotal += count
  acount += count



  # puts " - Locale: #{::I18n.locale_label} (Reference)"
  total, count = atotal, acount
  log.write "  - Total:               #{(100*count/total).round.to_s.rjust(3)}% (#{count}/#{total})\n"
  puts " - Locale: #{(100*count/total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated (Reference)"
  reference_label = ::I18n.locale_name




  for locale in ::I18n.available_locales.delete_if{|l| l == ::I18n.default_locale or l.to_s.size != 3}.sort{|a,b| a.to_s <=> b.to_s}
    ::I18n.locale = locale
    locale_dir = Rails.root.join("config", "locales", locale.to_s)
    FileUtils.makedirs(locale_dir) unless File.exist?(locale_dir)
    FileUtils.makedirs(locale_dir.join("help")) unless File.exist?(locale_dir.join("help"))
    log.write "Locale #{::I18n.locale_label}:\n"
    total, count = 0, 0
    for reference_path in Dir.glob(Rails.root.join("config", "locales", ::I18n.default_locale.to_s, "*.yml")).sort
      file_name = reference_path.split(/[\/\\]+/)[-1]
      next if file_name.match(/accounting/)
      target_path = Rails.root.join("config", "locales", locale.to_s, file_name)
      unless File.exist?(target_path)
        File.open(target_path, "wb") do |file|
          file.write("#{locale}:\n")
        end
      end
      target = yaml_to_hash(target_path)
      reference = yaml_to_hash(reference_path)
      translation, scount, stotal = hash_diff(target[locale], reference[::I18n.default_locale], 1)
      count += scount
      total += stotal
      # puts "  - #{(file_name+':').ljust(20)} #{stotal} #{scount}"
      log.write "  - #{(file_name+':').ljust(20)} #{(stotal.zero? ? 0 : 100*(stotal-scount)/stotal).round.to_s.rjust(3)}% (#{stotal-scount}/#{stotal})\n"
      File.open(target_path, "wb") do |file|
        file.write("#{locale}:\n")
        file.write(translation)
      end
    end
    log.write "  - Total:               #{(100*(total-count)/total).round.to_s.rjust(3)}% (#{total-count}/#{total})\n"
    # Missing help files
    # log.write "  - help: # Missing files\n"
    for controller, actions in useful_actions
      for action in actions
        if File.exists?(Rails.root.join('app', 'views', controller.to_s, "#{action}.html.haml")) or (File.exists?("#{Rails.root.to_s}/app/views/#{controller}/_#{action.gsub(/_[^_]*$/,'')}_form.html.haml") and action.split("_")[-1].match(/create|update/))
          help = "#{Rails.root.to_s}/config/locales/#{locale}/help/#{controller}-#{action}.txt"
          # log.write "    - #{help.gsub(Rails.root.to_s,'.')}\n" unless File.exists?(help)
        end
      end
    end
    puts " - Locale: #{(100*(total-count)/total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated from #{reference_label}" # reference
  end

  log.close
end
