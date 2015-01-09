# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::ImportsController < BackendController
  manage_restfully t3e: {name: :name}

  list line_class: "RECORD.errored? ? 'error' : ''".c do |t|
    t.column :nature
    t.column :state
    t.column :created_at
    t.column :imported_at
    t.column :importer
    t.action :new, on: :none
    t.action :run, method: :post, if: :runnable?
    t.action :edit
    t.action :destroy
  end

  def run
    return unless import = find_and_check
    begin
      Import.find(import.id).run
    rescue Exchanges::Error => e
      notify_error :cannot_import_file, message: e.message
    rescue Exception => e
      notify_error :exception_raised, message: e.message
    end
    # TODO: Activate background tasks
    # ImportJob.enqueue(import.id)
    redirect_to action: :index
  end

end
