# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2016 Brice Texier, David Joulin
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
#  description          :text
#  geolocation          :geometry({:srid=>4326, :type=>"point"})
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
#  target_id            :integer          not null
#  target_type          :string           not null
#  updated_at           :datetime         not null
#  updater_id           :integer
#

class Issue < Ekylibre::Record::Base
  include Versionable, Commentable, Attachable
  include Customizable
  refers_to :nature, class_name: 'IssueNature'
  has_many :interventions
  belongs_to :target, polymorphic: true

  has_geometry :geolocation, type: :point
  has_picture

  # [VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :observed_at, :picture_updated_at, allow_blank: true, on_or_after: DateTime.civil(1900, 1, 1), on_or_before: -> { DateTime.now + 50.years }
  validates_numericality_of :gravity, :picture_file_size, :priority, allow_nil: true, only_integer: true
  validates_presence_of :name, :nature, :observed_at, :target, :target_type
  # ]VALIDATORS]
  validates_inclusion_of :priority, :gravity, in: 0..5
  validates_attachment_content_type :picture, content_type: /image/

  delegate :name, to: :target, prefix: true
  delegate :count, to: :interventions, prefix: true

  scope :of_campaign, lambda { |campaign|
    where(target_id: TargetDistribution.of_campaign(campaign), target_type: 'Product')
  }

  scope :of_activity, lambda { |activity|
    where(target_id: TargetDistribution.of_activity(activity), target_type: 'Product')
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

  protect(on: :destroy) do
    has_intervention?
  end

  def has_intervention?
    interventions.any?
  end

  def status
    if opened?
      return (has_intervention? ? :caution : :stop)
    else
      return :go
    end
  end

  def picture_path(style = :original)
    picture.path(style)
  end
end
