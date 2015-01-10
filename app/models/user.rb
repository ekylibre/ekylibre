# -*- coding: utf-8 -*-

# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
# 
# == Table: users
#
#  admin             :boolean          default(TRUE), not null
#  arrived_on        :date             
#  comment           :text             
#  commercial        :boolean          
#  company_id        :integer          not null
#  connected_at      :datetime         
#  created_at        :datetime         not null
#  creator_id        :integer          
#  departed_on       :date             
#  department_id     :integer          
#  email             :string(255)      
#  employed          :boolean          not null
#  employment        :string(255)      
#  establishment_id  :integer          
#  first_name        :string(255)      not null
#  hashed_password   :string(64)       
#  id                :integer          not null, primary key
#  language          :string(3)        default("???"), not null
#  last_name         :string(255)      not null
#  lock_version      :integer          default(0), not null
#  locked            :boolean          not null
#  name              :string(32)       not null
#  office            :string(255)      
#  profession_id     :integer          
#  reduction_percent :decimal(16, 4)   default(5.0), not null
#  rights            :text             
#  role_id           :integer          not null
#  salt              :string(64)       
#  updated_at        :datetime         not null
#  updater_id        :integer          
#


require "digest/sha2"

class User < CompanyRecord
  belongs_to :department
  belongs_to :establishment
  belongs_to :profession
  belongs_to :role
  has_many :clients, :class_name=>"Entity", :foreign_key=>:responsible_id, :dependent=>:nullify
  has_many :events, :foreign_key=>:responsible_id
  has_many :future_events, :class_name=>"Event", :foreign_key=>:responsible_id, :conditions=>["started_at >= CURRENT_TIMESTAMP"]
  has_many :preferences, :dependent=>:destroy
  has_many :sales_invoices, :foreign_key=>:responsible_id, :class_name=>"Sale", :conditions=>{:state=>:invoice}
  has_many :sales, :foreign_key=>:responsible_id
  has_many :operations, :foreign_key=>:responsible_id
  has_many :transports, :foreign_key=>:responsible_id
  has_many :unpaid_sales, :class_name=>"Sale", :foreign_key=>:responsible_id, :order=>"created_on", :conditions=>["state IN ('order', 'invoice') AND paid_amount < amount AND lost = ? ", false]
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :reduction_percent, :allow_nil => true
  validates_length_of :language, :allow_nil => true, :maximum => 3
  validates_length_of :name, :allow_nil => true, :maximum => 32
  validates_length_of :hashed_password, :salt, :allow_nil => true, :maximum => 64
  validates_length_of :email, :employment, :first_name, :last_name, :office, :allow_nil => true, :maximum => 255
  validates_inclusion_of :admin, :employed, :locked, :in => [true, false]
  validates_presence_of :company, :first_name, :language, :last_name, :name, :reduction_percent, :role
  #]VALIDATORS]
  validates_presence_of :password, :password_confirmation, :if=>Proc.new{|u| u.new_record?}
  validates_confirmation_of :password
  validates_inclusion_of :reduction_percent, :in=>0..100
  validates_uniqueness_of :name, :scope=>:company_id

  # cattr_accessor :current_user
  attr_accessor :password_confirmation, :old_password
  attr_protected :hashed_password, :salt, :locked, :rights

  # Needed to stamp all records
  model_stamper

  class << self
    def rights_file; Rails.root.join("config", "rights.yml"); end
    def minimum_right; :__minimum__; end
    def rights; @@rights; end
    def rights_list; @@rights_list; end
    def useful_rights; @@useful_rights; end
  end
  
  before_validation do
    self.name = self.name.to_s.strip.downcase.gsub(/[^a-z0-9\.\_]/,'')
    if self.company
      self.language = self.company.language if self.language.blank?
    end
    self.reduction_percent ||= 0
    self.admin = true if self.rights.nil?
    self.rights_array = self.rights_array # Clean the rights
    return true
  end

  protect_on_destroy do
    self.events.size <= 0 and self.sales.size <= 0 and self.operations.size <= 0 and self.transports.size <= 0
  end

  def label
    self["first_name"]+' '+self["last_name"]
  end
  alias :full_name :label
  

  def preference(name, value=nil, nature=:string)
    p = self.preferences.find(:first, :order=>:id, :conditions=>{:name=>name})
    if p.nil?
      p = self.preferences.new(:name=>name, :company_id=>self.company_id, :nature=>nature.to_s)
      p.value = value
      p.save!
    end
    return p
  end


  def rights_array
    self.rights.to_s.split(/\s+/).collect{|x| x.to_sym}
  end

  def rights_array=(array)
    narray = array.select{|x| User.rights_list.include? x.to_sym}.collect{|x| x.to_sym}
    self.rights = narray.join(" ")
    return narray
  end

  def diff_more(right_markup = 'div', separator='')
    return '<div>&infin;</div>'.html_safe if self.admin?
    (self.rights_array-self.role.rights_array).select{|x| User.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
  end


  def diff_less(right_markup = 'div', separator='')
    return '' if self.admin?
    (self.role.rights_array-self.rights_array).select{|x| User.rights_list.include?(x)}.collect{|x| "<#{right_markup}>"+::I18n.t("rights.#{x}")+"</#{right_markup}>"}.join(separator).html_safe
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
      users = self.find_all_by_name(name)
      user = users[0] if users.size == 1
    else
      user = self.find_by_name_and_company_id(name.to_s.downcase, company.id)
    end
    if user
      user = nil if user.locked or !user.authenticated?(password.to_s)
    end
    user
  end

  def authorization(controller_name, action_name, rights_list=nil)
    rights_list = self.rights_array if rights_list.blank?
    message = nil
    if User.rights[controller_name.to_sym].nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller=>controller_name, :action=>action_name)
    elsif (rights = User.rights[controller_name.to_sym][action_name.to_sym]).nil?
      message = tc(:no_right_defined_for_this_part_of_the_application, :controller=>controller_name, :action=>action_name)
    elsif (rights & [:__minimum__, :__public__]).empty? and (rights_list & rights).empty? and not self.admin?
      message = tc(:no_right_defined_for_this_part_of_the_application_and_this_user)
    end
    return message
  end

  def can?(right)
    self.admin? or self.rights.match(/(^|\s)#{right}(\s|$)/)
  end
  
  protect_on_destroy do
    self.company.users.count > 1
  end

  def authenticated?(password)
    self.hashed_password == User.encrypted_password(password, self.salt)
  end

  # Used for generic password creation
  def self.give_password(length=8, mode=:complex)
    User.generate_password(length, mode)
  end

  private

  def self.encrypted_password(password, salt)
    string_to_hash = "<"+password.to_s+":"+salt.to_s+"/>"
    Digest::SHA256.hexdigest(string_to_hash)
  end

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
    definition = YAML.load_file(User.rights_file)
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
  
  User.initialize_rights
end

