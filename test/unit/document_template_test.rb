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
# == Table: document_templates
#
#  active       :boolean          not null
#  by_default   :boolean          default(TRUE), not null
#  cache        :text
#  code         :string(32)
#  country      :string(2)
#  created_at   :datetime         not null
#  creator_id   :integer
#  family       :string(32)
#  filename     :string(255)
#  id           :integer          not null, primary key
#  language     :string(3)        default("???"), not null
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  nature       :string(64)
#  source       :text
#  to_archive   :boolean
#  updated_at   :datetime         not null
#  updater_id   :integer
#


require 'test_helper'

class DocumentTemplateTest < ActiveSupport::TestCase

  # Tests all templates
  test "compile all templates" do
    for locale in I18n.active_locales
      # Load all templates
      assert_nothing_raised do
        DocumentTemplate.load_defaults(:locale => locale)
      end
      # Compile all templates
      DocumentTemplate.where(:language => locale.to_s).find_each do |template|
        assert_not_nil template.nature, template.inspect
        if DocumentTemplate.document_natures[template.nature.to_sym].size > 0
          assert_raise ArgumentError do
            DocumentTemplate.print(template.nature)
          end
        else
          assert_nothing_raised do
            DocumentTemplate.print(template.nature)
          end
        end
        code = ""
        assert_nothing_raised(template.source) do
          code = Templating.compile(template.source, :xil, :mode => :debug)
        end
        # assert_nothing_raised(code) do
        #   eval(code)
        # end
      end
    end
  end


end
