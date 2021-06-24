# frozen_string_literal: true

module Printers
  class ActivityCostPrinter < PrinterBase

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
    # Set Current intervention as instance variable @intervention
    def initialize(*_args, template:, **options)
      super(template: template)
      @campaign = options[:campaign]
      @activity = options[:activity] if options[:activity]
    end

    # Generate document name
    def document_name
      if @activity
        "#{template.nature.human_name} : #{@activity.name} #{@campaign.name}"
      else
        "#{template.nature.human_name} : #{@campaign.name}"
      end
    end

    # Create document key
    def key
      self.class.build_key(campaign: @campaign)
    end

    # @param [Intervention] intervention
    # @return [String] human_date
    def human_date(intervention)
      I18n.locale = :fra
      if intervention.started_at.to_date == intervention.stopped_at.to_date
        intervention.stopped_at.strftime("%d/%m/%y")
      else
        :from_to_date.tl(from: intervention.started_at.strftime("%d/%m/%y"), to: intervention.stopped_at.strftime("%d/%m/%y"))
      end
    end

    # @param [Integer] duration in ms
    # @return [String] human duration
    def human_duration(ms)
      if (hour = ms/3600) < 1
        "#{ms/3600} min"
      elsif hour > 24 || (remainder = ms % 3600) == 0
        "#{hour}h"
      else
        "#{hour}h#{remainder / 60}"
      end
    end

    def compute_dataset
      currency = Onoma::Currency.find(Preference[:currency]).symbol
      activities = if @activity
                     [@activity]
                   else
                     @campaign.activities
                   end.map do |activity|
        if @campaign.interventions.of_activity(activity).present?
          {
            name: activity.name,
            area: activity.net_surface_area(@campaign).in_hectare,
            summary: [{
              name: activity.name,
              int_count: "#{@campaign.interventions.of_activity(activity).count} interventions",
              total_duration: human_duration(activity.interventions.sum(&:duration))
            }.merge(activity.decorate.production_costs(@campaign)[:global_costs])],
            interventions: @campaign.interventions.of_activity(activity).order('STARTED_AT').map do |intervention|
              {
                name: intervention.name,
                date: human_date(intervention),
                targets: intervention.human_target_names,
                duration: human_duration(intervention.duration),
                ratio: intervention.activity_imputation(activity).to_f
              }.merge(intervention.costing.decorate.to_human_h)
            end
          }
        end
      end.compact
      activities.each do |act|
        # Multiplying every intervention cost by it's activity ratio
        act[:interventions].each do |int|
          %i[inputs tools doers receptions].each do |cost|
            int[cost] = int[cost] == 0 ? nil : (int[cost]  * int[:ratio])
          end
        end
        # Calculating each total cost, with/without area dimension
        summary = act[:summary].first
        %i[inputs tools doers receptions].each do |cost|
          total_cost = summary[cost].nil? ? 0 : summary[cost]
          summary[cost] = total_cost.round_l << currency
          summary["#{cost}_ha".to_sym] =  act[:area].to_f != 0 ? (total_cost/act[:area].to_f).to_i.to_s << "#{currency}/ha" : "0€/ha"
        end
      end
      activities
    end

    def generate(r)
      company = Entity.of_company
      currency = Onoma::Currency.find(Preference[:currency]).symbol
      dataset = compute_dataset
      r.add_field 'CAMPAIGN_NAME', @campaign.name
      r.add_field 'EXPORT_DATE', Time.now.strftime("%d/%m/%y")
      r.add_field 'COMPANY_NAME', company.name
      r.add_field 'COMPANY_ADDRESS', company.mails.where(by_default: true).first.coordinate
      r.add_field 'COMPANY_SIRET', company.siret_number
      r.add_field 'FILENAME', document_name
      r.add_section(:section_activity, dataset) do |s|
        s.add_field(:activity_name) { |act| act[:name]}
        s.add_field(:activity_area) { |act| act[:area].round_l}
        s.add_table(:table_summary, :summary) do |ts|
          ts.add_field(:activity_name) { |act| act[:name]}
          ts.add_field(:int_count) { |act| act[:int_count]}
          ts.add_field(:int_durs) { |act| act[:total_duration]}
          ts.add_field(:total_inputs) { |act| act[:inputs]}
          ts.add_field(:total_tools) { |act| act[:tools]}
          ts.add_field(:total_moeuvre) { |act| act[:doers]}
          ts.add_field(:total_service) { |act| act[:receptions]}
          ts.add_field(:total_inputs_ha) { |act| act[:inputs_ha]}
          ts.add_field(:total_tools_ha) { |act| act[:tools_ha]}
          ts.add_field(:total_moeuvre_ha) { |act| act[:doers_ha]}
          ts.add_field(:total_service_ha) { |act| act[:receptions_ha]}
        end
        s.add_table(:table_interventions, :interventions) do |t|
          t.add_field(:campaign_name, @campaign.name)
          t.add_field(:int_date) { |int| int[:date]}
          t.add_field(:int_name) { |int| int[:name]}
          t.add_field(:int_tars) { |int| int[:targets]}
          t.add_field(:int_ratio) { |int| int[:ratio]}
          t.add_field(:int_duration) { |int| int[:duration]}
          t.add_field(:int_inputs) { |int|  int[:inputs].nil? ? nil : "#{int[:inputs].round_l}#{currency}"}
          t.add_field(:int_tools) { |int| int[:tools].nil? ? nil : "#{int[:tools].round_l}#{currency}"}
          t.add_field(:int_service) { |int| int[:receptions].nil? ? nil : "#{int[:receptions].round_l}#{currency}"}
          t.add_field(:int_mo) { |int| int[:doers].nil? ? nil : "#{int[:doers].round_l}#{currency}"}
        end
      end
    end

  end
end
