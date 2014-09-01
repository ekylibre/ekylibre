# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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

class CrumbSet

  attr_reader :crumbs, :start, :started_at, :stopped_at, :user, :device_uid, :intervention_cast, :procedure_nature

  delegate :possible_procedures_matching, to: :start
  delegate :each, :to_a, :where, :order, :update_all, to: :crumbs

  def initialize(crumbs)
    @crumbs = crumbs
    @start = @crumbs.first
    @procedure_nature = Nomen::ProcedureNatures[@start.metadata['procedure_nature']]
    @started_at = @start.read_at
    @stopped_at = @crumbs.last.read_at
    @user = @start.user
    @device_uid = @start.device_uid
    @intervention_cast = @start.intervention_cast
  end

  def human_name
    :intervention_at.tl(intervention: @procedure_nature.human_name, at: @start.read_at.l)
  end

  def id
    "set_#{start.id}"
  end

  def casted?
    !@intervention_cast.nil?
  end

  def intervention
    return (@intervention_cast ? @intervention_cast.intervention : nil)
  end

end
