# coding: utf-8

require 'test_helper'

class AddACustomFieldTest < CapybaraIntegrationTest
  # setup do
  #   # Need to go on page to set tenant
  #   login_with_user
  #   visit('/backend/custom_fields/new')
  # end

  # teardown do
  #   CustomField.destroy_all
  #   Warden.test_reset!
  # end

  # # tests 15% of models randomly. For local tests, set manually this value
  # coverage_percent = 0.15
  # models = CustomField.customized_type.values.select do |model|
  #   # Do not test when controller does not exist
  #   model != CustomField.name and Rails.root.join("app", "controllers", "backend", "#{model.tableize}_controller.rb").exist?
  # end
  # custom_field_natures = CustomField.nature.values.map(&:to_sym)
  # models.sample((models.count * coverage_percent).round + custom_field_natures.count).each_with_index do |model, index|
  #   model_name = model.underscore
  #   model_human_name = Ekylibre::Record.human_name(model_name)

  #   # tests one random custom field nature. For local tests, set manually left and right range values
  #   left = index.modulo(custom_field_natures.count)
  #   right = left
  #   custom_field_natures[left..right].each do |nature|
  #     nature_human_name = CustomField.nature.human_value_name(nature)
  #     test "manage #{nature} custom field on #{model_name}" do
  #       id = send(model.tableize, "#{model.tableize}_001").id
  #       # creating custom field
  #       select model_human_name,  from: "custom_field[customized_type]"
  #       select nature_human_name, from: "custom_field[nature]"
  #       custom_field_name = "#{nature.to_s.capitalize} インフォ #{rand(36**20).to_s(36)}"
  #       fill_in "custom_field[name]", with: custom_field_name
  #       check   "custom_field[active]"
  #       if nature == :text
  #         fill_in "custom_field[minimal_length]", with: 5
  #         fill_in "custom_field[maximal_length]", with: 200
  #       elsif nature == :decimal
  #         fill_in "custom_field[minimal_value]", with: 1
  #         fill_in "custom_field[maximal_value]", with: 1000
  #       elsif nature == :choice
  #         within "div#choice_options" do
  #           2.times do
  #             click_on :add_choice.tl
  #           end
  #           all('input').each_with_index do |input, index|
  #             fill_in current_input[:name], with: "Bar #{index}"
  #           end
  #         end
  #       end
  #       click_on :create.tl
  #       # wait_for_ajax

  #       # TODO: get real column name after create
  #       field = CustomField.find_by(name: custom_field_name)
  #       assert field, "Cannot find created custom field '#{custom_field_name}'"
  #       assert_equal custom_field_name, field.name
  #       column_name = field.column_name

  #       # using custom field in model
  #       visit "/backend/#{model.tableize}/#{id}/edit"
  #       if nature == :text
  #         fill_in "#{model_name}[#{column_name}]", with: 'foobarbaz'
  #       elsif nature == :decimal
  #         fill_in "#{model_name}[#{column_name}]", with: 3.14
  #       elsif nature == :boolean
  #         check   "#{model_name}[#{column_name}]"
  #       elsif nature == :date
  #         fill_in "#{model_name}[#{column_name}]", with: '2013-06-01'
  #       elsif nature == :datetime
  #         fill_in "#{model_name}[#{column_name}]", with: '2013-06-01 14:50'
  #       elsif nature == :choice
  #         select 'Bar 0', from: "#{model_name}[#{column_name}]"
  #       else
  #         raise "Unknown custom field datatype"
  #       end
  #       first("#title").click # useful to prevent datetime selector from overlaping "update" button
  #       click_on :update.tl
  #       wait_for_ajax

  #       # views_with_no_redirection = ['Listing']
  #       # unless views_with_no_redirection.include? model
  #       #   refute_equal("/backend/#{model.tableize}/#{id}/edit", current_path)
  #       # end

  #       # checking if modification was done
  #       visit "/backend/#{model.tableize}/#{id}/edit"
  #       if nature == :text
  #         assert_equal('foobarbaz', find_field("#{model_name}[#{column_name}]").value)
  #       elsif nature == :date
  #         assert_equal("2013-06-01", find_field("#{model_name}[#{column_name}]").value)
  #       elsif nature == :datetime
  #         assert_equal("2013-06-01 14:50", find_field("#{model_name}[#{column_name}]").value)
  #       elsif nature == :decimal
  #         assert_equal("3.14", find_field("#{model_name}[#{column_name}]").value)
  #       elsif nature == :boolean
  #         has_checked_field? "#{model_name}[#{column_name}]"
  #       elsif nature == :choice
  #         page.has_select?   "#{model_name}[#{column_name}]", selected: 'Bar 0'
  #       else
  #         raise "Unknown custom field datatype"
  #       end

  #       # Ensure custom field is removed
  #       # Needed for tests
  #       # field.destroy

  #       # TODO: check if custom field is visible in #show view
  #     end
  #   end
  # end
end
