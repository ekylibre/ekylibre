# coding: utf-8
# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2015 Brice Texier, David Joulin
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: users
#
#  administrator                          :boolean          default(TRUE), not null
#  authentication_token                   :string
#  commercial                             :boolean          default(FALSE), not null
#  confirmation_sent_at                   :datetime
#  confirmation_token                     :string
#  confirmed_at                           :datetime
#  created_at                             :datetime         not null
#  creator_id                             :integer
#  current_sign_in_at                     :datetime
#  current_sign_in_ip                     :string
#  description                            :text
#  email                                  :string           not null
#  employed                               :boolean          default(FALSE), not null
#  employment                             :string
#  encrypted_password                     :string           default(""), not null
#  failed_attempts                        :integer          default(0)
#  first_name                             :string           not null
#  id                                     :integer          not null, primary key
#  language                               :string           not null
#  last_name                              :string           not null
#  last_sign_in_at                        :datetime
#  last_sign_in_ip                        :string
#  lock_version                           :integer          default(0), not null
#  locked                                 :boolean          default(FALSE), not null
#  locked_at                              :datetime
#  maximal_grantable_reduction_percentage :decimal(19, 4)   default(5.0), not null
#  person_id                              :integer
#  remember_created_at                    :datetime
#  reset_password_sent_at                 :datetime
#  reset_password_token                   :string
#  rights                                 :text
#  role_id                                :integer          not null
#  sign_in_count                          :integer          default(0)
#  team_id                                :integer
#  unconfirmed_email                      :string
#  unlock_token                           :string
#  updated_at                             :datetime         not null
#  updater_id                             :integer
#

