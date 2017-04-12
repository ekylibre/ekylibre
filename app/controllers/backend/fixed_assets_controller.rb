# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2012 Brice Texier
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

module Backend
  class FixedAssetsController < Backend::BaseController
    manage_restfully currency: 'Preference[:currency]'.c, depreciation_method: 'linear'

    unroll

    respond_to :pdf, :odt, :docx, :xml, :json, :html, :csv

    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    #   :activity_id
    def self.fixed_assets_conditions
      code = ''
      code = search_conditions(fixed_assets: %i[name number description]) + " ||= []\n"
      code << "if params[:period].present? && params[:period].to_s != 'all'\n"
      code << "  c[0] << ' AND #{FixedAsset.table_name}.started_on BETWEEN ? AND ?'\n"
      code << "  if params[:period].to_s == 'interval'\n"
      code << "    c << params[:started_on]\n"
      code << "    c << params[:stopped_on]\n"
      code << "  else\n"
      code << "    interval = params[:period].to_s.split('_')\n"
      code << "    c << interval.first\n"
      code << "    c << interval.second\n"
      code << "  end\n"
      code << "end\n"
      code << "if params[:fixed_asset_id].to_i > 0\n"
      code << "  c[0] += ' AND #{FixedAsset.table_name}.id = ?'\n"
      code << "  c << params[:fixed_asset_id]\n"
      code << "end\n"
      code << "if params[:product_id].to_i > 0\n"
      code << "  c[0] += ' AND #{FixedAsset.table_name}.product_id = ?'\n"
      code << "  c << params[:product_id]\n"
      code << "end\n"
      code << "c\n"
      code.c
    end

    list(conditions: fixed_assets_conditions) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :name, url: true
      t.column :asset_account, url: true
      t.status
      t.column :product, url: true
      t.column :depreciable_amount, currency: true
      t.column :started_on
      t.column :stopped_on
    end

    list(:depreciations, model: :fixed_asset_depreciations, conditions: { fixed_asset_id: 'params[:id]'.c }, order: :position) do |t|
      # t.action :edit, if: "RECORD.journal_entry.nil?".c
      t.column :position
      t.column :accountable
      t.column :locked
      t.column :amount, currency: true
      t.column :depreciable_amount, currency: true
      t.column :depreciated_amount, currency: true
      t.column :started_on
      t.column :stopped_on
      t.column :financial_year, url: true
      t.column :journal_entry, label_method: :number, url: true
    end

    # Show a list of fixed_assets
    def index
      @fixed_assets = FixedAsset.all.reorder(:started_on)
      # passing a parameter to Jasper for company full name and id
      @entity_of_company_full_name = Entity.of_company.full_name
      @entity_of_company_id = Entity.of_company.id

      respond_with @fixed_assets, methods: [:net_book_value], include: %i[asset_account expenses_account allocation_account product]
    end

    def show
      # passing a parameter to Jasper for company full name and id
      @entity_of_company_full_name = Entity.of_company.full_name
      @entity_of_company_id = Entity.of_company.id

      return unless @fixed_asset = find_and_check
      t3e @fixed_asset
      respond_with(@fixed_asset, methods: %i[net_book_value duration],
                                 include: [
                                   {
                                     depreciations: {
                                       methods: [],
                                       include: { journal_entry: {} }
                                     },
                                     purchase_items: {},
                                     asset_account: {},
                                     expenses_account: {},
                                     allocation_account: {},
                                     product: {}

                                   }
                                 ],
                                 procs: proc { |options| options[:builder].tag!(:url, backend_fixed_asset_url(@fixed_asset)) })
    end

    def depreciate_up_to
      begin
        date = Date.parse(params[:'depreciation-date'])
      rescue
        notify_error(:error_while_depreciating)
        return redirect_to(params[:redirect] || { action: :index })
      end

      depreciations = FixedAssetDepreciation.with_active_asset.up_to(date)
      success = true

      ActiveRecord::Base.transaction do
        # trusting the bookkeep to take care of the accounting
        depreciations.find_each { |dep| success &&= dep.update(accountable: true) }
        raise ActiveRecord::Rollback unless success
      end

      if success
        notify_success(:depreciation_successful)
      else
        notify_error(:depreciation_failed)
      end
      redirect_to(params[:redirect] || { action: :index })
    end

    # def cede
    #   return unless @fixed_asset = find_and_check
    # end

    # def sell
    #   return unless @fixed_asset = find_and_check
    # end

    FixedAsset.state_machine.events.each do |event|
      define_method event.name do
        fire_event(event.name)
      end
    end

    def depreciate
      fixed_assets = find_fixed_assets
      return unless fixed_assets

      unless fixed_assets.all?(&:depreciable?)
        notify_error(:all_fixed_assets_must_be_depreciable)
        redirect_to(params[:redirect] || { action: :index })
        return
      end
    end

    protected

    def find_fixed_assets
      fixed_asset_ids = params[:id].split(',')
      fixed_assets = fixed_asset_ids.map { |id| FixedAsset.find_by(id: id) }.compact
      unless fixed_assets.any?
        notify_error :no_fixed_assets_given
        redirect_to(params[:redirect] || { action: :index })
        return nil
      end
      fixed_assets
    end
  end
end
