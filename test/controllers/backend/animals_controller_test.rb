# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

require 'test_helper'
module Backend
  class AnimalsControllerTest < ActionController::TestCase
    test_restfully_all_actions add_to_variant: :get_and_post,
                               # add_to_group: :get_and_post, # TODO: Re-activate this test
                               add_to_container: :get_and_post,
                               add_group: { mode: :create,
                                            params: { variant_id: 31,
                                                      name: 'Fluffy' } },
                               except: %i[change matching_interventions load_animals add_to_group]
    # TODO: Re-activate #matching_interventions, #add_to_group and #load_animals tests
  end
end
