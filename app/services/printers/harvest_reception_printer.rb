# frozen_string_literal: true

module Printers
  class HarvestReceptionPrinter < PrinterBase
    # for accessing to number_to_accountancy
    include ApplicationHelper

    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(period:)
        filters = [period]
        filters.reject(&:blank?).join(' - ')
      end
    end

    def initialize(crop_id: nil, driver_id: nil, storage_id: nil, period:, started_on: nil, stopped_on: nil, template:)
      super(template: template)

      @period = period
      @crop = Product.find(crop_id) if crop_id
      @driver = Worker.find(driver_id) if driver_id
      @storage = BuildingDivision.find(storage_id) if storage_id
      @template = template
      # build dates conditions from period options
      if @period == 'all'
        @started_on = FinancialYear.first_of_all.started_on
        @stopped_on = Date.today
      elsif @period == 'interval'
        @started_on = Date.parse(started_on)
        @stopped_on = Date.parse(stopped_on)
      else
        # period=2019-01-01_2019-12-31
        @started_on = Date.parse(@period.split('_').first)
        @stopped_on = Date.parse(@period.split('_').last)
      end
    end

    def key
      self.class.build_key(period: @period)
    end

    def document_name
      "#{@template.nature.human_name} | #{@period} (#{humanized_period})"
    end

    def humanized_period
      I18n.translate('labels.from_to_date', from: @started_on.l, to: @stopped_on.l)
    end

    def compute_dataset
      h = HashWithIndifferentAccess.new
      h[:data_filters] = []
      if @driver
        h[:data_filters] << :driver.tl + ' : ' + @driver.name
      end
      if @crop
        h[:data_filters] << :crop.tl + ' : ' + @crop.name
      end
      if @storage
        h[:data_filters] << :storage.tl + ' : ' + @storage.name
      end
      h[:dates] = []
      ihgs = IncomingHarvest.between(@started_on.to_time.beginning_of_day, @stopped_on.to_time.end_of_day).reorder(:received_at).group_by { |i| i.received_at.to_date }
      ihgs.each do |received_on, ihs|
        sh = HashWithIndifferentAccess.new
        sh[:received_on] = received_on.l
        sh[:total_day_quantity] = IncomingHarvest.where(id: ihs.map(&:id)).order(:quantity_unit).group_by(&:quantity_unit).collect do |_unit, ihs_day|
          ihs_day.map(&:quantity).sum.l(precision: 2, round: 2)
        end.to_sentence
        sh[:items] = []
        ihs.each do |ih|
          item = HashWithIndifferentAccess.new
          item[:number] = ih.number
          item[:t_number] = ih.ticket_number
          item[:received_at] = ih.received_at.strftime("%d/%m/%y %H:%M")
          item[:harvest_crops_name] = ih.human_crops_names
          item[:area] = ih.net_harvest_areas_sum
          item[:qt] = ih.quantity_value.to_f
          item[:unit] = ih.quantity_unit
          item[:driver] = ih.driver&.name
          item[:harvest_storages_name] = ih.human_storages_names
          sh[:items] << item
        end
        h[:dates] << sh
      end
      h
    end

    def generate(r)
      dataset = compute_dataset
      data_filters = dataset[:data_filters]

      e = Entity.of_company
      company_name = e.full_name
      company_address = e.default_mail_address&.coordinate

      r.add_field 'COMPANY_ADDRESS', company_address
      r.add_field 'DOCUMENT_NAME', document_name
      r.add_field 'FILE_NAME', key
      r.add_field 'PERIOD', humanized_period
      r.add_field 'DATE', Date.today.l
      r.add_field 'PRINTED_AT', Time.zone.now.l(format: '%d/%m/%Y %T')
      r.add_field 'DATA_FILTERS', data_filters * ' | '
      r.add_section(:section_dates, dataset[:dates]) do |s|
        s.add_column(:received_on)
        s.add_column(:total_day_quantity)
        s.add_table('W_ITEMS', :items, header: true) do |t|
          t.add_column(:number)
          t.add_column(:t_number)
          t.add_column(:received_at)
          t.add_column(:harvest_crops_name)
          t.add_column(:area)
          t.add_column(:qt)
          t.add_column(:unit)
          t.add_column(:driver)
          t.add_column(:harvest_storages_name)
        end
      end
    end
  end
end
