# encoding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2014 Brice Texier, David Joulin
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class Backend::GuidesController < BackendController
  manage_restfully

  unroll

  list do |t|
    t.column :name, url: true
    t.column :active
    t.status
    t.column :nature
    t.column :external
    t.action :run, method: :post
    t.action :edit
    t.action :destroy
  end

  list(:analyses, model: :guide_analyses, conditions: {guide_id: 'params[:id]'.c}, order: {execution_number: :desc}) do |t|
    t.column :execution_number, url: true
    t.status
    t.column :started_at, hidden: true
    t.column :stopped_at
  end

  def run
    notify_warning(:implemented_with_dummy_data)
    @guide = find_and_check
    statuses = [:passed, :failed, :passed_with_warnings]
    analysis = @guide.analyses.create!(acceptance_status: statuses.sample, started_at: Time.now - 10, stopped_at: Time.now)
    (14 * @guide.name.size).times do |i|
      status = statuses.sample
      analysis.points.create!(acceptance_status: status, reference_name: "#{@guide.name.parameterize.underscore}_check_#{i}", advice_reference_name: (status.to_s == "failed" ? "do_something" : nil))
    end
    redirect_to action: :show
  end

end
