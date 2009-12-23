# == Schema Information
#
# Table name: units
#
#  base         :string(255)   not null
#  coefficient  :decimal(, )   default(1.0), not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  label        :string(255)   not null
#  lock_version :integer       default(0), not null
#  name         :string(8)     not null
#  start        :decimal(, )   default(0.0), not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Unit < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  has_many :products
  validates_format_of :name, :with=>/^[a-zA-Z][a-zA-Z0-9]*$/

  @@units = ["m", "kg", "s", "A", "K", "mol", "cd"]

  def self.default_units
    { 
      :u=> {},
      :kg=>{:base=>'kg'},
      :t=> {:base=>'kg', :coefficient=>1000},
      :m=> {:base=>'m'},
      :km=>{:base=>'m',  :coefficient=>1000},
      :ha=>{:base=>'m2', :coefficient=>10000},
      :a=> {:base=>'m2', :coefficient=>100},
      :ca=>{:base=>'m2'},
      :l=> {:base=>'m3', :coefficient=>0.001},
      :hl=>{:base=>'m3', :coefficient=>0.1},
      :m3=>{:base=>'m3'}
    }
  end

  def before_validation
    self.name.strip!
    self.coefficient ||= 1
    self.start ||= 0
    self.base = self.class.normalize(self.base)
  end

  def self.normalize(expr)
    expression = expr.to_s.dup
    expression.strip!
    
    # flatten
    flat = expression.split(/[\.\s]+/).collect do |x|
      if x.match(/[a-z]+(\-\d+)?/i)
        name = x.gsub(/[0-9\-]+/, '')
        raise Exception.new "Unknown unit #{name.inspect} (only base units #{@@units.join(', ')} are accepted)" unless @@units.include? name
      else  
        raise Exception.new "Bad expression: error on #{x.inspect}"
      end
      x
    end.join(".")
    
    # reduce
    exps = {}
    flat.split(/[\.\s]+/).each do |x|
      name = x.gsub(/[0-9\-]+/,'')
      exps[name] = (exps[name]||0)+(x == name ? 1 : x.gsub(/[a-z]+/i,'').to_i) 
    end

    # magnify
    exps.sort.collect{|k,v| k+(v!=1 ? v.to_s : "") if v != 0}.compact.join(".")
  end


  def destroyable?
    return false
  end

end
