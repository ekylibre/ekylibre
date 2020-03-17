# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
#  administrator                          :boolean          default(FALSE), not null
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
#  invitation_accepted_at                 :datetime
#  invitation_created_at                  :datetime
#  invitation_limit                       :integer
#  invitation_sent_at                     :datetime
#  invitation_token                       :string
#  invitations_count                      :integer          default(0)
#  invited_by_id                          :integer
#  language                               :string           not null
#  last_name                              :string           not null
#  last_sign_in_at                        :datetime
#  last_sign_in_ip                        :string
#  lock_version                           :integer          default(0), not null
#  locked                                 :boolean          default(FALSE), not null
#  locked_at                              :datetime
#  maximal_grantable_reduction_percentage :decimal(19, 4)   default(5.0), not null
#  person_id                              :integer
#  provider                               :string
#  remember_created_at                    :datetime
#  reset_password_sent_at                 :datetime
#  reset_password_token                   :string
#  rights                                 :text
#  role_id                                :integer
#  sign_in_count                          :integer          default(0)
#  signup_at                              :datetime
#  team_id                                :integer
#  uid                                    :string
#  unconfirmed_email                      :string
#  unlock_token                           :string
#  updated_at                             :datetime         not null
#  updater_id                             :integer
#

class User < Ekylibre::Record::Base
  # No point accepted in preference name
  PREFERENCE_SHOW_MAP_INTERVENTION_FORM = 'show_map_on_intervention_form'.freeze
  PREFERENCE_SHOW_EXPORT_PREVIEW        = 'show_export_preview'.freeze
  PREFERENCE_SHOW_COMPARE_REALISED_PLANNED = 'compare_planned_and_realised'.freeze
  PREFERENCES = {
    PREFERENCE_SHOW_MAP_INTERVENTION_FORM => :boolean,
    PREFERENCE_SHOW_EXPORT_PREVIEW => :boolean,
    PREFERENCE_SHOW_COMPARE_REALISED_PLANNED => :boolean
  }.freeze
  include Rightable
  refers_to :language
  belongs_to :team
  belongs_to :person, -> { contacts }, class_name: 'Entity'
  belongs_to :role
  has_many :crumbs
  has_many :dashboards, foreign_key: :owner_id
  has_many :notifications, foreign_key: :recipient_id, dependent: :delete_all
  has_many :unread_notifications, -> { where(read_at: nil) }, class_name: 'Notification', foreign_key: :recipient_id
  has_many :preferences, dependent: :destroy, foreign_key: :user_id
  has_many :sales_invoices, -> { where(state: 'invoice') }, through: :person, source: :managed_sales, class_name: 'Sale'
  has_many :sales, through: :person, source: :managed_sales
  has_many :deliveries, foreign_key: :responsible_id
  has_many :unpaid_sales, -> { order(:created_at).where(state: %w[order invoice]).where(lost: false).where('paid_amount < amount') }, through: :person, source: :managed_sales, class_name: 'Sale'
  has_one :worker, through: :person
  has_many :intervention_participations, through: :worker

  scope :employees, -> { where(employed: true) }
  scope :administrators, -> { where(administrator: true) }

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :administrator, :commercial, :employed, :locked, inclusion: { in: [true, false] }
  validates :authentication_token, :confirmation_token, :invitation_token, :reset_password_token, :unlock_token, uniqueness: true, length: { maximum: 500 }, allow_blank: true
  validates :confirmation_sent_at, :confirmed_at, :current_sign_in_at, :invitation_accepted_at, :invitation_created_at, :invitation_sent_at, :last_sign_in_at, :locked_at, :remember_created_at, :reset_password_sent_at, :signup_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 50.years } }, allow_blank: true
  validates :current_sign_in_ip, :employment, :last_sign_in_ip, :provider, :uid, :unconfirmed_email, length: { maximum: 500 }, allow_blank: true
  validates :description, :rights, length: { maximum: 500_000 }, allow_blank: true
  validates :email, presence: true, uniqueness: true, length: { maximum: 500 }
  validates :encrypted_password, :first_name, :last_name, presence: true, length: { maximum: 500 }
  validates :failed_attempts, :invitation_limit, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :language, presence: true
  validates :maximal_grantable_reduction_percentage, presence: true, numericality: { greater_than: -1_000_000_000_000_000, less_than: 1_000_000_000_000_000 }
  # ]VALIDATORS]
  validates :language, length: { allow_nil: true, maximum: 3 }
  # validates_presence_of :password, :password_confirmation, if: Proc.new{|e| e.encrypted_password.blank? and e.loggable?}
  validates :password, confirmation: true
  validates :maximal_grantable_reduction_percentage, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :email, :person_id, uniqueness: true
  validates :role, presence: { unless: :administrator_or_unapproved? }
  # validates_presence_of :person
  # validates_format_of :email, :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i, if: lambda{|r| !r.email.blank?}

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable, :registerable
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable, :validatable, :invitable, :omniauthable, omniauth_providers: [:ekylibre]
  model_stamper # Needed to stamp.all records
  delegate :picture, :participations, to: :person
  delegate :name, to: :role, prefix: true

  before_validation do
    self.language = Preference[:language] if language.blank?
    self.maximal_grantable_reduction_percentage ||= 0
    self.rights ||= role.rights if role
    self.rights = self.rights.to_hash if self.rights
  end

  validate on: :update do
    if self.class.administrators.count <= 1 && old_record.administrator? && !administrator?
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
      create_person!(first_name: first_name, last_name: last_name, nature: :contact)
    end
  end

  protect(on: :destroy) do
    (administrator? && self.class.administrators.count <= 1) || self.class.count <= 1
  end

  def full_name
    name
  end

  def invitation_status
    if created_by_invite?
      if invitation_accepted?
        tc('invitation.accepted')
      else
        tc('invitation.pending')
      end
    else
      tc('invitation.not_invited')
    end
  end

  def status
    return tc('status.invitation.pending') if created_by_invite? && !invitation_accepted?
    return tc('status.registration.pending') if pending_approval?
  end

  def name
    # TODO: I18nize the method User#name !
    "#{first_name} #{last_name}"
  end

  def label
    name
  end

  def theme=(value)
    prefer!(:theme, value, :string)
  end

  def theme
    preference(:theme).value
  end

  # Returns the URL of the avatar of the user
  def avatar_url(options = {})
    size = options[:size] || 200
    hash = Digest::MD5.hexdigest(email)
    "https://secure.gravatar.com/avatar/#{hash}?size=#{size}"
  end

  # Find or create preference for given name
  def preference(name, default_value = nil, nature = nil)
    p = preferences.find_by(name: name)
    p ||= prefer!(name, default_value, nature)
    p
  end

  alias pref preference

  def prefer!(name, value, nature = nil)
    p = preferences.find_or_initialize_by(name: name)
    p.nature ||= nature if nature
    p.value = value
    p.save!
    p
  end

  # Create a notification with message for given user
  def notify(message, interpolations = {}, options = {})
    attributes = options.slice(:target, :target_url, :level)
    notifications.create!(attributes.merge(message: message, interpolations: interpolations))
  end

  # Notify all administrators
  def self.notify_administrators(*args)
    User.administrators.each do |user|
      user.notify(*args)
    end
  end

  def pending_approval?
    signup_at.present?
  end

  def approved?
    !pending_approval?
  end

  def active_for_authentication?
    super && approved?
  end

  def inactive_message
    if !approved?
      :not_approved
    else
      super
    end
  end

  def authorization(controller_name, action_name, rights_list = nil)
    rights_list = rights_array if rights_list.blank?
    message = nil
    if self.class.rights[controller_name.to_sym].nil?
      message = :no_right_defined_for_this_part_of_the_application.tl(controller: controller_name, action: action_name)
    elsif (rights = self.class.rights[controller_name.to_sym][action_name.to_sym]).nil?
      message = :no_right_defined_for_this_part_of_the_application.tl(controller: controller_name, action: action_name)
    elsif (rights & %i[__minimum__ __public__]).empty? && (rights_list & rights).empty? && !administrator?
      message = :no_right_defined_for_this_part_of_the_application_and_this_user.tl
    end
    message
  end

  def can?(action, resource)
    administrator? || right_exist?(action, resource)
  end

  def can_access?(url)
    return true if administrator?
    if url.is_a?(Hash)
      unless url[:controller] && url[:action]
        raise "Invalid URL for accessibility test: #{url.inspect}"
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

  def current_campaign
    return nil unless default_campaign = Campaign.order(harvest_year: :desc).first
    preference = self.preference('current_campaign.id', default_campaign.id, :integer)
    unless campaign = Campaign.find_by(id: preference.value)
      campaign = default_campaign
      prefer!('current_campaign.id', campaign.id)
    end
    campaign
  end

  def current_campaign=(campaign)
    prefer!('current_campaign.id', campaign.id, :integer)
  end

  def current_financial_year
    default_financial_year   = FinancialYear.on(Date.current)
    default_financial_year ||= FinancialYear.closest(Date.current)
    return nil unless default_financial_year
    preference = self.preference('current_financial_year', default_financial_year, :record)
    unless financial_year = preference.value
      financial_year = default_financial_year
      prefer!('current_financial_year', financial_year)
    end
    financial_year
  end

  def current_financial_year=(financial_year)
    prefer!('current_financial_year', financial_year, :record)
  end

  def current_period_interval
    preference('current_period_interval', :year, :string).value
  end

  def current_period_interval=(period_interval)
    prefer!('current_period_interval', period_interval, :string)
  end

  def current_period
    preference('current_period', Date.today, :string).value
  end

  def current_period=(period)
    prefer!('current_period', period, :string)
  end

  def mask_lettered_items?(options = {})
    preference_name = options[:controller] || 'all'
    preference_name << ".#{options[:context]}" if options[:context]
    preference_name << '.lettered_items.masked'
    preference(preference_name, false, :boolean).value
  end

  def mask_draft_items?(options = {})
    preference_name = options[:controller] || 'all'
    preference_name << ".#{options[:context]}" if options[:context]
    preference_name << '.draft_items.masked'
    preference(preference_name, false, :boolean).value
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

  def administrator_or_unapproved?
    administrator? || !approved?
  end

  def self.generate_password(password_length = 8, mode = :normal)
    return '' if password_length.blank? || password_length < 1
    letters = case mode
              when :dummy then
                %w[a b c d e f g h j k m n o p q r s t u w x y 3 4 6 7 8 9]
              when :simple then
                %w[a b c d e f g h j k m n o p q r s t u w x y A B C D E F G H J K M N P Q R T U W Y X 3 4 6 7 8 9]
              when :normal then
                %w[a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9]
              else
                %w(a b c d e f g h i j k l m n o p q r s t u v w x y z A B C D E F G H I J K L M N O P Q R S T U V W Y X Z 0 1 2 3 4 5 6 7 8 9 _ = + - * | [ ] { } . : ; ! ? , § % / & < >)
              end
    letters_length = letters.length
    password = ''
    password_length.times { password += letters[(letters_length * rand).to_i] }
    password
  end
end
