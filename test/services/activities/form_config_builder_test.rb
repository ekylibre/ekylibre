require 'test_helper'

module Activities
  class FromConfigBuilderTest < Ekylibre::Testing::ApplicationTestCase
    test 'New config is registered and override default config' do
      family = 'test_family'
      form_config_builder = Activities::FormConfigBuilder.build
      form_config_builder.register_config(family, {
        inspections: false,
        production_nature: {
          display_style: 'none'
        }
      })

      form_config = form_config_builder.config_for(family)

      assert_equal false, form_config.inspections
      assert_equal 'none', form_config.production_nature.display_style
      assert_equal 'block', form_config.start_state_of_production.display_style
    end
  end
end
