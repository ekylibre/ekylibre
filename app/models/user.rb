# == Schema Information
#
# Table name: users
#
#  id                :integer       not null, primary key
#  name              :string(32)    not null
#  first_name        :string(255)   not null
#  last_name         :string(255)   not null
#  salt              :string(64)    
#  hashed_password   :string(64)    
#  locked            :boolean       not null
#  deleted           :boolean       not null
#  email             :string(255)   
#  company_id        :integer       not null
#  language_id       :integer       not null
#  role_id           :integer       not null
#  created_at        :datetime      not null
#  updated_at        :datetime      not null
#  lock_version      :integer       default(0), not null
#  free_price        :boolean       default(TRUE), not null
#  reduction_percent :decimal(, )   default(5.0), not null
#  credits           :boolean       default(TRUE), not null
#  admin             :boolean       default(TRUE), not null
#  rights            :text          
#  creator_id        :integer       
#  updater_id        :integer       
#

require "digest/sha2"

class User < ActiveRecord::Base
  belongs_to :company
  belongs_to :language
  belongs_to :role
  has_many :parameters
  has_one :employee

  validates_presence_of :password, :password_confirmation, :if=>Proc.new{|u| u.new_record?}
  validates_confirmation_of :password
  # validates_uniqueness_of :name, :scope=>:company_id

  # cattr_accessor :current_user
  attr_accessor :password_confirmation
  attr_protected :hashed_password, :salt, :locked, :deleted, :role_id
  attr_readonly :company_id

  # Needed to stamp all records
  model_stamper if defined? Userstamp

  class << self
    def rights; @@rights; end
    def rights_list; @@rights_list; end
    def useful_rights; @@useful_rights; end
  end
  
  def before_validation
    self.name = self.name.to_s.strip.downcase.gsub(/[^a-z0-9\.\_]/,'')
    if self.company
      self.language = self.company.parameter('general.language').value if self.language.nil?
    end
    self.language = Language.find(:first, :order=>:name) if self.language.nil?
    self.rights = "administrate" if self.rights.nil?
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

  def self.authenticate(name, password, company=nil)
    user = nil
    if company.nil?
      users = self.find_all_by_name(name.downcase)
      user = users[0] if users.size == 1
    else
      user = self.find_by_name_and_company_id(name.downcase, company.id)
    end
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


  def self.initialize_rights
    @@rights = {}
    @@rights_list = []
    @@useful_rights = {}
    file = File.open("#{RAILS_ROOT}/config/rights.txt", "r") 
    file.each_line do |line|
      line = line.strip.split(":")
      unless line[0].match(/\#/) or line[2].match(/\</)
        @@rights[line[0].to_sym] ||= {}
        @@rights[line[0].to_sym][line[1].to_sym] = line[2].to_sym 
        @@rights_list << line[2].to_sym 
      end
    end
    @@rights_list.uniq!
    for controller, actions in @@rights
      unless [:search, :guide, :authentication, :help].include? controller
        @@useful_rights[controller] = actions.values.uniq
      end
    end
  end

  User.initialize_rights
end
