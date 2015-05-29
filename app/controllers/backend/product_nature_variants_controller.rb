# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::ProductNatureVariantsController < Backend::BaseController
  manage_restfully active: true

  manage_restfully_incorporation

  unroll :name, :unit_name, :number

  list do |t|
    t.action :edit
    t.action :destroy, if: :destroyable?
    t.column :name, url: true
    t.column :nature, url: true
    t.column :unit_name
  end

  list(:catalog_items, conditions: {variant_id: 'params[:id]'.c}) do |t|
    t.action :edit
    t.action :destroy
    t.column :name, url: true
    t.column :amount, url: true, currency: true
    t.column :all_taxes_included
    t.column :catalog, url: true
  end

  list(:products, conditions: {variant_id: 'params[:id]'.c}, order: {born_at: :desc}) do |t|
    t.column :name, url: true
    t.column :identification_number
    t.column :born_at
    t.column :net_mass
    t.column :net_volume
    t.column :population
  end


  # Returns quantifiers for a given variant
  def quantifiers
    return unless @product_nature_variant = find_and_check
  end



  def detail
    return unless @product_nature_variant = find_and_check
    infos = {
      name: @product_nature_variant.name,
      number: @product_nature_variant.number,
      depreciable: @product_nature_variant.depreciable?,
      unit: {
        name: @product_nature_variant.unit_name
      }
    }
    if @product_nature_variant.picture.file?
      infos[:picture] = @product_nature_variant.picture.url(:thumb)
    end
    if pictogram = @product_nature_variant.category.pictogram
      infos[:pictogram] = pictogram
    end
    catalog = nil
    if params[:catalog_id]
      catalog = Catalog.find(params[:catalog_id])
    elsif params[:sale_nature_id]
      catalog = SaleNature.find(params[:sale_nature_id]).catalog
    end
    if catalog and item = catalog.items.find_by(variant_id: @product_nature_variant.id)
      infos[:all_taxes_included] = item.all_taxes_included
      unless infos[:tax_id] = item.reference_tax
        if items = SaleItem.where(variant_id: @product_nature_variant.id) and items.any?
          infos[:tax_id] = items.order(id: :desc).first.tax_id
        else
          infos[:tax_id] = Tax.first.id
        end
      end
      if tax = Tax.find_by(id: infos[:tax_id])
        if item.all_taxes_included
          infos[:unit][:pretax_amount] = tax.pretax_amount_of(item.amount)
          infos[:unit][:amount] = item.amount
        else
          infos[:unit][:pretax_amount] = item.amount
          infos[:unit][:amount] = tax.amount_of(item.amount)
        end
      end
    elsif params[:mode] == "last_purchase_item"
      if items = PurchaseItem.where(variant_id: @product_nature_variant.id) and items.any?
        item = items.order(id: :desc).first
        infos[:tax_id] = item.tax_id
        infos[:unit][:pretax_amount] = item.pretax_amount
        infos[:unit][:amount] = item.amount
      end
    end
    render json: infos
  end

end
