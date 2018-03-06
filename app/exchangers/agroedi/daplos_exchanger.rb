module Agroedi
  # Exchanger to import COFTW.isa files from IsaCompta software
  class DaplosExchanger < ActiveExchanger::Base
    def check
      SVF::EdiDaplos2.parse(file)
    rescue SVF::InvalidSyntax
      return false
    end

    def import
      # path = "/home/djoulin/projects/eky/tmp/test.dap"
      # f = File.open(path)
      
      
      # Load hash to transcode EDI code to procedure
      here = Pathname.new(__FILE__).dirname
      procedures_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('procedures.csv'), headers: true) do |row|
        procedures_transcode[row[0]] = row[1].to_sym
      end

      begin
        daplos = SVF::EdiDaplos2.parse(file)
      rescue SVF::InvalidSyntax
        raise ActiveExchanger::NotWellFormedFileError
      end

      # TODO: check siret

      # crop
      daplos.interchange.crops.each do |crop|
        
        # get specie and area
        production_nature = MasterProductionNature.where(agroedi_crop_code: crop.crop_edicode).first
        puts "production_nature : #{production_nature}".inspect.yellow
        
        crop_area = crop.crop_areas.first.area_nature_value.to_f
        max_area = crop_area + (crop_area * 0.05)
        min_area = crop_area - (crop_area * 0.05)
        
        # find existing activity production with specie and area +/- 5% and then a support
        # TODO add campaign
        activity_production = ActivityProduction.of_cultivation_variety(production_nature.specie).where('size_value <= ?', max_area).where('size_value >= ?', min_area).first
        target = activity_production.support if activity_production
        puts "target : #{target.name}".inspect.yellow
        
        # parse interventions from daplos file and create each one
        crop.interventions.each do |i|
        
          # get intervention nature
          intervention_agroedi_code = RegisteredAgroediCode.where(repository_id: 14, reference_code: i.intervention_nature_edicode).first
          puts "intervention_agroedi_code : #{intervention_agroedi_code}".inspect.red
          
          procedure = Procedo.find(procedures_transcode[intervention_agroedi_code.reference_code]) if intervention_agroedi_code
          puts "procedure : #{procedure.name}".inspect.yellow
          
          # record intervention
          record_default_intervention(i, target, procedure)
            
        end
        
      end
    end
    
    protected
    
    # find or create product and variant
    def find_or_create_product(input, at)
      
      # Load hash to transcode EDI input to nature
      here = Pathname.new(__FILE__).dirname
      inputs_transcode = {}.with_indifferent_access
      CSV.foreach(here.join('inputs.csv'), headers: true) do |row|
        inputs_transcode[row[0]] = row[1].to_sym
      end
      
      units_transcode = {"KGM" => :kilogram, "LTR" => :liter, "TNE" => :ton, "NAR" => :unit}
      
      nature = ProductNature.import_from_nomenclature(inputs_transcode[input.input_nature_edicode])
      
      variant = nature.variants.where(name: input.input_name, unit_name: units_transcode[input.input_unity_edicode], active: true).first
      
      unless variant
        
        variant = nature.variants.create!(name: input.input_name, unit_name: units_transcode[input.input_unity_edicode], active: true)
        
        default_indicators = {
                net_mass: Measure.new(1.00, :kilogram),
                net_volume: Measure.new(1.00, :liter)
              }.with_indifferent_access
        
        default_indicators.each do |indicator_name, value|
          variant.read! indicator_name, value
        end
        
      end
 
      if !input.input_phytosanitary_number.blank?
        variant.france_maaid = input.input_phytosanitary_number
        variant.save!
      end
      
      if variant.products.any?
        return variant.products.first
      else
        # Check building division presence
        building_division = BuildingDivision.first 
        
        pmodel = variant.nature.matching_model
        # create the product
          matter = pmodel.create!(
            variant: variant,
            initial_born_at: at,
            initial_population: 0.0,
            initial_owner: Entity.of_company,
            initial_container: building_division,
            default_storage: building_division
          )
          return matter
        
      end
    end
    
    
    def record_default_intervention(i, target, procedure)
      # build base procedure
      attributes = {
        procedure_name: procedure.name,
        actions: procedure.mandatory_actions.map(&:name),
        description: "#{i.intervention_name} | #{i.intervention_id}"
      }

      ## working_periods
      attributes[:working_periods_attributes] = {
        '0' => {
          started_at: Date.parse(i.intervention_started_on).strftime('%Y-%m-%d %H:%M'),
          stopped_at: (Date.parse(i.intervention_stopped_on) + 1.hour).strftime('%Y-%m-%d %H:%M')
        }
      }

      ## targets
      procedure.parameters_of_type(:target).each do |support|
        # next unless target.of_expression(support.filter)
        attributes[:targets_attributes] ||= {}
        attributes[:targets_attributes][0] = {
          reference_name: support.name,
          product_id: target.id,
          working_zone: target.shape.to_geojson
        }
      end

      ## inputs
      updaters = []

      i.inputs.each_with_index do |actor, index|
        
        p = find_or_create_product(actor, Date.parse(i.intervention_started_on).to_time)
        
        puts "product : #{p.name}".inspect.yellow
        
        unit = Nomen::Unit.find(p.variant.unit_name.to_sym)
        dimension = unit.dimension
        quantity_handler = "net_" + dimension.to_s
        
        procedure.parameters_of_type(:input).each do |input|
           # find measure from quantity
           # product_measure = actor_measure_conversion(p.variant)
           # find best handler for product measure
           # inp = input.best_handler_for(product_measure)
           # handler = if inp.is_a?(Array)
           #             input.best_handler_for(product_measure).first.name
           #           else
           #             input.best_handler_for(product_measure).name
           #           end
         
          puts "input : #{input}".inspect.red
          puts "input filter : #{input.filter}".inspect.green
          next unless p.of_expression(input.filter)
          
          attributes[:inputs_attributes] ||= {}
          attributes[:inputs_attributes][index.to_s] = {
            reference_name: input.name,
            product_id: p.id,
            quantity_handler: quantity_handler.to_sym,
            quantity_value: Measure.new(actor.input_quantity.to_f, unit.name.to_sym)
          }
          puts "inputs attributes #{attributes}".inspect.yellow
           
          updaters << "inputs[#{index}]quantity_value"
          break
        end
      end

      ## tools
      attributes[:tools_attributes] ||= {}
 
      ## doers
      attributes[:doers_attributes] ||= {}

      ## impact
      intervention = Procedo::Engine.new_intervention(attributes)
      updaters.each do |updater|
        intervention.impact_with!(updater)
      end

      ## save
      ::Intervention.create!(intervention.to_attributes)
    end
    
  end
end
