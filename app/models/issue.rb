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
# == Table: issues
#
#  created_at           :datetime         not null
#  creator_id           :integer
#  custom_fields        :jsonb
#  dead                 :boolean          default(FALSE)
#  description          :text
#  geolocation          :geometry({:srid=>4326, :type=>"st_point"})
#  gravity              :integer
#  id                   :integer          not null, primary key
#  lock_version         :integer          default(0), not null
#  name                 :string           not null
#  nature               :string           not null
#  observed_at          :datetime         not null
#  picture_content_type :string
#  picture_file_name    :string
#  picture_file_size    :integer
#  picture_updated_at   :datetime
#  priority             :integer
#  state                :string
#  target_id            :integer
#  target_type          :string
#  updated_at           :datetime         not null
#  updater_id           :integer
#

class Issue < Ekylibre::Record::Base
  include Attachable
  include Commentable
  include Versionable
  include Customizable
  refers_to :nature, class_name: 'IssueNature'
  has_many :interventions
  belongs_to :target, polymorphic: true

  has_geometry :geolocation, type: :point
  has_picture

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates :dead, inclusion: { in: [true, false] }, allow_blank: true
  validates :description, length: { maximum: 500_000 }, allow_blank: true
  validates :gravity, :picture_file_size, :priority, numericality: { only_integer: true, greater_than: -2_147_483_649, less_than: 2_147_483_648 }, allow_blank: true
  validates :name, presence: true, length: { maximum: 500 }
  validates :nature, presence: true
  validates :observed_at, presence: true, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }
  validates :picture_content_type, :picture_file_name, :state, :target_type, length: { maximum: 500 }, allow_blank: true
  validates :picture_updated_at, timeliness: { on_or_after: -> { Time.new(1, 1, 1).in_time_zone }, on_or_before: -> { Time.zone.now + 100.years } }, allow_blank: true
  # ]VALIDATORS]
  validates :priority, :gravity, inclusion: { in: 0..5 }
  validates_attachment_content_type :picture, content_type: /image/

  delegate :count, to: :interventions, prefix: true

  scope :of_campaign, lambda { |campaign|
    where(target_id: Product.where(activity_production_id: ActivityProduction.of_campaign(campaign).select(:id)))
  }

  scope :of_activity, lambda { |activity|
    where(target_id: Product.where(activity_production_id: activity.productions.select(:id)))
  }

  scope :opened, lambda {
    where(state: 'opened')
  }

  state_machine :state, initial: :opened do
    ## define states
    state :opened
    state :closed
    state :aborted

    ## define events

    # # way A1
    # event :treat do
    #   transition :opened => :in_progress, if: :has_intervention?
    # end

    # way A2
    event :close do
      # transition :in_progress => :closed, if: :has_intervention?
      transition opened: :closed # , if: :has_intervention?
    end

    # way B1
    event :abort do
      transition opened: :aborted
      # transition :in_progress => :aborted
    end

    # way A3 || B2
    event :reopen do
      transition closed: :opened
      transition aborted: :opened
    end

    ## define callbacks after and before transition
  end

  before_validation do
    self.state ||= :opened
    self.target_type = target.class.base_class.name if target
    self.priority ||= 0
    self.gravity ||= 0
    if nature
      self.name = (target ? tc(:name_with_target, nature: nature.l, target: target.name) : tc(:name_without_target, nature: nature.l))
    end
  end

  after_save do
    if target && dead && (!target.dead_at || target.dead_at > observed_at)
      target.update_columns dead_at: observed_at
    end
  end

  after_destroy do
    target.update_columns(dead_at: target.dead_first_at) if target && dead
  end

  protect(on: :destroy) do
    has_intervention?
  end

  def has_intervention?
    interventions.any?
  end

  def status
    if opened?
      (has_intervention? ? :caution : :stop)
    else
      :go
    end
  end

  def picture_path(style = :original)
    picture.path(style)
  end

  def target_name
    target ? target.name : :none.tl
  end
end
