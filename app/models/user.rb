# -*- coding: utf-8 -*-
class User < Ekylibre::Record::Base
  attr_accessible :email, :password, :password_confirmation, :remember_me
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :registerable
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  model_stamper # Needed to stamp all records

  class << self
    def rights_file; Rails.root.join("config", "rights.yml"); end
    def minimum_right; :__minimum__; end
    def rights; @@rights; end
    def rights_list; @@rights_list; end
    def useful_rights; @@useful_rights; end
  end

  before_validation do
    self.rights_array = self.rights_array # Clean the rights
  end

  def rights_array
    self.rights.to_s.split(/\s+/).collect{|x| x.to_sym}
  end

  def rights_array=(array)
    narray = array.select{|x| self.class.rights_list.include? x.to_sym}.collect{|x| x.to_sym}
    self.rights = narray.join(" ")
    return narray
  end

  def diff_more(right_markup = 'div', separator='')
    return '<div>&infin;</div>'.html_safe if self.admin?
    (self.rights_array-self.role.rights_array).select{|x| self.class.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
  end


  def diff_less(right_markup = 'div', separator='')
    return '' if self.admin?
    (self.role.rights_array-self.rights_array).select{|x| self.class.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
  end


  def preference(name, value = nil, nature = :string)
    p = self.preferences.find(:first, :order => :id, :conditions => {:name => name})
    if p.nil?
      p = self.preferences.build
      p.name   = name
      p.nature = nature.to_s
      p.value  = value
      p.save!
    end
    return p
  end



  # # Find and check user account
  # def self.authenticate(user_name, password)
  #   if user = self.find_by_user_name_and_loggable(user_name.to_s.downcase, true)
  #     if user.locked or !user.authenticated?(password.to_s)
  #       user = nil
  #     end
  #   end
  #   return user
  # end

  def authorization(controller_name, action_name, rights_list=nil)
    rights_list = self.rights_array if rights_list.blank?
    message = nil
    if self.class.rights[controller_name.to_sym].nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller => controller_name, :action => action_name)
    elsif (rights = self.class.rights[controller_name.to_sym][action_name.to_sym]).nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller => controller_name, :action => action_name)
    elsif (rights & [:__minimum__, :__public__]).empty? and (rights_list & rights).empty? and not self.admin?
      message = tc(:no_right_defined_for_this_part_of_the_application_and_this_user)
    end
    return message
  end

  def can?(right)
    self.admin? or self.rights.match(/(^|\s)#{right}(\s|$)/)
  end

  protect(:on => :destroy) do
    self.class.count > 1
  end

  # def authenticated?(password)
  #   self.hashed_password == self.class.encrypted_password(password, self.salt)
  # end

  # Used for generic password creation
  def self.give_password(length=8, mode=:complex)
    self.generate_password(length, mode)
  end

  private

  # def self.encrypted_password(password, salt)
  #   string_to_hash = "<"+password.to_s+":"+salt.to_s+"/>"
  #   Digest::SHA256.hexdigest(string_to_hash)
  # end

  def self.generate_password(password_length=8, mode=:normal)
    return '' if password_length.blank? or password_length<1
    case mode
    when :dummy then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y 3 4 6 7 8 9)
    when :simple then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y A B C D E F G H J K M N P Q R T U W Y X 3 4 6 7 8 9)
    when :normal then
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9)
    else
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9 _ = + - * | [ ] { } . : ; ! ? , § µ % / & < >)
    end
    letters_length = letters.length
    password = ''
    password_length.times{password+=letters[(letters_length*rand).to_i]}
    password
  end


  def self.initialize_rights
    definition = YAML.load_file(self.rights_file)
    # Expand actions
    for right, attributes in definition
      if attributes
        attributes['actions'].each_index do |index|
          unless attributes['actions'][index].match(/\:\:/)
            attributes['actions'][index] = attributes['controller'].to_s+"::"+attributes['actions'][index]
          end
        end if attributes['actions'].is_a? Array
      end
    end
    definition.delete_if{|k, v| k == "__not_used__" }
    @@rights_list = definition.keys.sort.collect{|x| x.to_sym}.delete_if{|k, v| k.to_s.match(/^__.*__$/)}
    @@rights = {}
    @@useful_rights = {}
    for right, attributes in definition
      if attributes.is_a? Hash
        unless attributes["controller"].blank?
          controller = attributes["controller"].to_sym
          @@useful_rights[controller] ||= []
          @@useful_rights[controller] << right.to_sym
        end
        for uniq_action in attributes["actions"]
          controller, action = uniq_action.split(/\W+/)[0..1].collect{|x| x.to_sym}
          @@rights[controller] ||= {}
          @@rights[controller][action] ||= []
          @@rights[controller][action] << right.to_sym
        end if attributes["actions"].is_a? Array
      end
    end
  end
  
  initialize_rights

end
