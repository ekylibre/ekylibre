class ProductNatureDecorator < Draper::Decorator
  delegate_all

  def hour_counter?
    object
      .variable_indicators_list
      .include?(:hour_counter)
  end
end
