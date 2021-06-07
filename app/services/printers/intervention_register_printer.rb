# frozen_string_literal: true

module Printers
  class InterventionRegisterPrinter < PrinterBase

    ANY_VARIETY = 'Sans disctinction'

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

    # Set Intervention.id as instance variable @id
    #  Set Current intervention as instance variable @intervention
    def initialize(*_args, template:, **options)
      super(template: template)
      @campaign = options[:campaign]
    end

    #  Generate document name
    def document_name
      "#{template.nature.human_name} : #{@campaign.name}"
    end

    #  Create document key
    def key
      self.class.build_key(campaign: @campaign)
    end

    def human_duration(ms)
      if (hour = ms/3600) < 1
        "#{ms/3600} min"
      elsif hour > 24 || (remainder = ms % 3600) == 0
        "#{hour}h"
      else
        "#{hour}h#{remainder / 60}"
      end
    end

    def worked_area(target)
      worked_area = if target.working_area.present?
                      target.working_area
                    else
                      target.product.net_surface_area
                    end
      worked_area.in_hectare.round_l
    end

    def compute_dataset
      interventions = if @activity
                        @activity.interventions.of_campaign(@campaign)
                      else
                        Intervention.of_campaign(@campaign)
                      end
      interventions = interventions.sort_by(&:started_at).map do |int|
        {
          name: int.name,
          nature: int.procedure.human_name,
          started_at: int.started_at.strftime("%d/%m/%y"),
          duration: human_duration(int.duration),
          params: [{
            doers: int.doers.map{|doer| doer.product.name},
            targets: int.targets.map{|target| "#{target.product.name} (#{worked_area(target)})"},
            tools: int.tools.map{|tool| tool.product.name},
            inputs: int.inputs.map{|input| "#{input.product.name} (#{input.quantity.round_l})"}
          }]
        }
      end
      {
        interventions: interventions,
        activity: @activity.present? ? @activity.name : ANY_VARIETY,
        empty_register: interventions.empty? ? [{}] : [],
        company: Entity.of_company
      }
    end

    def generate(r)
      dataset = compute_dataset
      #  Outside Tables
      r.add_field 'CAMPAIGN_NAME', @campaign.name
      r.add_field 'ACTIVITY_NAME', dataset.fetch(:activity)
      r.add_field 'EXPORT_DATE', Time.now.strftime("%d/%m/%y")
      r.add_field 'COMPANY_NAME', dataset.fetch(:company).name
      r.add_field 'COMPANY_ADDRESS', dataset.fetch(:company).mails.where(by_default: true).first.coordinate
      r.add_field 'COMPANY_SIRET', dataset.fetch(:company).siret_number
      r.add_field 'FILENAME', document_name
      #  Inside Table-intervention
      r.add_section(:section_intervention, dataset.fetch(:interventions)) do |s|
        s.add_field(:intervention_name) { |int| int[:name]}
        s.add_field(:intervention_nature) { |int| int[:nature]}
        s.add_field(:intervention_duration) { |int| int[:duration]}
        s.add_field(:intervention_date) { |int| int[:started_at]}
        s.add_table(:table_intervention, :params) do |t|
          t.add_table(:table_targets, :targets) do |ttar|
            ttar.add_field(:tar_name) { |tar| tar }
          end
          t.add_table(:table_doers, :doers) do |td|
            td.add_field(:doer_name) { |tar| tar }
          end
          t.add_table(:table_tools, :tools) do |tt|
            tt.add_field(:tool_name) { |tar| tar }
          end
          t.add_table(:table_inputs, :inputs) do |ti|
            ti.add_field(:input_name) { |tar| tar }
          end
        end
      end
      r.add_section(:section_no_intervention, dataset.fetch(:empty_register)) do |msg|
        msg
      end
    end

  end
end
