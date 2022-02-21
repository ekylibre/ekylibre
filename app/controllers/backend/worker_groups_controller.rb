# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 David Joulin, Brice Texier
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
  class WorkerGroupsController < Backend::BaseController
    manage_restfully

    unroll

    before_action :kujaku_options, only: %i[index]

    def kujaku_options
      @usages = WorkerGroup.all.map(&:usage).uniq
    end

    def self.worker_groups_conditions
      code = ''
      code << search_conditions(worker_groups: %i[name], products: %i[name]) + " ||= []\n"
      code << "unless params[:usage].blank? \n"
      code << "  c[0] << ' AND usage = ?'\n"
      code << "  c << params[:usage]\n"
      code << "end\n"
      code << "c\n "
      code.c
    end

    list selectable: true, conditions: worker_groups_conditions, joins: "
      LEFT JOIN worker_group_items ON worker_group_items.worker_group_id = worker_groups.id
      LEFT JOIN products ON products.id = worker_group_items.worker_id ", distinct: true do |t|
      t.action :edit
      t.action :destroy, if: :destroyable?
      t.action :duplicate, method: :post
      t.column :name, url: true
      t.column :workers_name, label: :worker
      t.column :work_number
      t.column :usage
      t.column :group_size, label: :group_size
    end

    list(:workers, joins: :worker_groups, conditions: ['worker_groups.id = ?', 'params[:id]'.c], order: { name: :asc }) do |t|
      t.column :number, url: true
      t.column :work_number
      t.column :name, url: true
      t.column :variant, url: { controller: 'RECORD.variant.class.name.tableize'.c, namespace: :backend }
      t.column :variety
      t.column :container, url: true
      t.column :description
    end

    def duplicate
      return unless worker_group = find_and_check

      duplicate_wg = duplicate_worker_group(worker_group)
      duplicate_wg.save!

      redirect_to action: :index
    end

    def new
      @worker_group = resource_model.new(active: params[:active], name: params[:name], usage: params[:usage], work_number: params[:work_number])
      if params[:worker_ids]
        worker_ids = params[:worker_ids].split(',')
        worker_ids.each do |id|
          @worker_group.items << WorkerGroupItem.new(worker_id: id)
        end
        @worker_group.name = :group.tl
      end
      render(locals: { cancel_url: { action: :index }, with_continue: false })
    end

    private

      def duplicate_worker_group(worker_group)
        index = worker_group.class.where('name like ?', "#{worker_group.name}%").count
        new_worker_group = worker_group.dup.tap { |dup| dup.name = "#{worker_group.name} (#{index})" }
        new_worker_group.items.build(
          worker_group.items.map {|item| item.dup.attributes }
        )
        new_worker_group
      end

  end
end
