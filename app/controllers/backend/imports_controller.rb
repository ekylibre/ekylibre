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

module Backend
  class ImportsController < Backend::BaseController
    manage_restfully t3e: { name: :name }

    list line_class: "RECORD.errored? ? 'error' : ''".c do |t|
      t.action :new, on: :none
      t.action :run, method: :post, if: :runnable?
      t.action :edit
      t.action :destroy
      t.column :nature, url: true
      t.column :state
      t.column :created_at
      t.column :imported_at
      t.column :importer
    end

    def run
      import = find_and_check
      return unless import
      import.run_later
      redirect_to params[:redirect] || { action: :index }
    end

    def progress
      @import = find_and_check
      return unless @import
      render partial: 'progress', locals: { import: @import }
    end

    def abort
      @import = find_and_check
      return unless @import
      @import.abort
      redirect_to params[:redirect] || { action: :index }
    end
  end
end
