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
      code << "unless params[:state].blank?\n"
      code << "  c[0] << ' AND #{FixedAsset.table_name}.state IN (?)'\n"
      code << "  c << params[:state]\n"
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
      t.column :accounted, datatype: :boolean
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
      key = "#{Nomen::DocumentNature.find(:fixed_asset_registry).name}-#{Time.zone.now.l(format: '%Y-%m-%d-%H:%M:%S')}"

      respond_to do |format|
        format.html do
          @fixed_assets = FixedAsset.all.reorder(:started_on)
          # passing a parameter to Jasper for company full name and id
          @entity_of_company_full_name = Entity.of_company.full_name
          @entity_of_company_id = Entity.of_company.id

          respond_with @fixed_assets, methods: [:net_book_value], include: %i[asset_account expenses_account allocation_account product]
        end

        format.pdf do
          FixedAssetExportJob.perform_later('fixed_asset_registry', key, params[:nature], params[:period], current_user)
          notify_success(:document_in_preparation)
          redirect_to :back
        end
      end
    end

    def show
      # passing a parameter to Jasper for company full name and id
      @entity_of_company_full_name = Entity.of_company.full_name
      @entity_of_company_id = Entity.of_company.id

      return unless @fixed_asset = find_and_check
      t3e @fixed_asset
      notify_warning_now(:closed_financial_periods) unless @fixed_asset.on_unclosed_periods?
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

    def create
      @fixed_asset = resource_model.new(parameters_with_processed_percentage)
      return if save_and_redirect(@fixed_asset, url: (params[:create_and_continue] ? {:action=>:new, :continue=>true} : (params[:redirect] || ({ action: :show, id: 'id'.c }))), notify: ((params[:create_and_continue] || params[:redirect]) ? :record_x_created : false), identifier: :name)
      render(locals: { cancel_url: {:action=>:index}, with_continue: false })
    end

    def update
      return unless @fixed_asset = find_and_check(:fixed_asset)
      t3e(@fixed_asset.attributes)
      @fixed_asset.attributes = parameters_with_processed_percentage
      return if save_and_redirect(@fixed_asset, url: params[:redirect] || ({ action: :show, id: 'id'.c }), notify: (params[:redirect] ? :record_x_updated : false), identifier: :name)
      render(locals: { cancel_url: {:action=>:index}, with_continue: false })
    end

    def depreciate_all
      begin
        bookkeep_until = Date.parse(params[:until])
      rescue
        notify_error(:the_bookkeep_date_format_is_invalid)
        return redirect_to(params[:redirect] || { action: :index })
      end

      if FinancialYear.on(bookkeep_until)
        count = FixedAsset.depreciate(until: bookkeep_until)
        notify_success(:x_fixed_asset_depreciations_have_been_bookkept_successfully, count: count)
        redirect_to(params[:redirect] || { action: :index })
      else
        notify_error(:need_financial_year_over_entire_period)
        redirect_to(params[:redirect] || { action: :index })
      end
    end

    def sell
      return unless record = find_and_check

      ok = record.sell
      record.errors.messages.each do |field, message|
        notify_error :error_on_field, { field: FixedAsset.human_attribute_name(field), message: message.join(", ") }
      end

      redirect_action = ok ? :show : :edit
      redirect_to params[:redirect] || { action: redirect_action, id: record.id }
      record
    end

    def scrap
      return unless record = find_and_check

      ok = record.scrap
      record.errors.messages.each do |field, message|
        notify_error :error_on_field, { field: FixedAsset.human_attribute_name(field), message: message.join(", ") }
      end

      redirect_action = ok ? :show : :edit
      redirect_to params[:redirect] || { action: redirect_action, id: record.id }
      record
    end

    def start_up
      return unless record = find_and_check

      ok = record.start_up

      if ok == false && msg.respond_to?(:map)
        notify_error(map.collect(&:messages).map(&:values).flatten.join(', '))
      end

      redirect_to params[:redirect] || { action: :show, id: record.id }

      record
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
        fixed_assets = FixedAsset.where(id: fixed_asset_ids)
        unless fixed_assets.any?
          notify_error :no_fixed_assets_given
          redirect_to(params[:redirect] || { action: :index })
          return nil
        end
        fixed_assets
      end


      def parameters_with_processed_percentage
        parameters = permitted_params.to_h
        method = parameters.fetch('depreciation_method', nil)
        if method
          percentage_key = "#{method}_depreciation_percentage"
          depreciation_percentage = parameters.fetch(percentage_key, '')
          parameters['depreciation_percentage'] = depreciation_percentage if depreciation_percentage.present?
        end
        parameters.except('linear_depreciation_percentage', 'regressive_depreciation_percentage')
      end
  end
end
