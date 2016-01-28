module NomenHelper

  AVATARS_INDEX = Rails.root.join('db', 'nomenclatures', 'avatars.yml').freeze
  AVATARS = (AVATARS_INDEX.exist? ? YAML.load_file(AVATARS_INDEX) : {}).freeze

  def item_avatar_path(item)
    nomenclature = AVATARS[item.nomenclature.table_name]
    return nil unless nomenclature
    return item.rise { |i| nomenclature[i.name] }
  end

  def activity_avatar_path(activity)
    if (variety = Nomen::Variety.find(activity.cultivation_variety))
      path = item_avatar_path(variety)
    end
    unless path
      path = item_avatar_path Nomen::ActivityFamily.find(activity.family)
    end
    path
  end
end
