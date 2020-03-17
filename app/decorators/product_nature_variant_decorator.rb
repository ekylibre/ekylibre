class ProductNatureVariantDecorator < Draper::Decorator
  delegate_all

  def get_controller_path
    "backend/#{type.tableize}"
  end
end
