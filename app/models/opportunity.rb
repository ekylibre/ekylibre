# -*- coding: utf-8 -*-
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
# == Table: opportunities
#
#  affair_id      :integer
#  client_id      :integer          not null
#  created_at     :datetime         not null
#  creator_id     :integer
#  currency       :string
#  dead_line_at   :datetime
#  description    :text
#  id             :integer          not null, primary key
#  lock_version   :integer          default(0), not null
#  name           :string
#  number         :string
#  origin         :string
#  pretax_amount  :decimal(19, 4)   default(0.0)
#  probability    :decimal(19, 4)   default(0.0)
#  responsible_id :integer          not null
#  state          :string
#  updated_at     :datetime         not null
#  updater_id     :integer
#



class Opportunity < Ekylibre::Record::Base
  include Versionable, Commentable
  attr_readonly :currency
  enumerize :origin, in: Nomen::OpportunityCategories.all, predicates: true
  belongs_to :affair
  belongs_to :client, class_name: "Entity"
  belongs_to :responsible, class_name: "Person"
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_datetime :dead_line_at, allow_blank: true, on_or_after: Time.new(1, 1, 1, 0, 0, 0, '+00:00')
  validates_numericality_of :pretax_amount, :probability, allow_nil: true
  validates_presence_of :client, :responsible
  #]VALIDATORS]
  acts_as_numbered :number, readonly: false

  state_machine :state, :initial => :prospecting do
    state :prospecting
    state :qualification
    state :value_proposition
    state :price_quote
    state :negociation
    state :won
    state :lost

    event :qualify do
      transition :prospecting => :qualification
    end

    event :evaluate do
      transition :qualification => :value_proposition
    end

    event :quote do
      transition :value_proposition => :price_quote
    end

    event :negociation do
      transition :price_quote => :negociation
    end

    event :win do
      transition :negociation => :won
    end

    event :lose do
      transition :negociation => :lost
    end


  end

  def status
    if self.state == :lost
      return  :stop
    elsif self.state == :win
      return :go
    else
      return :caution
    end
  end

end


