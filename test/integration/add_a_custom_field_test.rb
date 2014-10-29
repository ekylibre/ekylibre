# -*- coding: utf-8 -*-
require 'test_helper'

class AddACustomFieldTest < CapybaraIntegrationTest

  setup do
    #~ for field in [:custom_fields_001, :custom_fields_002]
      #~ #break
      #~ record = custom_fields(field)
      #~ assert record.save, record.errors.inspect
    #~ end
    visit('/authentication/sign_in')
    resize_window(1366, 768)
    login_as(users(:users_001), scope: :user)
    visit('/backend/custom_fields/new')
  end

  CustomField.customized_type.values[0..-1].each do |model|

    # Do not test when controller does not exist
    next unless Rails.root.join("app", "controllers", "backend", "#{model.tableize}_controller.rb").exist?

    model_name = model.underscore
    model_human_name = Ekylibre::Record.human_name(model_name)
    id = ActiveRecord::FixtureSet.identify("#{model.tableize}_001")

    [:text, :decimal, :boolean, :date, :datetime, :choice][2..2].each do |nature|
      nature_human_name = CustomField.nature.human_value_name(nature)
      test "manage #{nature} custom field on #{model_name}" do
        # creating custom field
        select model_human_name, from: "custom_field[customized_type]"
        select nature_human_name, from: "custom_field[nature]"
        custom_field_name = "#{nature.to_s.capitalize} インフォ"
        column_name = ("_" + custom_field_name.parameterize.gsub(/[^a-z]+/, '_').gsub(/(^\_+|\_+$)/, ''))[0..62]
        fill_in "custom_field[name]", with: custom_field_name
        check   "custom_field[active]"
        if nature == :text
          fill_in "custom_field[minimal_length]", with: 5
          fill_in "custom_field[maximal_length]", with: 200
        end
        if nature == :decimal
          fill_in "custom_field[minimal_value]", with: 1
          fill_in "custom_field[maximal_value]", with: 1000
        end
        within "div#choice_options" do
          2.times do
            click_on :add_choice.tl
          end
          counter = 0
          all('input').each do |current_input|
            fill_in current_input[:name], with: "Bar #{counter}"
            counter += 1
          end
        end if nature == :choice
        # shoot_screen
        click_on :create.tl

        # TODO: get real column name after create

        # using custom field in model
        visit "/backend/#{model.tableize}/#{id}/edit"
        if nature == :text
          fill_in "#{model_name}[#{column_name}]", with: 'baz'
        elsif nature == :decimal
          fill_in "#{model_name}[#{column_name}]", with: 3.14
        elsif nature == :boolean
          check   "#{model_name}[#{column_name}]"
        elsif nature == :date
          fill_in "#{model_name}[#{column_name}]", with: '2013-06-01'
        elsif nature == :datetime
          fill_in "#{model_name}[#{column_name}]", with: '2013-06-01 14:50'
        elsif nature == :choice
          select 'bar_0', from: "#{model_name}[#{column_name}]"
        else
          raise "Unknown custom field datatype"
        end
        first("#general-informations").click # useful to prevent datetime selector from overlaping "update" button
        # shoot_screen
        click_on :update.tl

        # checking if modification was done
        visit "/backend/#{model.tableize}/#{id}/edit"
        # shoot_screen "model: #{model}, nature: #{nature.to_s}"
        if nature == :text
          assert_equal('baz', find_by_id("#{model_name}_#{column_name}").value)
        elsif nature == :date
          assert_equal("2013-06-01", find_field("#{model_name}[#{column_name}]").value)
        elsif nature == :datetime
          assert_equal("2013-06-01 14:50", find_field("#{model_name}[#{column_name}]").value)
        elsif nature == :decimal
          assert_equal("3.14", find_field("#{model_name}[#{column_name}]").value)
        elsif nature == :boolean
          has_checked_field? "#{model_name}[#{column_name}]"
        elsif nature == :choice
          page.has_select?   "#{model_name}[#{column_name}]", selected: 'Bar 0'
        else
          raise "Unknown custom field datatype"
        end

        # TODO: check if custom field is visible in #show view
      end
    end
  end
end
