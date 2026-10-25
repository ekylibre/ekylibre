json.set! :pagination do
  json.call(@pagination, :elements, :page, :per_page, :total_elements, :page_count)
end

json.set! :data do
  json.array! @activity_productions do |production|
    activity = production.activity
    json.call(production, :id, :name, :started_on, :stopped_on, :state, :usage)

    json.activity do
      json.call(activity, :id, :name, :family, :nature, :production_cycle)
    end
    json.cultivation_variety activity.cultivation_variety
    json.cultivation_variety_name activity.human_cultivation_variety_name

    # Area of the support shape (nil when the production has no shape, e.g. animal groups)
    json.net_surface_area_value production.support_shape ? production.net_surface_area.to_d(:hectare).round(4).to_f : nil
    json.net_surface_area_unit production.support_shape ? 'hectare' : nil

    json.support do
      json.id production.support_id
      json.name production.support&.name
      json.nature production.support_nature
    end

    zone = production.cultivable_zone
    json.cultivable_zone zone ? { id: zone.id, name: zone.name, work_number: zone.work_number } : nil

    json.target_product_ids @target_product_ids[production.id]
  end
end
