# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: production_chains
#
#  comment      :text             
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class ProductionChain < Ekylibre::Record::Base
  has_many :operations, :class_name=>"ProductionChainWorkCenter", :order=>:position, :dependent=>:delete_all
  has_many :conveyors, :class_name=>"ProductionChainConveyor", :dependent=>:delete_all
  has_many :unused_conveyors, :class_name=>"ProductionChainConveyor", :conditions=>{:source_id=>nil, :target_id=>nil}
  has_many :input_conveyors, :class_name=>"ProductionChainConveyor", :conditions=>{:source_id=>nil}

  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :allow_nil => true, :maximum => 255
  validates_presence_of :name
  #]VALIDATORS]
  validates_uniqueness_of :name


  # Unused
  def play(from, responsible, inputs={})
    ActiveRecord::Base.transaction do
      token = self.tokens.create!
      from = ProductionChainWorkCenter.find_by_id(from.to_i) unless from.is_a? ProductionChainWorkCenter
      raise ArgumentError.new("The first argument must be a ProductionChainWorkCenter") unless from.is_a? ProductionChainWorkCenter
      responsible = Entity.find_by_id(responsible.to_i) unless responsible.is_a? Entity
      raise ArgumentError.new("The second argument must be a Entity") unless responsible.is_a? Entity

      operation = Operation.create!(:name=>tc(:operation_name, :name=>from.name, :token=>token.number), :production_chain_token=>token, :nature=>from.operation_nature, :started_at=>Time.now, :planned_on=>date.today, :moved_on=>Date.today, :responsible_id=>responsible.id)
      lines = []
      for k, v in inputs
        conveyor = ProductionChainConveyor.find(k.to_i)
        stock = ProductStock.find(v[:stock_id].to_i)
        lines << {:direction=>"in", :product=>conveyor.product, :quantity=>v[:quantity], :tracking=>stock.tracking, :warehouse=>stock.warehouse}
      end
      for conveyor in from.output_conveyors
        lines << {:direction=>"out", :product=>conveyor.product, :quantity=>v[:quantity], :tracking=>stock.tracking, :warehouse=>stock.warehouse}
      end
      operation.save_with_uses_and_lines([], lines)

    end
  end

end
