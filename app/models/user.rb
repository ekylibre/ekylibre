# == Schema Information
# Schema version: 20090520140946
#
# Table name: users
#
#  id              :integer       not null, primary key
#  name            :string(32)    not null
#  first_name      :string(255)   not null
#  last_name       :string(255)   not null
#  salt            :string(64)    
#  hashed_password :string(64)    
#  locked          :boolean       not null
#  deleted         :boolean       not null
#  email           :string(255)   
#  company_id      :integer       not null
#  language_id     :integer       not null
#  role_id         :integer       not null
#  created_at      :datetime      not null
#  updated_at      :datetime      not null
#  created_by      :integer       
#  updated_by      :integer       
#  lock_version    :integer       default(0), not null
#

require "digest/sha2"

class User < ActiveRecord::Base
  belongs_to :company
  belongs_to :language
  belongs_to :role
  has_many :parameters
  has_one :employee

  validates_presence_of :password, :password_confirmation, :if=>Proc.new{|u| u.new_record?}
  validates_presence_of  :reduction_percent
  validates_confirmation_of :password

  cattr_accessor :current_user
  attr_accessor :password_confirmation
  attr_protected :hashed_password, :salt, :locked, :deleted, :role_id
  attr_readonly :company_id
  
  def before_validation
    self.name = self.name.to_s.strip.downcase.gsub(/[^a-z0-9\.\_]/,'')
    if self.company
      self.language = self.company.parameter('general.language').value if self.language.nil?
    end
    self.language = Language.find(:first, :order=>:name) if self.language.nil?
  end

  def validate
    errors.add_to_base tc(:reduction_percent_between_0_and_100) if self.reduction_percent < 0 || self.reduction_percent > 100
  end   

  def label
    self.first_name+' '+self.last_name
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
      user = nil if user.locked or user.deleted or !user.authenticated?(password)
    end
    user
  end
  
  def after_destroy
    if User.count.zero?
      raise "Impossible to destroy the last user"
    end
  end

  def authenticated?(password)
    self.hashed_password == User.encrypted_password(password, self.salt)
  end

  def admin?
    self.role.can_do? :all
  end

  def can_do?(action)
    self.role.can_do?(action)
  end

  private

  def self.encrypted_password(password, salt)
    string_to_hash = "<"+password+":"+salt+"/>"
    Digest::SHA256.hexdigest(string_to_hash)
  end

  def self.generate_password(password_length=8, mode=:complex)
    return '' if password_length.blank? or password_length<1
    case mode
      when :dummy  : letters = %w(a b c d e f g h j k m n o p q r s t u w x y 3 4 6 7 8 9)
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
