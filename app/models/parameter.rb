# == Schema Information
#
# Table name: parameters
#
#  id                :integer       not null, primary key
#  name              :string(255)   not null
#  nature            :string(8)     default("u"), not null
#  string_value      :text          
#  boolean_value     :boolean       
#  integer_value     :integer       
#  decimal_value     :decimal(, )   
#  user_id           :integer       
#  company_id        :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  lock_version      :integer       default(0), not null
#  record_value_id   :integer       
#  record_value_type :string(255)   
#  creator_id        :integer       
#  updater_id        :integer       
#

class Parameter < ActiveRecord::Base
  @@natures = Parameter.columns_hash.keys.select{|x| x.match(/_value(_id)?$/)}.collect{|x| x.split(/_value/)[0] }
  @@conversions = {:float=>'decimal', :true_class=>'boolean', :false_class=>'boolean', :fixnum=>'integer'}
  belongs_to :company
  belongs_to :user
  belongs_to :record_value, :polymorphic=>true
  validates_inclusion_of :nature, :in => @@natures

  cattr_reader :reference
  attr_readonly :company_id, :user_id, :name, :nature

  def value
    self.send(self.nature+'_value')
  end

  def value=(object)
    if @@reference[self.name]
      self.nature = @@reference[self.name][:nature] 
      self.record_value_type = @@reference[self.name][:model].name if @@reference[self.name][:model]
    end
    if self.nature == 'record' and object.class.name != self.record_value_type
      begin
        self.send(self.nature.to_s+'_value=', self.record_value_type.constantize.find(object.to_i))
      rescue  
        self.record_value_id = nil
      end
    else
      self.send(self.nature.to_s+'_value=', object)
    end
  end

  def record?
    self.nature == 'record'
  end

  def self.tree_reference
    ref = {}
    for k, v in @@reference.sort
      w = k.split('.')[0]
      ref[w] ||= {}
      ref[w][k] = v
    end
    ref
  end

  private

  def self.convert(nature, string)
    case nature.to_sym
    when :boolean
      (string == "true" ? true : false)
    when :integer
      string.to_i
    when :decimal
      string.to_f
    else
      string
    end
  end

  def self.initialize_reference
    @@reference = {}
    file = File.open("#{RAILS_ROOT}/config/parameters.csv", "r")
    file.each_line do |line|
      unless line.match(/\#/)
        line   = line.strip.split(",")
        param  = line[0]
        nature = line[1]
        if nature
          @@reference[param] ||= {}
          @@reference[param][:nature] = nature
          if nature == 'record'
            @@reference[param][:model] = line[2].camelcase.constantize
          else
            @@reference[param][:default] = Parameter.convert(nature, line[2])
          end
        end
      end
    end
  end

  Parameter.initialize_reference

end
