# frozen_string_literal: true

module Printers
  class PlannedBudgetPrinter < PrinterBase

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

    def compute_dataset
      dataset = []
      if @activity
        activities = [@activity]
      else
        activities = @campaign.activities.reorder(:name)
      end
      activities_dataset = activities.map do |activity|
        ab = ActivityBudget.of_campaign(@campaign).of_activity(activity).first
        support_size = ab&.productions_size&.to_f
        support_size = 1.0 if support_size.nil? || support_size == 0.0
        if ab.present?
          {
            name: activity.name,
            activity_size: "#{support_size.round_l(precision: 2)} #{activity.size_unit&.symbol}",
            activity_expenses: ab.expenses_amount&.round_l(currency: ab.currency, precision: 2),
            activity_revenues: ab.revenues_amount&.round_l(currency: ab.currency, precision: 2),
            activity_balance: (ab.revenues_amount - ab.expenses_amount)&.round_l(currency: ab.currency, precision: 2),
            activity_pretax_expenses: ab.expenses_pretax_amount&.round_l(currency: ab.currency, precision: 2),
            activity_pretax_revenues: ab.revenues_pretax_amount&.round_l(currency: ab.currency, precision: 2),
            activity_pretax_balance: (ab.revenues_pretax_amount - ab.expenses_pretax_amount)&.round_l(currency: ab.currency, precision: 2),
            activity_pretax_expenses_per_support_size: (ab.expenses_pretax_amount / support_size)&.round_l(currency: ab.currency, precision: 2),
            activity_pretax_revenues_per_support_size: (ab.revenues_pretax_amount / support_size)&.round_l(currency: ab.currency, precision: 2),
            activity_pretax_balance_per_support_size: "#{((ab.revenues_pretax_amount / support_size) - (ab.expenses_pretax_amount / support_size))&.round_l(currency: ab.currency, precision: 2)} / #{activity.size_unit&.symbol}",
            expenses: ab.expenses.reorder(:id).map do |expense|
              {
                article_name: expense.variant_name,
                used_on: expense.used_on&.strftime("%d/%m/%y"),
                quantity: expense.quantity,
                unit: expense.unit&.name,
                unit_amount: expense.unit_amount&.round_l(currency: ab.currency, precision: 2),
                repetition: expense.repetition,
                frequency: expense.frequency.l,
                computation_method: expense.computation_method.l,
                global_pretax_amount: expense.global_pretax_amount&.round_l(currency: ab.currency, precision: 2),
                global_pretax_amount_per_support_size: (expense.global_pretax_amount / support_size)&.round_l(currency: ab.currency, precision: 2)
              }
            end,
            revenues: ab.revenues.reorder(:id).map do |revenue|
              {
                article_name: revenue.variant_name,
                used_on: revenue.used_on&.strftime("%d/%m/%y"),
                quantity: revenue.quantity,
                unit: revenue.unit&.name,
                unit_amount: revenue.unit_amount&.round_l(currency: ab.currency, precision: 2),
                repetition: revenue.repetition,
                frequency: revenue.frequency.l,
                computation_method: revenue.computation_method.l,
                global_pretax_amount: revenue.global_pretax_amount&.round_l(currency: ab.currency, precision: 2),
                global_pretax_amount_per_support_size: (revenue.global_pretax_amount / support_size)&.round_l(currency: ab.currency, precision: 2)
              }
            end
          }
        end
      end.compact
      summary = activities_dataset.map do |act|
        {
          name: "#{act[:name]} | #{act[:activity_size]}",
          expenses: act[:activity_expenses],
          revenues: act[:activity_revenues],
          balance: act[:activity_balance],
          pretax_expenses: act[:activity_pretax_expenses],
          pretax_revenues: act[:activity_pretax_revenues],
          pretax_balance: act[:activity_pretax_balance],
          pretax_expenses_per_support_size: act[:activity_pretax_expenses_per_support_size],
          pretax_revenues_per_support_size: act[:activity_pretax_revenues_per_support_size],
          pretax_balance_per_support_size: act[:activity_pretax_balance_per_support_size]
        }
      end.compact
      dataset << summary
      dataset << activities_dataset
      dataset
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
      r.add_table(:global_budget, dataset[0]) do |g|
        g.add_field(:name) { |act| act[:name]}
        g.add_field(:expenses) { |act| act[:expenses]}
        g.add_field(:revenues) { |act| act[:revenues]}
        g.add_field(:balance) { |act| act[:balance]}
        g.add_field(:pretax_expenses) { |act| act[:pretax_expenses]}
        g.add_field(:pretax_revenues) { |act| act[:pretax_revenues]}
        g.add_field(:pretax_balance) { |act| act[:pretax_balance]}
        g.add_field(:pss_expenses) { |act| act[:pretax_expenses_per_support_size]}
        g.add_field(:pss_revenues) { |act| act[:pretax_revenues_per_support_size]}
        g.add_field(:pss_balance) { |act| act[:pretax_balance_per_support_size]}
      end
      r.add_section(:section_activity, dataset[1]) do |s|
        s.add_field(:activity_name) { |act| act[:name]}
        s.add_field(:activity_size) { |act| act[:activity_size]}
        s.add_table(:table_expenses, :expenses) do |ts|
          ts.add_field(:article_name) { |expense| expense[:article_name]}
          ts.add_field(:used_on) { |expense| expense[:used_on]}
          ts.add_field(:quantity) { |expense| expense[:quantity]}
          ts.add_field(:unit) { |expense| expense[:unit]}
          ts.add_field(:unit_amount) { |expense| expense[:unit_amount]}
          ts.add_field(:g_amount) { |expense| expense[:global_pretax_amount]}
          ts.add_field(:gss_amount) { |expense| expense[:global_pretax_amount_per_support_size]}
          ts.add_field(:c_meth) { |expense| expense[:computation_method]}
          ts.add_field(:re) { |expense| expense[:repetition]}
          ts.add_field(:mom) { |expense| expense[:frequency]}
        end
        s.add_table(:table_revenues, :revenues) do |t|
          t.add_field(:article_name) { |revenue| revenue[:article_name]}
          t.add_field(:used_on) { |revenue| revenue[:used_on]}
          t.add_field(:quantity) { |revenue| revenue[:quantity]}
          t.add_field(:unit) { |revenue| revenue[:unit]}
          t.add_field(:unit_amount) { |revenue| revenue[:unit_amount]}
          t.add_field(:g_amount) { |revenue| revenue[:global_pretax_amount]}
          t.add_field(:gss_amount) { |revenue| revenue[:global_pretax_amount_per_support_size]}
          t.add_field(:c_meth) { |revenue| revenue[:computation_method]}
          t.add_field(:re) { |revenue| revenue[:repetition]}
          t.add_field(:mom) { |revenue| revenue[:frequency]}
        end
        s.add_field(:act_balance) { |act| act[:activity_pretax_balance]}
        s.add_field(:actss_balance) { |act| act[:activity_pretax_balance_per_support_size]}
      end
    end

  end
end
