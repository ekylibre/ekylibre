# == Schema Information
# Schema version: 20090123112145
#
# Table name: delays
#
#  id           :integer       not null, primary key
#  name         :string(255)   not null
#  active       :boolean       not null
#  expression   :string(255)   default("0"), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  updated_at   :datetime      not null
#  created_by   :integer       
#  updated_by   :integer       
#  lock_version :integer       default(0), not null
#

class Delay < ActiveRecord::Base

  DELAY_SEPARATOR = ', '

  def before_validation
    self.expression = self.expression.squeeze(" ").lower
    self.expression.split(',').collect{|x| x.strip}.join(DELAY_SEPARATOR)
  end

  def validate
    errors.add(:expression, I18n.t('activerecord.errors.messages.invalid')) if self.compute(Date.today).nil?
  end

  def compute(started_on)    
    # dead_on =(born_on >> self.months) + self.days
    # dead_on = dead_on.end_of_month + self.additional_days if self.end_of_month
    steps = self.expression.to_s.split(DELAY_SEPARATOR)||[]
    stopped_on = started_on
    steps.each do |step|
      if step.match /^(eom|end of month|fdm|fin de mois)$/
        stopped_on = stopped_on.end_of_month
      elsif step.match /^\d+\ (jour|day)s?(\ (avant|ago))?$/
        words = step.split " "
        stopped_on += (words[2].nil? ? 1 : -1)*words[0].to_i
      else
        return nil
      end
    end
  end

end
