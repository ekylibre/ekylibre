class DataView::VeterinaryBooklet < DataView

  define_view do |builder, campaign|
    entity = Entity.of_company
    entity_breeding_number = Preference.find_by_name('services.synel17.login')
    procedures = Procedure.where("nomen = 'animal_treatment'")
    #raise groups.inspect
    builder.list(:interventions, procedures, 
                 :campaign => campaign.name,
                 :entity_name => entity.full_name,
                 :entity_address => entity.default_mail_address.coordinate,
                 :entity_breeding_number => entity_breeding_number.value
                 ) do |procedure|
      builder.item(:id => procedure.id, :name => procedure.name) do
        target = procedure.variables.of_role(:target).first.target
        worker = procedure.variables.of_role(:worker).first.target
        builder.list(:inputs, procedure.variables.of_role(:input)) do |input_variable|
          # determine min sale date
          started_at = procedure.started_at
          stopped_at = procedure.stopped_at
          meat_withdrawal_period = input_variable.target.meat_withdrawal_period.to_f
          milk_withdrawal_period = input_variable.target.milk_withdrawal_period.to_f
          milk_min_sale_date = stopped_at + milk_withdrawal_period
          meat_min_sale_date = stopped_at + meat_withdrawal_period
          procedure_duration_day = (stopped_at - started_at)/(60*60*24)
            
          builder.item(:id => input_variable.id,
                       :target_identification => target.identification_number,
                       :target_id => target.id,
                       :target_name => target.name,
                       :target_class_name => target.class.name,
                       :worker_name => worker.name,
                       :worker_id => worker.id,
                       :worker_entity_id => worker.owner.id,
                       :name => input_variable.target.name,
                       :nature => input_variable.target.nature.name,
                       :variety => input_variable.target.variety,
                       :quantity => input_variable.measure_quantity,
                       :quantity_unit => input_variable.measure_unit,
                       :meat_withdrawal_period => meat_withdrawal_period,
                       :milk_withdrawal_period => milk_withdrawal_period,
                       :milk_min_sale_date => milk_min_sale_date,
                       :meat_min_sale_date => meat_min_sale_date,
                       :started_at => started_at,
                       :stopped_at => stopped_at,
                       :procedure_duration_day => procedure_duration_day
                       ) do
            if incident = procedure.incident
              builder.sdsds(:id => incident.id,
                            :name => incident.name,
                            :observed_at => incident.observed_at,
                            :state => incident.state,
                            :description => incident.description
                            )
            end
            if prescription = procedure.prescription
              builder.prescription(:id => prescription.id,
                                   :reference_number => prescription.reference_number,
                                   :prescriptor => prescription.prescriptor.name
                                   )
            end
          end
        end
      end
    end
  end

  

  define_view do |builder, campaign|
    entity = Entity.of_company
    entity_breeding_number = Preference.find_by_name('services.synel17.login')
    procedures = Procedure.where("nomen = 'animal_treatment'")
    #raise groups.inspect
    builder.interventions(:campaign => campaign.name,
                          :entity_name => entity.full_name,
                          :entity_adress => entity.default_mail_address.coordinate,
                          :entity_breeding_number => entity_breeding_number.value
                          ) do
      for procedure in procedures
        builder.intervention(:id => procedure.id, :name => procedure.name) do
          target = procedure.variables.of_role(:target).first.target
          worker = procedure.variables.of_role(:worker).first.target
          for input_variable in procedure.variables.of_role(:input)
            # determine min sale date
            started_at = procedure.started_at
            stopped_at = procedure.stopped_at
            meat_withdrawal_period = input_variable.target.meat_withdrawal_period.to_f
            milk_withdrawal_period = input_variable.target.milk_withdrawal_period.to_f
            milk_min_sale_date = stopped_at + milk_withdrawal_period
            meat_min_sale_date = stopped_at + meat_withdrawal_period
            procedure_duration_day = (stopped_at - started_at)/(60*60*24)
            
            builder.input(:id => input_variable.id,
                          :target_identification => target.identification_number,
                          :target_id => target.id,
                          :target_name => target.name,
                          :target_class_name => target.class.name,
                          :worker_name => worker.name,
                          :worker_id => worker.id,
                          :worker_entity_id => worker.owner.id,
                          :name => input_variable.target.name,
                          :nature => input_variable.target.nature.name,
                          :variety => input_variable.target.variety,
                          :quantity => input_variable.measure_quantity,
                          :quantity_unit => input_variable.measure_unit,
                          :meat_withdrawal_period => meat_withdrawal_period,
                          :milk_withdrawal_period => milk_withdrawal_period,
                          :milk_min_sale_date => milk_min_sale_date,
                          :meat_min_sale_date => meat_min_sale_date,
                          :started_at => started_at,
                          :stopped_at => stopped_at,
                          :procedure_duration_day => procedure_duration_day
                          ) do
              
              if incident = procedure.incident
                builder.incident(:id => incident.id,
                                 :name => incident.name,
                                 :observed_at => incident.observed_at,
                                 :state => incident.state,
                                 :description => incident.description
                                 )
              end
              if prescription = procedure.prescription
                builder.prescription(:id => prescription.id,
                                     :reference_number => prescription.reference_number,
                                     :prescriptor => prescription.prescriptor.name
                                     )
              end
            end
          end
        end
      end
    end
  end


end
