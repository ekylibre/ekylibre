# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2013 Brice Texier, David Joulin
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
# == Table: products
#
#  address_id               :integer
#  asset_id                 :integer
#  born_at                  :datetime
#  category_id              :integer          not null
#  content_indicator_name   :string(255)
#  content_indicator_unit   :string(255)
#  content_maximal_quantity :decimal(19, 4)   default(0.0), not null
#  content_nature_id        :integer
#  created_at               :datetime         not null
#  creator_id               :integer
#  dead_at                  :datetime
#  default_storage_id       :integer
#  derivative_of            :string(120)
#  description              :text
#  father_id                :integer
#  id                       :integer          not null, primary key
#  identification_number    :string(255)
#  initial_arrival_cause    :string(120)
#  initial_container_id     :integer
#  initial_owner_id         :integer
#  initial_population       :decimal(19, 4)   default(0.0)
#  lock_version             :integer          default(0), not null
#  mother_id                :integer
#  name                     :string(255)      not null
#  nature_id                :integer          not null
#  number                   :string(255)      not null
#  parent_id                :integer
#  picture_content_type     :string(255)
#  picture_file_name        :string(255)
#  picture_file_size        :integer
#  picture_updated_at       :datetime
#  reservoir                :boolean          not null
#  tracking_id              :integer
#  type                     :string(255)
#  updated_at               :datetime         not null
#  updater_id               :integer
#  variant_id               :integer          not null
#  variety                  :string(120)      not null
#  work_number              :string(255)
#


class BuildingDivision < SubZone
  # TODO: Use acts_as_nested_set
  # acts_as_tree
  attr_readonly :reservoir
  # belongs_to :address, class_name: "EntityAddress"
  # belongs_to :establishment
  belongs_to :content_nature, class_name: "ProductNature"
  # has_many :purchase_items, class_name: "PurchaseItem"
  # has_many :sale_items, class_name: "SaleItem"
  # has_many :stock_moves, class_name: "ProductMove"
  # has_many :stock_transfers, class_name: "ProductTransfer"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  #]VALIDATORS]
  validates_presence_of :content_nature, if: :reservoir?

  # default_scope order(:name)
  scope :of_product, lambda { |product|
    where("(product_id = ? AND reservoir = ?) OR reservoir = ?", product.id, true, false)
  }

  validate do
    # TODO: Describe errors more precisely
    # if self.parent
    #   errors.add(:parent_id, :invalid) if self.parent.reservoir?
    #   if self.parent_id == self.id or self.parent_ids.include?(self.id) or self.child_ids.include?(self.id)
    #     errors.add(:parent_id, :invalid)
    #   end
    # end
  end

  # @FIXME
  # ActiveRecord::StatementInvalid in Backend::BuildingDivisions#index
  # PG::UndefinedColumn: ERROR:  column operation_tasks.subject_id does not exist
  #protect(on: :destroy) do
   # dependencies = 0
    #for k, v in self.class.reflections.select{|k, v| v.macro == :has_many}
    #  dependencies += self.send(k).count
    #end
    #return dependencies <= 0
  #end


  def can_receive?(product_id)
    #raise Exception.new product_id.inspect+self.reservoir.inspect
    reception = true
    if self.reservoir
      stocks = ProductStock.where(:product_id => self.product_id, :building_id => self.id)
      if !stocks.first.nil?
        reception = ((self.product_id == product_id) || (stocks.first.quantity <= 0))
        self.update_attributes!(:product_id => product_id) if stocks.first.quantity <= 0
        #if stocks.first.quantity <= 0
        for ps in stocks
          ps.destroy if ps.product_id != product_id and ps.quantity <=0
        end
        #end
      else
        self.update_attributes!(:product_id=>product_id)
      end
    end
    reception
  end

  # # obsolete
  # def can_receive(product_id)
  #   self.can_receive?(product_id)
  # end

  # TODO : adapt method to parent_place
  # Returns parent ids
  def parent_ids
    if self.parent
      return [self.parent_id] + self.parent.parent_ids
    else
      return []
    end
  end

  # Return child ids
  def child_ids
    ids = []
    for child in self.children
      ids << child.id
      ids += child.child_ids
    end
    return ids
  end

  # return Map SVG as String for a class
  # @TODO refactor it and put it in has_shape method
  def self.map_svg(options = {})
    ids = self.indicator_datum(:shape, at: options[:at]).pluck(:product_id)
    return "" unless ids.size > 0
    viewbox = self.shape_view_box.join(' ')
    code = "<svg xmlns=\"http://www.w3.org/2000/svg\" version=\"1.1\""
    code << " class=\"shape\" preserveAspectRatio=\"xMidYMid meet\" width=\"100%\" height=\"100%\" viewBox=\"#{viewbox}\" "
    code << ">"
    for product_id in ids
      if product = Product.find(product_id)
        product_shape = product.shape_as_svg.to_s
        code << "<path d=\"#{product_shape}\"/>"
      end
    end
    code << "</svg>"
    return code.html_safe
  end

end
