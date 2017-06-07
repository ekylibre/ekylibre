require 'test_helper'

module Backend
  class InterventionsControllerTest < ActionController::TestCase
    test_restfully_all_actions compute: { mode: :create, params: { format: :json } }, set: :show, except: :run

    test 'parturition heifer create taurus' do
      post :create, {
        intervention: {
          procedure_name: :parturition,
          nature: :record,
          state: :done,
          actions: [:parturition],
          working_periods_attributes:
          {
            '0'=>{
              _destroy: false,
              started_at: "2017-06-06 15:26",
              stopped_at: "2017-06-06 16:26",
            }
          },
          group_parameters_attributes:
          {
            '0'=> {
              _destroy: false,
              reference_name: :parturition,
              targets_attributes: {
                '0'=>{
                  _destroy: false,
                  reference_name: 'mother',
                  product_id: 299,
                }
              },
              outputs_attributes: {
                '0'=> {
                  _destroy: false,
                  reference_name: :child,
                  variant_id: 168,
                  new_name: 'hello',
                  identification_number: 1256,
                }
              }
            }
          }
        }
       }

      #  body = JSON.parse(response.body)
       binding.pry
      # { "intervention"=>{"procedure_name"=>"parturition", "nature"=>"record", "state"=>"done",
      #   "issue_id"=>"", "request_intervention_id"=>"", "description"=>"",
      #   "actions"=>["parturition"], "trouble_encountered"=>"0", "trouble_description"=>"",
      #   "prescription_id"=>"", "working_periods_attributes"=>
      #   {"0"=>{"_destroy"=>"false", "started_at"=>"2017-06-06 15:26", "stopped_at"=>"2017-06-06 16:26"}},
      #   "group_parameters_attributes"=>{
      # "0"=>{"_destroy"=>"false", "reference_name"=>"parturition",
      #   "targets_attributes"=>{"0"=>{"_destroy"=>"false", "reference_name"=>"mother", "product_id"=>"299"}},
      #   "outputs_attributes"=>{"0"=>{"_destroy"=>"false", "reference_name"=>"child", "variant_id"=>"168", "quantity_population"=>"", "new_name"=>"Taureau sauvage", "identification_number"=>"12565", "readings_attributes"=>{"0"=>{"indicator_name"=>"sex", "indicator_datatype"=>"choice", "choice_value"=>"male"}, "1"=>{"indicator_name"=>"net_mass", "indicator_datatype"=>"measure", "measure_value_value"=>"30", "measure_value_unit"=>"kilogram"}, "2"=>{"indicator_name"=>"healthy", "indicator_datatype"=>"boolean", "boolean_value"=>"0"}, "3"=>{"indicator_name"=>"mammalia_birth_condition", "indicator_datatype"=>"choice", "choice_value"=>"few_help"}}}}}}}, "dialog"=>"dialog-29"}

    end

  end
end
