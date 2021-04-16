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
      "#{template.nature.human_name}:#{@id}"
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
      worked_area.in_hectare.round(2)
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
    def input_unit(input)
      if o_unit = Onoma::Unit.find(input.quantity_unit_name)
        o_unit.symbol
      else
        input.product.unit_name
      end
    end

    #  @param [InterventionTarget] target
    #  @return [String] target area
    def target_area(target)
      "#{worked_area(target)} (#{(100 * (worked_area(target) / target.product.net_surface_area.in_hectare)).to_i} %)"
    end

    # @param [InterventionTarget] target
    #  @return [Float] between(0,1)
    def target_ratio(target)
      worked_area(target).to_d / total_area.to_d
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
    def input_quantity(input, target)
      if target.working_zone.nil?
        "#{input.input_quantity_per_area.to_d} #{input_unit(input)}"
      elsif input.input_quantity_per_area.repartition_unit.present?
        "#{worked_area(target).to_d * input.input_quantity_per_area.to_d} #{input_unit(input)}"
      else
        "#{(target_ratio(target) * input.input_quantity_per_area.to_d).round(2)} #{input_unit(input)}"
      end
    end

    def compute_dataset
      #  Create Targets
      targets = @intervention.targets.map do |target|
        if target.working_zone
          {
            name: target.product.name,
            type: target.product.nature.name,
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
      inputs = @intervention.targets.map do |target|
        @intervention.inputs.map do |input|
          {
           name: input.product.name,
           rate: input_rate(input),
           quantity: input_quantity(input, target)
          }
        end
      end
      #  Add inputs as a target attribute
      (0..targets.size - 1).each do |j|
        targets[j].merge!({ input: inputs[j] })
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
        tools: tools
      }.to_struct
    end

    def generate(r)
      dataset = compute_dataset
      #  Outside Tables
      r.add_field 'INTERV_NAME', @intervention.name
      r.add_field 'INTERV_STATUS', @intervention.status.tl
      r.add_field 'STARTED_ON', @intervention.started_at.in_time_zone.strftime("%d/%m/%y %R")
      r.add_field 'STOPPED_ON', @intervention.stopped_at.in_time_zone.strftime("%d/%m/%y %R")
      r.add_field 'TOTAL_AREA', total_area.round_l
      # Inside Table-targets
      r.add_table('Table-target', dataset.targets) do |t|
        t.add_field(:target_name) { |target| target[:name] }
        t.add_field(:target_type) { |target| target[:type] }
        t.add_field(:working_area) { |target| target[:pct] }
        #  Inside Table-input
        t.add_table('Table-input', :input) do |i|
          i.add_field(:input_name) { |input| input[:name] }
          i.add_field(:input_rate) { |input| input[:rate] }
          i.add_field(:input_quantity) { |input| input[:quantity] }
        end
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
    end
  end
end
