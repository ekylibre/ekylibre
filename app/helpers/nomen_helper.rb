module NomenHelper
  AVATARS_INDEX = Rails.root.join('db', 'nomenclatures', 'avatars.yml').freeze
  AVATARS = (AVATARS_INDEX.exist? ? YAML.load_file(AVATARS_INDEX) : {}).freeze

  COLORS_INDEX = Rails.root.join('db', 'nomenclatures', 'colors.yml').freeze
  COLORS = (COLORS_INDEX.exist? ? YAML.load_file(COLORS_INDEX) : {}).freeze

  def item_avatar_path(item, reference_name = nil)
    return nil unless item

    nomenclature = AVATARS[item.nomenclature.table_name]
    return nil unless nomenclature

    nomenclature[reference_name] || item.rise { |i| nomenclature[i.name] }
  end

  def activity_avatar_path(activity)
    variety = Onoma::Variety.find(activity.cultivation_variety)
    path = item_avatar_path(variety, activity.reference_name)
    path ||= item_avatar_path(Onoma::ActivityFamily.find(activity.family))
    path
  end

  def item_color(item)
    nomenclature = COLORS[item.nomenclature.table_name]
    return nil unless nomenclature

    item.rise { |i| nomenclature[i.name] }
  end

  def variety_color(activity)
    if (variety = Onoma::Variety.find(activity.cultivation_variety))
      path = item_color(variety)
    end
    path ||= item_color Onoma::ActivityFamily.find(activity.family)
    path
  end
end
