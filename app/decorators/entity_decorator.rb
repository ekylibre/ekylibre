class EntityDecorator < Draper::Decorator
  delegate_all

  def block_address
    object.mails.any? ? object.mails.order(:by_default).first.mail_coordinate : object.full_name
  end

  alias_method :address, :block_address

  def inline_address
    block_address.gsub("\r\n", ', ')
  end

  def email
    object.emails.any? ? object.emails.order(:by_default).first.coordinate : ''
  end

  def phone
    object.phones.any? ? object.phones.order(:by_default).first.coordinate : ''
  end

  def website
    object.websites.any? ? object.websites.order(:by_default).first.coordinate : ''
  end

  def has_picture?
    picture.path && File.exist?(picture.path)
  end
end
