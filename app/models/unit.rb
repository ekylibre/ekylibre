# == Schema Information
#
# Table name: units
#
#  base         :string(255)   not null
#  company_id   :integer       not null
#  created_at   :datetime      not null
#  creator_id   :integer       
#  id           :integer       not null, primary key
#  label        :string(255)   not null
#  lock_version :integer       default(0), not null
#  name         :string(8)     not null
#  quantity     :decimal(, )   not null
#  updated_at   :datetime      not null
#  updater_id   :integer       
#

class Unit < ActiveRecord::Base
  attr_readonly :company_id
  belongs_to :company
  has_many :products

  @@units = ["m", "kg", "s", "A", "K", "mol", "cd"]

  def self.default_units
    { 
      :u=> {:base=>'u',  :quantity=>1},
      :kg=>{:base=>'g',  :quantity=>1000},
      :t=> {:base=>'g',  :quantity=>1000000},
      :m=> {:base=>'m',  :quantity=>1},
      :km=>{:base=>'m',  :quantity=>1000},
      :ha=>{:base=>'m2', :quantity=>10000},
      :a=> {:base=>'m2', :quantity=>100},
      :ca=>{:base=>'m2', :quantity=>1},
      :l=> {:base=>'m3', :quantity=>0.001},
      :hl=>{:base=>'m3', :quantity=>0.1},
      :m3=>{:base=>'m3', :quantity=>1}
    }
  end

  def before_validation
    self.normalized_expression = self.class.normalize(self.expression)
  end

  def self.normalize(expr)
    expression = expr.dup
    expression.strip!
    
    # flatten
    flat = expression.split(/[\.\s]+/).collect do |x|
      if x.match(/^\d+(\,\d+)?/) # coefficient
        x
      elsif x.match(/[a-z]+(\-\d+)?/i) # unit
        name = x.gsub(/[0-9\-]+/,'')
        if @@units.include? name
          x
        elsif unit = Unit.find_by_name(name)
          unit.normalized_expression.to_s
        else
          raise Exception.new "Unknown unit #{name.inspect}"
        end
      else  
        raise Exception.new "Bad expression: error on #{x.inspect}"
      end
    end.join(".")
    
    # reduce
    coeff = 1
    exps = {}
    flat.split(/[\.\s]+/).each do |x|
      if x.match(/^\d+(\,\d+)?/)
        coeff *= x.gsub(",", ".").to_f
      else
        name = x.gsub(/[0-9\-]+/,'')
        exps[name] = (exps[name]||0)+(x == name ? 1 : x.gsub(/[a-z]+/i,'').to_i)
      end
    end

    # magnify
    normalized = ""
    if coeff != 0
      normalized += coeff.to_s.gsub(".", ",")+" " if coeff != 1
      exps.sort.each{|k,v| normalized += k+(v!=1 ? v.to_s : "")+"." if v != 0}
    end
    return normalized.gsub(/(^[\.\s]+|[\.\s]+$)/, "")
  end


  def destroyable?
    return false
  end

end
