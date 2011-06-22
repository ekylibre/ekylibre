#
desc "Update and sort translation files"
task :locales => :environment do
  log = File.open(Rails.root.join("log", "clean.locales.log"), "wb")

  missing_prompt = "# "

  # Load of actions
  all_actions = {}
  for right, attributes in YAML.load_file(User.rights_file)
    for full_action in attributes['actions']
      controller, action = (full_action.match(/\:\:/) ? full_action.split(/\W+/)[0..1] : [attributes['controller'].to_s, full_action])
      all_actions[controller] ||= []
      all_actions[controller] << action unless action.match /dy(li|ta)|delete|kame/
    end if attributes['actions'].is_a? Array
  end
  useful_actions = all_actions.dup
  useful_actions.delete("authentication")
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
  translation += "  actions:\n"
  for controller_file in Dir[Rails.root.join("app", "controllers", "*.rb")].sort
    controller_name = controller_file.split("/")[-1].split("_controller")[0]
    actions = actions_in_file(controller_file, controller_name).sort
    existing_actions = ::I18n.translate("actions.#{controller_name}").stringify_keys.keys rescue []
    translateable_actions = (actions.delete_if{|a| [:update, :create, :destroy, :up, :down, :decrement, :increment, :duplicate, :reflect].include?(a.to_sym) or a.to_s.match(/^list(\_|$)/)}|existing_actions).sort
    if not translateable_actions.empty? and not [:interfacers].include?(controller_name.to_sym)
      translation += "    #{controller_name}:\n"
      for action_name in translateable_actions
        name = ::I18n.hardtranslate("actions.#{controller_name}.#{action_name}")
        to_translate += 1 
        if actions.include?(action_name)
          untranslated += 1 if name.blank?
        end
        translation += "      #{missing_prompt if name.blank?}#{action_name}: "+yaml_value(name.blank? ? "#{action_name}#{'_'+controller_name.singularize unless action_name.match(/^list/)}".humanize : name, 3)
        translation += " #!" unless actions.include?(action_name)
        translation += "\n"
      end
    end
  end

  # Controllers
  translation += "  controllers:\n"
  for controller_file in Dir[Rails.root.join("app", "controllers", "*.rb")].sort
    controller_name = controller_file.split(/[\\\/]+/)[-1].gsub('_controller.rb', '')
    name = ::I18n.hardtranslate("controllers.#{controller_name}")
    untranslated += 1 if name.blank?
    to_translate += 1
    translation += "    #{missing_prompt if name.blank?}#{controller_name}: "+yaml_value(name.blank? ? controller_name.humanize : name, 2)+"\n"
  end

  # Errors
  to_translate += hash_count(::I18n.translate("errors"))
  translation += "  errors:"+hash_to_yaml(::I18n.translate("errors"), 2)+"\n"

  # Labels
  to_translate += hash_count(::I18n.translate("labels"))
  translation += "  labels:"+hash_to_yaml(::I18n.translate("labels"), 2)+"\n"

  # Notifications
  translation += "  notifications:\n"
  notifications = ::I18n.t("notifications")
  deleted_notifs = ::I18n.t("notifications").keys
  for controller in Dir[Rails.root.join("app", "controllers", "*.rb")]
    File.open(controller, "rb").each_line do |line|
      if line.match(/([\s\W]+|^)notify\(\s*\:\w+/)
        key = line.split(/notify\(\s*\:/)[1].split(/\W/)[0]
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
    line.gsub!(/$/, " #!") if deleted_notifs.include?(key)
    translation += line+"\n"
  end
  warnings << "#{deleted_notifs.size} bad notifications" if deleted_notifs.size > 0

  # Preferences
  to_translate += hash_count(::I18n.translate("preferences"))
  translation += "  preferences:"+hash_to_yaml(::I18n.translate("preferences"), 2)

  File.open(locale_dir.join("action.yml"), "wb") do |file|
    file.write(translation)
  end
  total = to_translate
  log.write "  - #{'action.yml:'.ljust(16)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total}) #{warnings.to_sentence}\n"
  atotal += to_translate
  acount += total-untranslated
  

  count = sort_yaml_file :countries, log
  atotal += count
  acount += count

  count = sort_yaml_file :languages, log
  atotal += count
  acount += count

  # Models
  untranslated = 0
  to_translate = 0
  warnings = []
  models = {}
  attributes = {}
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
        else
          attributes[column] = [column.humanize, :undefined]
        end
      end
      for column in model.instance_methods
        attributes[column][1] = :used if attributes[column]
      end
    end
  end
  for k, v in models
    to_translate += 1 # if v[1]!=:unused
    untranslated += 1 if v[1]==:undefined
  end
  for k, v in attributes
    to_translate += 1 # if v[1]!=:unused
    untranslated += 1 if v[1]==:undefined
  end

  translation  = locale.to_s+":\n"
  translation += "  activerecord:\n"
  to_translate += hash_count(::I18n.translate("activerecord.attributes"))
  translation += "    attributes:"+hash_to_yaml(::I18n.translate("activerecord.attributes"), 3)+"\n"
  to_translate += hash_count(::I18n.translate("activerecord.errors"))
  translation += "    errors:"+hash_to_yaml(::I18n.translate("activerecord.errors"), 3)+"\n"
  translation += "    models:\n"
  for model, definition in models.sort
    translation += "      "
    translation += missing_prompt if definition[1] == :undefined
    translation += "#{model}: "+yaml_value(definition[0])
    translation += " #!" if definition[1] == :unused      
    translation += "\n"
  end
  translation += "  attributes:\n"
  for attribute, definition in attributes.sort
    translation += "    "
    translation += missing_prompt if definition[1] == :undefined
    translation += "#{attribute}: "+yaml_value(definition[0])
    translation += " #!" if definition[1] == :unused
    translation += "\n"
  end
  translation += "  models:\n"
  for model, definition in models.sort
    next unless definition[2]
    to_translate += hash_count(definition[2])
    translation += "    #{model}:"+yaml_value(definition[2], 2).gsub(/\n/, (definition[1] == :unused ? " #!\n" : "\n"))+"\n"
  end

  File.open(locale_dir.join("models.yml"), "wb") do |file|
    file.write(translation)
  end
  total = to_translate
  log.write "  - #{'models.yml:'.ljust(16)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total}) #{warnings.to_sentence}\n"
  atotal += to_translate
  acount += total-untranslated


  # Rights
  rights = YAML.load_file(User.rights_file)
  translation  = locale.to_s+":\n"
  translation += "  rights:\n"
  untranslated = 0
  for right in rights.keys.sort
    trans = ::I18n.pretranslate("rights.#{right}")
    untranslated += 1 if trans.match(/^\(\(\(.*\)\)\)$/)
    translation += "    #{right}: "+trans+"\n"
  end
  File.open(locale_dir.join("rights.yml"), "wb") do |file|
    file.write translation
  end
  total = rights.keys.size
  log.write "  - #{'rights.yml:'.ljust(16)} #{(100*(total-untranslated)/total).round.to_s.rjust(3)}% (#{total-untranslated}/#{total})\n"
  atotal += total
  acount += total-untranslated

  count = sort_yaml_file :support, log
  atotal += count
  acount += count


  #     log.write "  - help: # Missing files\n"
  #     for controller, actions in useful_actions
  #       for action in actions
  #         if File.exists?("#{Rails.root.to_s}/app/views/#{controller}/#{action}.html.haml") or (File.exists?("#{Rails.root.to_s}/app/views/#{controller}/_#{action.gsub(/_[^_]*$/,'')}_form.html.haml") and action.split("_")[-1].match(/create|update/))
  #           unless File.exist?("#{Rails.root.to_s}/config/locales/#{locale}/help/#{controller}-#{action}.txt") or File.exist?("#{Rails.root.to_s}/config/locales/#{locale}/help/#{controller}-#{action.to_s.split(/\_/)[0..-2].join('_').pluralize}.txt") or File.exist?("#{Rails.root.to_s}/config/locales/#{locale}/help/#{controller}-#{action.to_s.pluralize}.txt")
  #             log.write "    - ./config/locales/#{locale}/help/#{controller}-#{action}.txt\n" 
  #           end
  #         end
  #       end
  #     end

  # #     # wkl = [:zho, :cmn, :spa, :eng, :arb, :ara, :hin, :ben, :por, :rus, :jpn, :deu, :jav, :lah, :wuu, :tel, :vie, :mar, :fra, :kor, :tam, :pnb, :ita, :urd, :yue, :arz, :tur, :nan, :guj, :cjy, :pol, :msa, :bho, :awa, :ukr, :hsn, :mal, :kan, :mai, :sun, :mya, :ori, :fas, :mwr, :hak, :pan, :hau, :fil, :pes, :tgl, :ron, :ind, :arq, :nld, :snd, :ary, :gan, :tha, :pus, :uzb, :raj, :yor, :aze, :aec, :uzn, :ibo, :amh, :hne, :orm, :apd, :asm, :hbs, :kur, :ceb, :sin, :acm, :rkt, :tts, :zha, :mlg, :apc, :som, :nep, :skr, :mad, :khm, :bar, :ell, :mag, :ctg, :bgc, :dcc, :azb, :hun, :ful, :cat, :sna, :mup, :syl, :mnp, :zlm, :zul, :que, :ars, :pbu, :ces, :bjj, :aeb, :kmr, :bul, :lmo, :cdo, :dhd, :gaz, :uig, :nya, :bel, :aka, :swe, :kaz, :pst, :bfy, :xho, :hat, :kok, :prs, :ayn, :plt, :azj, :kin, :kik, :acq, :vah, :srp, :nap, :bal, :ilo, :tuk, :hmn, :tat, :gsw, :hye, :ayp, :lua, :ajp, :sat, :vec, :vls, :acw, :kon, :lmn, :sot, :nod, :tir, :sqi, :hil, :mon, :dan, :rwr, :kas, :min, :hrv, :suk, :heb, :mos, :wtm, :kng, :fin, :slk, :afr, :run, :grn, :vmf, :gug, :scn, :bik, :hoj, :nor, :czh, :sou, :hae, :tgk, :tsn, :man, :luo, :kat, :ayl, :aln, :ktu, :lug, :nso, :rmt, :umb, :kau, :wol, :kam, :knn, :mui, :wry, :myi, :doi, :gax, :ckb, :tso, :fuc, :quh, :afb, :gom, :bem, :bjn, :bug, :ace, :bcc, :mvf, :shn, :mzn, :ban, :glk, :knc, :lao, :glg, :tzm, :jam, :lit, :mey, :pms, :czo, :kab, :ewe, :vmw, :kmb, :sdh, :shi, :hrx, :als, :swv, :gdx]
  # #     wkl = [:ace, :acm, :acq, :acw, :aeb, :aec, :afb, :afr, :ajp, :aka, :aln, :als, :amh, :apc, :apd, :ara, :arb, :arq, :ars, :ary, :arz, :asm, :awa, :ayl, :ayn, :ayp, :azb, :aze, :azj, :bal, :ban, :bar, :bcc, :bel, :bem, :ben, :bfy, :bgc, :bho, :bik, :bjj, :bjn, :bug, :bul, :cat, :cdo, :ceb, :ces, :cjy, :ckb, :cmn, :ctg, :czh, :czo, :dan, :dcc, :deu, :dhd, :doi, :ell, :eng, :ewe, :fas, :fil, :fin, :fra, :fuc, :ful, :gan, :gax, :gaz, :gdx, :glg, :glk, :gom, :grn, :gsw, :gug, :guj, :hae, :hak, :hat, :hau, :hbs, :heb, :hil, :hin, :hmn, :hne, :hoj, :hrv, :hrx, :hsn, :hun, :hye, :ibo, :ilo, :ind, :ita, :jam, :jav, :jpn, :kab, :kam, :kan, :kas, :kat, :kau, :kaz, :khm, :kik, :kin, :kmb, :kmr, :knc, :kng, :knn, :kok, :kon, :kor, :ktu, :kur, :lah, :lao, :lit, :lmn, :lmo, :lua, :lug, :luo, :mad, :mag, :mai, :mal, :man, :mar, :mey, :min, :mlg, :mnp, :mon, :mos, :msa, :mui, :mup, :mvf, :mwr, :mya, :myi, :mzn, :nan, :nap, :nep, :nld, :nod, :nor, :nso, :nya, :ori, :orm, :pan, :pbu, :pes, :plt, :pms, :pnb, :pol, :por, :prs, :pst, :pus, :que, :quh, :raj, :rkt, :rmt, :ron, :run, :rus, :rwr, :sat, :scn, :sdh, :shi, :shn, :sin, :skr, :slk, :sna, :snd, :som, :sot, :sou, :spa, :sqi, :srp, :suk, :sun, :swe, :swv, :syl, :tam, :tat, :tel, :tgk, :tgl, :tha, :tir, :tsn, :tso, :tts, :tuk, :tur, :tzm, :uig, :ukr, :umb, :urd, :uzb, :uzn, :vah, :vec, :vie, :vls, :vmf, :vmw, :wol, :wry, :wtm, :wuu, :xho, :yor, :yue, :zha, :zho, :zlm, :zul]
  #     # Official languages
  #     wkl = [:eng, :arb, :cmn, :spa, :fra, :rus, :sqi, :deu, :hye, :aym, :ben, :cat, :kor, :hrv, :dan, :fin, :ell, :hun, :ita, :jpn, :swa, :msa, :mon, :nld, :urd, :fas, :por, :que, :ron, :smo, :srp, :sot, :slk, :slv, :swe, :tam, :tur, :afr, :amh, :aze, :bis, :bel, :mya, :bul, :nya, :sin, :pov, :hat, :crs, :div, :dzo, :est, :fij, :fil, :kat, :gil, :grn, :heb, :urd, :hin, :hmo, :iba, :ind, :gle, :isl, :kaz, :khm, :kir, :run, :lao, :nzs, :lat, :lav, :lit, :ltz, :mkd, :mlg, :mlt, :mri, :rar, :mah, :srp, :nau, :nep, :nor, :uzb, :pus, :pau, :pol, :sag, :swb, :sna, :nde, :som, :tgk, :tzm, :ces, :tet, :tir, :tha, :tpi, :ton, :tuk, :tvl, :ukr, :vie]
  #     for reference_path in Dir.glob(Rails.root.join("config", "locales", "*", "languages.yml")).sort
  #       lh = yaml_to_hash(reference_path)||{}
  #       # puts lh.to_a[0][1][:languages].inspect
  #       next if lh.to_a[0][1][:languages].nil?
  #       lh.to_a[0][1][:languages].delete_if{|k,v| not wkl.include? k.to_s.to_sym}
  #       translation = hash_to_yaml(lh)
  #       File.open(reference_path.to_s, "wb") do |file|
  #         file.write(translation.strip)
  #       end
  #     end



  #     # ldir = Rails.root.join("config", "locales", locale.to_s)
  #     ldir = Rails.root.join("lcx", locale.to_s)
  #     FileUtils.makedirs(ldir)
  #     for reference_path in Dir.glob(Rails.root.join("config", "locales", ::I18n.default_locale.to_s, "*.yml")).sort
  #       file_name = reference_path.split(/[\/\\]+/)[-1]
  #       target_path = ldir.join(file_name)
  #       translation = hash_to_yaml(yaml_to_hash(reference_path))
  #       File.open(target_path, "wb") do |file|
  #         file.write(translation.strip)
  #       end
  #     end

  
  # puts " - Locale: #{::I18n.locale_label} (Reference)"
  total, count = atotal, acount
  log.write "  - Total:           #{(100*count/total).round.to_s.rjust(3)}% (#{count}/#{total})\n"
  puts " - Locale: #{(100*count/total).round.to_s.rjust(3)}% of #{::I18n.locale_label} translated (Reference)"
  reference_label = ::I18n.locale_name




  for locale in ::I18n.available_locales.delete_if{|l| l==::I18n.default_locale or l.to_s.size!=3}.sort{|a,b| a.to_s<=>b.to_s}
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
      log.write "  - #{(file_name+':').ljust(16)} #{(100*(stotal-scount)/stotal).round.to_s.rjust(3)}% (#{stotal-scount}/#{stotal})\n"
      File.open(target_path, "wb") do |file|
        file.write("#{locale}:\n")
        file.write(translation)
      end
    end
    log.write "  - Total:           #{(100*(total-count)/total).round.to_s.rjust(3)}% (#{total-count}/#{total})\n"
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
