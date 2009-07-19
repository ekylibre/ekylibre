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
#  created_by       :integer       
#  updated_by       :integer       
#  lock_version     :integer       default(0), not null
#  period           :string(255)   default("number"), not null
#  last_year        :integer       
#  last_month       :integer       
#  last_cweek       :integer       
#  last_number      :integer       
#  number_increment :integer       default(1), not null
#  number_start     :integer       default(1), not null
#

class Sequence < ActiveRecord::Base
  @@periods = Sequence.columns_hash.keys.select{|x| x.match(/^last_/)}.collect{|x| x[5..-1] }
  @@replace = Regexp.new('\[('+@@periods.join('|')+')(\|(\d+)(\|([^\]]*))?)?\]')

  belongs_to :company
  attr_readonly :company_id
  validates_inclusion_of :period, :in => @@periods  

  def before_validation
    self.period ||= 'number'
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
    if period != 'number'
      self.last_number = self.number_start if self.send('last_'+period) != Date.today.send(period)
    end
    self.save
    self.compute
  end

end
