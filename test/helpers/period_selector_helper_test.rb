require 'test_helper'

class PeriodSelectorHelperTest < ActionView::TestCase
  setup do
    controller.params = ActionController::Parameters.new(
      { controller: "backend/interventions",
        action: "new",
        fake_param: ActionController::Parameters.new(fake_nested_params: 'fake_value') }
    )
  end

  test '#button_to_previous_period' do
    period_interval =  Date.new(2022, 9, 19)
    button = button_to_previous_period(:year, period_interval)
    assert_dom_equal(
      %(<a class="btn btn-previous icn icn-only"
        href="/backend/interventions/new?current_campaign=2021&amp;current_period=2021-09-19&amp;fake_param%5Bfake_nested_params%5D=fake_value"></a>),
      button
    )
  end

  test '#button_to_next_period' do
    period_interval =  Date.new(2022, 9, 19)
    button = button_to_next_period(:year, period_interval)
    assert_dom_equal(
      %(<a class="btn btn-next icn icn-only"
        href="/backend/interventions/new?current_campaign=2023&amp;current_period=2023-09-19&amp;fake_param%5Bfake_nested_params%5D=fake_value"></a>),
      button
    )
  end
end
