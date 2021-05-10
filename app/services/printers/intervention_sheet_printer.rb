# frozen_string_literal: true

module Printers
  class InterventionSheetPrinter < PrinterBase
    class << self
      # TODO: move this elsewhere when refactoring the Document Management System
      def build_key(id:, updated_at:)
        "#{id}-#{updated_at}"
      end
    end

    # Set Intervention.id as instance variable @id
    #  Set Current intervention as instance variable @intervention
    def initialize(*_args, id:, template:, **_options)
      super(template: template)
      @id = id
      @intervention = Intervention.find_by_id(id)
    end

    #  Generate document name
    def document_name
      "#{template.nature.human_name} : #{@intervention.name}"
    end

    #  Create document key
    def key
      self.class.build_key(id: @id, updated_at: @intervention.updated_at.to_s)
    end

    #  @param [InterventionTarget] target
    #  @return [Float] worked_area per target in hectare
    def worked_area(target)
      worked_area = if target.working_area.present?
                      target.working_area
                    else
                      target.product.net_surface_area
                    end
      worked_area.in_hectare.round(3)
    end

    #  Intervention total area
    #  @return [Measure] area in hectare
    def total_area
      if @intervention.working_area.zero?
        @intervention.targets.inject(0){|sum, tar| sum + worked_area(tar).to_d}.in_hectare
      else
        @intervention.working_area.in_hectare
      end
    end

    # @param [InterventionInput] input
    #  @returns [String] unit symbol
    def input_unit(input, base = false)
      o_unit = if base
                 Onoma::Unit.find(input.input_quantity_per_area.base_unit)
               else
                 Onoma::Unit.find(input.quantity_unit_name)
               end
      if o_unit
        o_unit.symbol
      else
        input.product.unit_name
      end
    end

    #  @param [InterventionTarget] target
    #  @return [String] target area
    def target_area(target)
      "#{(100 * (worked_area(target) / target.product.net_surface_area.in_hectare)).to_i} %"
    end

    # @param [InterventionInput] input
    #  @return [String] input_rate
    def input_rate(input)
      if input.input_quantity_per_area.repartition_unit.present? || total_area.zero?
        input.input_quantity_per_area.round_l
      else
        "#{(input.quantity_value / total_area.to_d).round(2)} #{input_unit(input)}/ha"
      end
    end

    # @param [InterventionInput] input
    #  @param [InterventionTarget] target
    #  @return [String] input quantity on this target
    def input_quantity(input)
      if input.input_quantity_per_area.repartition_unit.present?
        "#{(input.quantity_value * total_area.to_d).round(2)} #{input_unit(input, base=true)}"
      else
        "#{input.input_quantity_per_area.to_d.round(2)} #{input_unit(input)}"
      end
    end

    def compute_dataset
      #  Create Targets
      targets = @intervention.targets.map do |target|
        if target.working_zone
          {
            name: target.product.name,
            type: target.product.nature.name,
            area: target.product&.net_surface_area.to_d,
            w_area: worked_area(target).to_d,
            pct: target_area(target)
          }
        else
          {
            name: target.product.name,
            type: target.product.nature.name
          }
        end
      end
      #  Create inputs for each targets
      inputs = @intervention.inputs.map do |input|
        {
         name: input.product.name,
         rate: input_rate(input),
         quantity: input_quantity(input)
        }
      end
      #  Create tools
      tools = @intervention.tools.map do |tool|
        {
          name: tool.product.name,
          nature: tool.product.nature.name
         }
      end
      #  Create doers
      doers = @intervention.doers.map do |doer|
        {
         name: doer.product.name
        }
      end
      {
        targets: targets,
        doers: doers,
        tools: tools,
        inputs: inputs
      }.to_struct
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
