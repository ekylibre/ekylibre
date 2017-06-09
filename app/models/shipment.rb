# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2017 Brice Texier, David Joulin
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
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: parcels
#
#  accounted_at                         :datetime
#  address_id                           :integer
#  contract_id                          :integer
#  created_at                           :datetime         not null
#  creator_id                           :integer
#  currency                             :string
#  custom_fields                        :jsonb
#  delivery_id                          :integer
#  delivery_mode                        :string
#  given_at                             :datetime
#  id                                   :integer          not null, primary key
#  in_preparation_at                    :datetime
#  journal_entry_id                     :integer
#  lock_version                         :integer          default(0), not null
#  nature                               :string           not null
#  number                               :string           not null
#  ordered_at                           :datetime
#  planned_at                           :datetime         not null
#  position                             :integer
#  prepared_at                          :datetime
#  pretax_amount                        :decimal(19, 4)   default(0.0), not null
#  purchase_id                          :integer
#  recipient_id                         :integer
#  reference_number                     :string
#  remain_owner                         :boolean          default(FALSE), not null
#  responsible_id                       :integer
#  sale_id                              :integer
#  sender_id                            :integer
#  separated_stock                      :boolean
#  state                                :string           not null
#  storage_id                           :integer
#  transporter_id                       :integer
#  type                                 :string
#  undelivered_invoice_journal_entry_id :integer
#  updated_at                           :datetime         not null
#  updater_id                           :integer
#  with_delivery                        :boolean          default(FALSE), not null
#
class Shipment < Parcel
  belongs_to :recipient, class_name: 'Entity'
  belongs_to :sale, inverse_of: :parcels
  validates :recipient, presence: true
	before_save do
		self.nature = 'outgoing'
	end

	# This method permits to add stock journal entries corresponding to the
  # incoming or outgoing parcels.
  # It depends on the preferences which permit to activate the "permanent stock
  # inventory" and "automatic bookkeeping".
  #
  # | Parcel mode            | Debit                      | Credit                    |
  # | incoming parcel        | stock (3X)                 | stock_movement (603X/71X) |
  # | outgoing parcel        | stock_movement (603X/71X)  | stock (3X)                |
  bookkeep do |b|
    # For purchase_not_received or sale_not_emitted
    invoice = lambda do |usage, order|
      lambda do |entry|
        label = tc(:undelivered_invoice,
                   resource: self.class.model_name.human,
                   number: number, entity: entity.full_name, mode: nature.l)
        account = Account.find_or_import_from_nomenclature(usage)
        items.each do |item|
          amount = (item.trade_item && item.trade_item.pretax_amount) || item.stock_amount
          next unless item.variant && item.variant.charge_account && amount.nonzero?
          if order
            entry.add_credit label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_debit  label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          else
            entry.add_debit  label, account.id, amount, resource: item, as: :unbilled, variant: item.variant
            entry.add_credit label, item.variant.charge_account.id, amount, resource: item, as: :expense, variant: item.variant
          end
        end
      end
    end

    ufb_accountable = Preference[:unbilled_payables] && given?
    # For unbilled payables
    journal = unsuppress { Journal.used_for_unbilled_payables!(currency: self.currency) }

    b.journal_entry(journal, printed_on: printed_on, as: :undelivered_invoice, if: ufb_accountable, &invoice.call(:invoice_to_create_clients, false))

    accountable = Preference[:permanent_stock_inventory] && given?
    # For permanent stock inventory
    journal = unsuppress { Journal.used_for_permanent_stock_inventory!(currency: self.currency) }
    b.journal_entry(journal, printed_on: printed_on, if: (Preference[:permanent_stock_inventory] && given?)) do |entry|
      label = tc(:bookkeep, resource: self.class.model_name.human,
                            number: number, entity: entity.full_name, mode: nature.l)
      items.each do |item|
        variant = item.variant
        next unless variant && variant.storable? && item.stock_amount.nonzero?
        entry.add_debit(label, variant.stock_movement_account_id, item.stock_amount, resource: item, as: :stock_movement, varinafat: item.variant)
        entry.add_credit(label, variant.stock_account_id, item.stock_amount, resource: item, as: :stock, variant: item.variant)
      end
    end
  end

  def third_id
    recipient_id
  end

  def third
    recipient
  end

  alias :entity :third

  def invoiced?
    sale.present?
  end

  class << self

	  # Convert parcels to one sale. Assume that all parcels are checked before.
	  # Sale is written in DB with default values
	  def convert_to_sale(parcels)
	    sale = nil
	    transaction do
	      parcels = parcels.collect do |d|
	        (d.is_a?(self) ? d : find(d))
	      end.sort_by(&:first_available_date)
	      third = detect_third(parcels)
	      planned_at = parcels.last.first_available_date || Time.zone.now
	      unless nature = SaleNature.actives.first
	        unless journal = Journal.sales.opened_on(planned_at).first
	          raise 'No sale journal'
	        end
	        nature = SaleNature.create!(
	          active: true,
	          currency: Preference[:currency],
	          with_accounting: true,
	          journal: journal,
	          by_default: true,
	          name: SaleNature.tc('default.name', default: SaleNature.model_name.human)
	        )
	      end
	      sale = Sale.create!(
	        client: third,
	        nature: nature,
	        # created_at: planned_at,
	        delivery_address: parcels.last.address
	      )

	      # Adds items
	      parcels.each do |parcel|
	        parcel.items.each do |item|
	          # raise "#{item.variant.name} cannot be sold" unless item.variant.saleable?
	          next unless item.variant.saleable? && item.population && item.population > 0
	          catalog_item = Catalog.by_default!(:sale).items.find_by(variant: item.variant)
	          item.sale_item = sale.items.create!(
	            variant: item.variant,
	            unit_pretax_amount: (catalog_item ? catalog_item.amount : 0.0),
	            tax: item.variant.category.sale_taxes.first || Tax.first,
	            quantity: item.population
	          )
	          item.save!
	        end
	        parcel.reload
	        parcel.sale_id = sale.id
	        parcel.save!
	      end

	      # Refreshes affair
	      sale.save!
	    end
	    sale
	  end
	end

end
