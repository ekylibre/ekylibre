require "digest/sha2"

class User < ActiveRecord::Base
  cattr_accessor :current_user
  attr_accessor :password_confirmation
  validates_confirmation_of :password
  
  def before_validation
    self.name = self.name.strip.downcase.gsub(/[^a-z0-9\.\_]/,'')
  end

  def password
    @password
  end
  
  def password=(passwd)
    @password = passwd
    unless self.password.blank?
      self.salt = User.generate_password(64)
      self.hashed_password = User.encrypted_password(self.password, self.salt)
    end
  end

  def self.authenticate(name, password)
    user = self.find_by_name(name.downcase)
    if user
      user = nil if user.is_locked or user.is_deleted or !user.is_authenticated?(password)
    end
    user
  end
  
  def after_destroy
    if User.count.zero?
      raise "Impossible to destroy the last user"
    end
  end

  private

  def is_authenticated?(password)
    self.hashed_password == self.encrypted_password(password, self.salt)
  end

  def self.encrypted_password(password, salt)
    string_to_hash = "<"+password+":"+salt+"/>"
    Digest::SHA256.hexdigest(string_to_hash)
  end

  def self.generate_password(password_length=8, mode=:complex)
    return '' if password_length.blank? or password_length<1
    case mode
      when :simple : letters = %w(a b c d e f g h j k m n o p q r s t u w x y A B C D E F G H J K M N P Q R T U W Y X 3 4 6 7 8 9)
      when :normal : letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9)
      else           letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9 _ = + - * | [ ] { } . : ; ! ? , § µ % / & < >)
    end
    letters_length = letters.length
    password = ''
    password_length.times{password+=letters[(letters_length*rand).to_i]}
    password
  end

end
