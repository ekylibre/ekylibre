# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2013-2015 Brice Texier, David Joulin
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
  class AnalysesController < Backend::BaseController
    manage_restfully sampled_at: 'Time.zone.now'.c, sampler_id: 'current_user.person.id'.c

    unroll

    # params:
    #   :q Text search
    #   :s State search
    #   :period Two Dates with _ separator
    #   :variant_id
    def self.analyses_conditions
      code = ''
      code = search_conditions(entities: [:full_name], analyses: %i[reference_number number]) + " ||= []\n"
      code << "  if params[:sampler_id].to_i > 0\n"
      code << "    c[0] << \" AND \#{Entity.table_name}.id = ?\"\n"
      code << "    c << params[:sampler_id].to_i\n"
      code << "  end\n"
      code << "  unless params[:nature].blank?\n"
      code << "    if Analysis.nature.values.include?(params[:nature].to_sym)\n"
      code << "      c[0] << ' AND #{Analysis.table_name}.nature = ?'\n"
      code << "      c << params[:nature]\n"
      code << "    end\n"
      code << "  end\n"
      code << "c\n"
      code.c
    end

    list(conditions: analyses_conditions) do |t|
      t.action :edit
      t.action :destroy
      t.column :number, url: true
      t.column :reference_number, url: true
      t.column :nature
      t.column :product, url: true
      t.column :analyser, url: true
      t.column :analysed_at
      t.column :sampled_at, hidden: true
      t.column :sampler, url: true, hidden: true
    end

    list :items, model: :analysis_items, conditions: { analysis_id: 'params[:id]'.c } do |t|
      t.column :indicator, datatype: :item
      t.column :value, datatype: :measure
      t.column :annotation
    end
  end
end
