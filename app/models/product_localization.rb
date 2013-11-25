# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
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
# == Table: product_localizations
#
#  arrival_cause   :string(255)
#  container_id    :integer
#  created_at      :datetime         not null
#  creator_id      :integer
#  departure_cause :string(255)
#  id              :integer          not null, primary key
#  lock_version    :integer          default(0), not null
#  nature          :string(255)      not null
#  operation_id    :integer
#  product_id      :integer          not null
#  started_at      :datetime
#  stopped_at      :datetime
#  updated_at      :datetime         not null
#  updater_id      :integer
#

class ProductLocalization < Ekylibre::Record::Base
  include Taskable
  belongs_to :container, class_name: "Product"
  belongs_to :product
  enumerize :nature, in: [:transfer, :interior, :exterior], default: :interior, predicates: true
  enumerize :arrival_cause,   in: [:birth, :housing, :other, :purchase], default: :birth, predicates: {prefix: true}
  enumerize :departure_cause, in: [:death, :consumption, :other, :sale], default: :sale,  predicates: {prefix: true}
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :arrival_cause, :departure_cause, :nature, allow_nil: true, maximum: 255
  validates_presence_of :nature, :product
  #]VALIDATORS]
  validates_inclusion_of :nature, in: self.nature.values
  validates_presence_of :container, :if => :interior?
  validates_presence_of :started_at, :if => :has_previous?
  validates_presence_of :stopped_at, :if => :has_followings?

  scope :at, lambda { |at| where("? BETWEEN COALESCE(started_at, ?) AND COALESCE(stopped_at, ?)", at, at, at) }
  scope :after,  lambda { |at| where("COALESCE(started_at, ?) > ?", at, at) }
  scope :before, lambda { |at| where("COALESCE(started_at, ?) < ?", at, at) }

  before_validation do
    if following = self.product.localizations.after(self.started_at).order(:started_at).first
      self.stopped_at = following.started_at
    else
      self.stopped_at = nil
    end
  end

  after_save do
    self.previous.update_column(:stopped_at, self.started_at) if self.previous
  end

  after_destroy do
    self.previous.update_column(:stopped_at, self.stopped_at) if self.previous
  end

  def previous
    return nil unless self.started_at
    return self.product.localizations.find_by(stopped_at: self.started_at)
  end

  def following
    return nil unless self.stopped_at
    return self.product.localizations.find_by(started_at: self.stopped_at)
  end

  def has_previous?
    self.product.localizations.before(self.started_at).any?
  end

  def has_followings?
    self.product.localizations.after(self.started_at).any?
  end

  def intervention_name
    return (self.operation ? self.operation.intervention_name : nil)
  end

end
