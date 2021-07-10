# frozen_string_literal: true

module Printers
  class InventorySheetPrinter < PrinterBase
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
      @inventory = Inventory.find_by_id(id)
    end

    #  Generate document name
    def document_name
      "#{template.nature.human_name} : #{@intervention.updated_at}"
    end

    #  Create document key
    def key
      self.class.build_key(id: @id, updated_at: @intervention.updated_at.to_s)
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