class User < Ekylibre::Record::Base
  include Rightable
  refers_to :language
  belongs_to :team
  belongs_to :person, -> { contacts }, class_name: 'Entity'
  belongs_to :role
  has_many :crumbs
  has_many :dashboards, foreign_key: :owner_id
  has_many :preferences, dependent: :destroy, foreign_key: :user_id
  has_many :sales_invoices, -> { where(state: 'invoice') }, through: :person, source: :managed_sales, class_name: 'Sale'
  has_many :sales, through: :person, source: :managed_sales
  has_many :transports, foreign_key: :responsible_id
  has_many :unpaid_sales, -> { order(:created_at).where(state: %w(order invoice)).where(lost: false).where('paid_amount < amount') }, through: :person, source: :managed_sales, class_name: 'Sale'
  has_one :worker, through: :person

  scope :employees, -> { where(employed: true) }
  scope :administrators, -> { where(administrator: true) }

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :confirmation_sent_at, :confirmed_at, :current_sign_in_at, :last_sign_in_at, :locked_at, :remember_created_at, :reset_password_sent_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :failed_attempts, allow_nil: true, only_integer: true
  validates_numericality_of :maximal_grantable_reduction_percentage, allow_nil: true
  validates_inclusion_of :administrator, :commercial, :employed, :locked, in: [true, false]
  validates_presence_of :email, :encrypted_password, :first_name, :language, :last_name, :maximal_grantable_reduction_percentage, :role
  # ]VALIDATORS]
  validates_length_of :language, allow_nil: true, maximum: 3
  # validates_presence_of :password, :password_confirmation, if: Proc.new{|e| e.encrypted_password.blank? and e.loggable?}
  validates_confirmation_of :password
  validates_numericality_of :maximal_grantable_reduction_percentage, greater_than_or_equal_to: 0, less_than_or_equal_to: 100
  validates_uniqueness_of :email, :person_id
  # validates_presence_of :person
  # validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, if: lambda{|r| !r.email.blank?}

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :registerable
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :recoverable, :rememberable, :trackable, :validatable
  model_stamper # Needed to stamp.all records
  delegate :picture, :participations, to: :person
  delegate :name, to: :role, prefix: true

  before_validation do
    self.language = Preference[:language] if language.blank?
    self.maximal_grantable_reduction_percentage ||= 0
    self.role ||= Role.first if self.administrator?
    self.rights ||= self.role.rights if self.role
    self.rights = self.rights.to_hash if self.rights
  end

  validate on: :update do
    if self.class.administrators.count <= 1 && old_record.administrator? && !self.administrator?
      errors.add(:administrator, :accepted)
    end
    if person && old_record.person
      errors.add(:person_id, :readonly) if person_id != old_record.person_id
    end
  end

  before_save do
    if authentication_token.blank?
      self.authentication_token = self.class.generate_authentication_token
    end
  end

  before_save do
    unless person
      self.create_person!(first_name: first_name, last_name: last_name, nature: :contact)
    end
  end

  protect(on: :destroy) do
    (self.administrator? && self.class.administrators.count <= 1) || self.class.count <= 1
  end

  def full_name
    name
  end

  def name
    # TODO: I18nize the method User#name !
    "#{first_name} #{last_name}"
  end

  def label
    name
  end

  # Returns the URL of the avatar of the user
  def avatar_url(options = {})
    size = options[:size] || 200
    hash = Digest::MD5.hexdigest(email)
    "https://secure.gravatar.com/avatar/#{hash}?size=#{size}"
  end

  # Find or create preference for given name
  def preference(name, default_value = nil, nature = :string)
    prefs = preferences.select { |p| p.name == name }
    return prefs.first if prefs.any?
    p = preferences.build(name: name, nature: nature.to_s)
    p.value = default_value
    p.save!
    p
  end
  alias_method :pref, :preference

  def prefer!(name, value, nature = :string)
    unless p = preferences.find_by(name: name)
      p = preferences.build(name: name, nature: nature.to_s)
    end
    p.value = value
    p.save!
    p
  end

  def authorization(controller_name, action_name, rights_list = nil)
    rights_list = rights_array if rights_list.blank?
    message = nil
    if self.class.rights[controller_name.to_sym].nil?
      message = :no_right_defined_for_this_part_of_the_application.tl(controller: controller_name, action: action_name)
    elsif (rights = self.class.rights[controller_name.to_sym][action_name.to_sym]).nil?
      message = :no_right_defined_for_this_part_of_the_application.tl(controller: controller_name, action: action_name)
    elsif (rights & [:__minimum__, :__public__]).empty? && (rights_list & rights).empty? && !self.administrator?
      message = :no_right_defined_for_this_part_of_the_application_and_this_user.tl
    end
    message
  end

  def can?(right)
    self.administrator? || self.rights.match(/(^|\s)#{right}(\s|$)/)
  end

  def can_access?(url)
    return true if self.administrator?
    if url.is_a?(Hash)
      unless url[:controller] && url[:action]
        fail "Invalid URL for accessibility test: #{url.inspect}"
      end
      key = "#{url[:controller].to_s.gsub(/^\//, '')}##{url[:action]}"
    else
      key = url.to_s
    end
    list = Ekylibre::Access.rights_of(key)
    if list.empty?
      logger.debug "Unable to check access for action: #{key}. #{url.inspect}".yellow
      return true
    end
    list &= resource_actions
    list.any?
  end

  # Lock the user
  def lock
    update_column(:locked, true)
  end

  # Unlock the user
  def unlock
    update_column(:locked, false)
  end

  # Returns the days where the user has crumbs present
  def unconverted_crumb_days
    crumbs.unconverted.pluck(:read_at).map(&:to_date).uniq.sort
  end

  # Returns all crumbs, grouped by interventions paths, for the current user.
  # The result is an array of interventions paths.
  # An intervention path is an array of crumbs, for a user, ordered by read_at,
  # between a start crumb and a stop crumb.
  def interventions_paths(options = {})
    crumbs = reload.crumbs.unconverted.where(nature: :start)
    if options[:on]
      crumbs = crumbs.where(read_at: options[:on].beginning_of_day..options[:on].end_of_day)
    end
    crumbs.order(read_at: :asc).map(&:intervention_path)
  end

  def current_campaign
    return nil unless default_campaign = Campaign.order(harvest_year: :desc).first
    preference = self.preference('current_campaign.id', default_campaign.id, :integer)
    unless campaign = Campaign.find_by(id: preference.value)
      campaign = default
      self.prefer!('current_campaign.id', campaign.id)
    end
    campaign
  end

  def current_campaign=(campaign)
    self.prefer!('current_campaign.id', campaign.id, :integer)
  end

  def card
    nil
  end

  def self.generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless exists?(authentication_token: token)
    end
  end

  # Used for generic password creation
  def self.give_password(length = 8, mode = :complex)
    generate_password(length, mode)
  end

  private

  def self.generate_password(password_length = 8, mode = :normal)
    return '' if password_length.blank? || password_length < 1
    case mode
    when :dummy then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y 3 4 6 7 8 9)
    when :simple then
      letters = %w(a b c d e f g h j k m n o p q r s t u w x y A B C D E F G H J K M N P Q R T U W Y X 3 4 6 7 8 9)
    when :normal then
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9)
    else
      letters = %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9 _ = + - * | [ ] { } . : ; ! ? , § % / & < >)
    end
    letters_length = letters.length
    password = ''
    password_length.times { password += letters[(letters_length * rand).to_i] }
    password
  end
end
