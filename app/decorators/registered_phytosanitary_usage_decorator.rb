class RegisteredPhytosanitaryUsageDecorator < Draper::Decorator
  delegate_all

  def dose_quantity
    if object.dose_quantity.present?
      ActionController::Base.helpers.number_to_currency(object.dose_quantity, unit: object.dose_unit_name, separator: ',', precision: 2)
    else
      nil
    end
  end

  def development_stage_min
    if object.development_stage_min && !object.development_stage_max
      "Min : #{object.development_stage_min}"
    elsif !object.development_stage_min && object.development_stage_max
      "Max : #{object.development_stage_max}"
    elsif object.development_stage_min && object.development_stage_max
      "#{object.development_stage_min} - #{object.development_stage_max}"
    end
  end

  def usage_conditions
    return unless object.usage_conditions
    ApplicationController.helpers.picto_tag('info-circle', color: '#3f70ce', pointer: true, data: { toggle: 'modal', target: "#usage-conditions-modal-#{object.id}" })
  end

  def pre_harvest_delay
    object.pre_harvest_delay ? "#{object.pre_harvest_delay.in_full(:day)} j" : nil
  end

  def value_in_days(col)
    value = object.send(col)

    if value.present?
      "#{value} #{:day.tl.lower.pluralize(value)}"
    else
      nil
    end
  end

  def value_in_meters(col)
    value = object.send(col)

    if value.present?
      "#{value} m"
    else
      nil
    end
  end

  def link_to_ephy(col)
    ActionController::Base.helpers.content_tag(:a, href: "https://ephy.anses.fr/#{object.product.product_type}/#{object.product.name.gsub(' ', '-')}#usages", target: '_blank') do
      object.send(col).to_s
    end
  end
end
