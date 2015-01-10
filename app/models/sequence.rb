# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: sequences
#
#  company_id       :integer          not null
#  created_at       :datetime         not null
#  creator_id       :integer          
#  format           :string(255)      not null
#  id               :integer          not null, primary key
#  last_cweek       :integer          
#  last_month       :integer          
#  last_number      :integer          
#  last_year        :integer          
#  lock_version     :integer          default(0), not null
#  name             :string(255)      not null
#  number_increment :integer          default(1), not null
#  number_start     :integer          default(1), not null
#  period           :string(255)      default("number"), not null
#  updated_at       :datetime         not null
#  updater_id       :integer          
#


class Sequence < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :last_cweek, :last_month, :last_number, :last_year, :number_increment, :number_start, :allow_nil => true, :only_integer => true
  validates_length_of :format, :name, :period, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  @@periods = Sequence.columns_hash.keys.select{|x| x.match(/^last_/)}.collect{|x| x[5..-1] }.sort
  @@replace = Regexp.new('\[('+@@periods.join('|')+')(\|(\d+)(\|([^\]]*))?)?\]')

  attr_readonly :company_id
  belongs_to :company
  has_many :preferences, :as=>:record_value
  validates_inclusion_of :period, :in => @@periods  
  validates_uniqueness_of :format, :scope=>:company_id

  before_validation do
    self.period ||= 'number'
  end

  protect_on_destroy do
    self.preferences.size <= 0
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
    self.reload
    today = Date.today
    period = self.period
    if self.last_number.nil?
      self.last_number  = self.number_start
    else
      self.last_number += self.number_increment 
    end
    if period != 'number' and not self.send('last_'+period).nil?
      self.last_number = self.number_start if self.send('last_'+period) != today.send(period) or self.last_year != today.year
    end
    self.last_year, self.last_month, self.last_cweek = today.year, today.month, today.cweek
    self.save!
    self.compute
  end

end

