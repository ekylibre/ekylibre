# == Schema Information
#
# Table name: sequences
#
#  id               :integer       not null, primary key
#  name             :string(255)   not null
#  format           :string(255)   not null
#  company_id       :integer       not null
#  created_at       :datetime      not null
#  updated_at       :datetime      not null
#  lock_version     :integer       default(0), not null
#  period           :string(255)   default("number"), not null
#  last_year        :integer       
#  last_month       :integer       
#  last_cweek       :integer       
#  last_number      :integer       
#  number_increment :integer       default(1), not null
#  number_start     :integer       default(1), not null
#  creator_id       :integer       
#  updater_id       :integer       
#

class Sequence < ActiveRecord::Base
  @@periods = Sequence.columns_hash.keys.select{|x| x.match(/^last_/)}.collect{|x| x[5..-1] }.sort
  @@replace = Regexp.new('\[('+@@periods.join('|')+')(\|(\d+)(\|([^\]]*))?)?\]')

  has_many :parameters, :as=>:record_value
  belongs_to :company
  attr_readonly :company_id
  validates_inclusion_of :period, :in => @@periods  

  def before_validation
    self.period ||= 'number'
  end

  def destroyable?
    self.parameters.size <= 0
  end

  def self.periods
    @@periods.collect{|p| [tc("periods.#{p}"), p]}.sort{|a,b| a[0]<=>b[0]}
  end

  def period_name
    tc("periods.#{self.period}") if self.period != "number"
  end

  def compute(number=nil)
    number ||= self.last_number
    today = Date.today
    self['format'].gsub(@@replace) do |m|
      key, size, pattern = $1, $3, $5
      string = (key == 'number' ? number :  today.send(key)).to_s
      size.nil? ? string : string.rjust(size.to_i, pattern||'0')
    end    
  end

  def next_value
    period = self.period
    if self.last_number.nil?
      self.last_number  = self.number_start
    else
      self.last_number += self.number_increment 
    end
    if period != 'number' and not self.send('last_'+period).nil?
      self.last_number = self.number_start if self.send('last_'+period) != Date.today.send(period)
    end
    self.save!
    self.compute
  end

end
