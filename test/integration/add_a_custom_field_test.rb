# -*- coding: utf-8 -*-
require 'test_helper'

class AddACustomFieldTest < CapybaraIntegrationTest

  setup do
    visit('/authentication/sign_in')
    resize_window(1366, 768)
    login_as(users(:users_001), scope: :user)
    visit('/backend/custom_fields/new')
  end

  CustomField.customized_type.values[0..-1].each do |model|
    model_human_name = Ekylibre::Record.human_name(model.to_s.underscore)
    [:text, :decimal, :boolean, :date, :datetime, :choice][2..2].each do |nature|
      nature_human_name = CustomField.nature.human_value_name(nature)

      test "select #{model.underscore}, create #{nature} custom field, and use it" do
      # creating custom field
        select model_human_name, from: "custom_field[customized_type]"
        select nature_human_name, from: "custom_field[nature]"
        fill_in "custom_field[name]", with: "foo-#{nature.to_s}-#{model.to_s.underscore}"
        check "custom_field[active]"
        fill_in "custom_field[minimal_length]", with: 1
        fill_in "custom_field[maximal_length]", with: 255
        fill_in "custom_field[minimal_value]", with: 1
        fill_in "custom_field[maximal_value]", with: 255
        within "div#choice_options" do
          2.times do
            click_on :add_choice.tl
          end
          counter = 0
          all('input').each do |current_input|
            fill_in current_input[:name], with: "bar_#{counter}"
            counter += 1
          end
        end
        shoot_screen
        click_on :create.tl

      # using custom field in model
        visit "/backend/#{model.to_s.pluralize.underscore}/#{ActiveRecord::FixtureSet.identify("#{model.to_s.pluralize.underscore}_001")}/edit"
        fill_in "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]", with: 'baz' if nature == :text
        fill_in "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]", with: 3.14 if nature == :decimal
        check "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]" if nature == :boolean
        fill_in "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]", with: '2013-06-01' if nature == :date
        fill_in "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]", with: '2013-06-01 14:50' if nature == :datetime
        select 'bar_0', from: "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]" if nature == :choice
        first("#general-informations").click # useful to prevent datetime selector from overlaping "update" button
        shoot_screen
        click_on :update.tl

      # checking if modification was done
        visit "/backend/#{model.to_s.pluralize.underscore}/#{ActiveRecord::FixtureSet.identify("#{model.to_s.pluralize.underscore}_001")}/edit"
        shoot_screen "model: #{model}, nature: #{nature.to_s}"
        assert(find_by_id("#{model.underscore.downcase}__foo_#{nature.to_s}_#{model.to_s.underscore}").value == 'baz') if nature == :text
        assert(find_field("#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]").value == "2013-06-01") if nature == :date
        assert(find_field("#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]").value == "2013-06-01 14:50") if nature == :datetime
        assert(find_field("#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]").value == "3.14") if nature == :decimal
        has_checked_field? "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]" if nature == :boolean
        page.has_select? "#{model.underscore.downcase}[_foo_#{nature.to_s}_#{model.to_s.underscore}]", selected: 'bar_0' if nature == :choice

      # TODO: check if custom field is visible in #show view
      end
    end
  end
end
