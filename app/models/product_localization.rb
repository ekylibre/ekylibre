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
# == Table: product_localizations
#
#  container_id :integer
#  created_at   :datetime         not null
#  creator_id   :integer
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  nature       :string(255)      not null
#  product_id   :integer          not null
#  started_at   :datetime         not null
#  stopped_at   :datetime         not null
#  transfer_id  :integer          not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

class ProductLocalization < Ekylibre::Record::Base
  belongs_to :container, :class_name => "Product"
  belongs_to :product
  enumerize :nature, :in => [:transfer, :interior, :exterior], :default => :interior, :predicates => true
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :nature, :allow_nil => true, :maximum => 255
  validates_presence_of :nature, :product, :started_at, :stopped_at
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values
  validates_presence_of :container, :if => :interior?

  def self.check_operation(operation)
    product = operation.product
    count = self.where(:product_id => operation.product_id, :started_at => operation.started_at).count
    if count < 1
      # self.create!(:product_id => operation.product_id, :container_id => operation.operand_id, :started_at => operation.started_at, :stopped_at => operation.stopped_at
    elsif count == 1
    else # count > 1
    end

  end


end
