class RemoveProcedureFromInterventionTemplateProductParameters < ActiveRecord::Migration[5.1]
  def up
    InterventionTemplate.all.each do |intervention|
      procedure = intervention.procedure
      intervention.product_parameters.each do |parameter|
        type = procedure.find(parameter.procedure['type']).type.to_s.capitalize
        parameter.update(type: 'InterventionTemplate::' + type)
      end
    end
  end
end
