# frozen_string_literal: true

module Printers
  class PhytosanitaryRegisterPrinter < PrinterBase
    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(campaign:, activity: nil)
        if activity.present?
          "#{activity.name} - #{campaign.name}"
        else
          campaign.name
        end
      end
    end

    def initialize(*_args, campaign:, template:, **_options)
      super(template: template)

      @campaign = campaign
    end

    def get_productions_for_dataset
      ActivityProduction.of_campaign(campaign)
    end

    def key
      if activity.present?
        self.class.build_key campaign: campaign, activity: activity
      else
        self.class.build_key campaign: campaign
      end
    end

    def compute_dataset
      productions = get_productions_for_dataset.select { |production| production.plant_farming? || production.vine_farming? }
    end

    def generate(r)
      dataset = compute_dataset
      #  Outside Tables
      r.add_field 'INTERV_NAME', @intervention.name
      r.add_field 'INTERV_DATE', @intervention.started_at.strftime("%d/%m/%Y")
      r.add_field 'AREA', total_area.round_l
      r.add_field 'INTERV_DESC', @intervention.description
      # Inside Table-targets
      r.add_table('Table-target', dataset.targets, header: true) do |t|
        t.add_field(:tar_name) { |target| target[:name] }
        t.add_field(:tar_type) { |target| target[:type] }
        t.add_field(:tar_area) { |target| target[:area]}
        t.add_field(:tar_pct) { |target| target[:pct]}
        t.add_field(:tar_w_area) { |target| target[:w_area]}
      end
      #  Inside Table-input
      r.add_table('Table-input', dataset.inputs, header: true, skip_if_empty: true) do |t|
        t.add_field(:input_name) { |input| input[:name] }
        t.add_field(:input_rate) { |input| input[:rate] }
        t.add_field(:input_quantity) { |input| input[:quantity] }
      end
      #  Inside Table-worker
      r.add_table('Table-worker', dataset.doers, header: true, skip_if_empty: true) do |t|
        t.add_field(:worker_name) { |doer| doer[:name] }
      end
      #  Inside Table-tools
      r.add_table('Table-tools', dataset.tools, header: true, skip_if_empty: true) do |t|
        t.add_field(:tool_name) { |tool| tool[:name] }
        t.add_field(:tool_nature) { |tool| tool[:nature] }
      end
      r.add_field 'COMPANY_ADDRESS', Entity.of_company.default_mail_address&.coordinate
    end
  end
end
