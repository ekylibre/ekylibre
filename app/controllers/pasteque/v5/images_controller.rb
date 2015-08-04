class Pasteque::V5::ImagesController < Pasteque::V5::BaseController
  def category
    send_data File.read(Rails.root.join('app', 'assets', 'images', 'icon', 'favicon.png'))
  end

  def payment_method
    send_data File.read(Rails.root.join('app', 'assets', 'images', 'icon', 'favicon.png'))
  end

  def product
    send_data File.read(Rails.root.join('app', 'assets', 'images', 'icon', 'favicon.png'))
  end

  def resource
    send_data File.read(Rails.root.join('app', 'assets', 'images', 'icon', 'favicon.png'))
  end
end
