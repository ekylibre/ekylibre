# frozen_string_literal: true

class MasterBudget < LexiconRecord
  extend Enumerize
  include Lexiconable
  enumerize :direction, in: %i[revenue expense], predicates: true
  enumerize :frequency, in: %i[per_year per_month], predicates: true
  enumerize :mode, in: %i[uo output global production], default: 'uo', predicates: true
  scope :of_family, ->(family) { where(activity_family: Onoma::ActivityFamily.all(family)) }

  def first_used_on(year)
    Date.new(year, start_month, 0o1)
  end

  def year_repetition
    if per_year?
      repetition
    elsif per_month?
      repetition * 12
    else
      1
    end
  end

  def day_gap
    if year_repetition != 0
      360 / year_repetition
    else
      360
    end
  end

  # link to computation_method in budget_item [per_campaign per_production per_working_unit]
  def computation_method
    case mode
    when 'uo'
      'per_working_unit'
    when 'global'
      'per_campaign'
    when 'production'
      'per_production'
    when 'output'
      'per_working_unit'
    else
      'per_campaign'
    end
  end

end
