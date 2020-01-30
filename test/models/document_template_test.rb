# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2009 Brice Texier, Thibaud Merigon
# Copyright (C) 2010-2012 Brice Texier
# Copyright (C) 2012-2014 Brice Texier, David Joulin
# Copyright (C) 2015-2020 Ekylibre SAS
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
# == Table: document_templates
#
#  active         :boolean          default(FALSE), not null
#  archiving      :string           not null
#  by_default     :boolean          default(FALSE), not null
#  created_at     :datetime         not null
#  creator_id     :integer
#  file_extension :string           default("xml")
#  formats        :string
#  id             :integer          not null, primary key
#  language       :string           not null
#  lock_version   :integer          default(0), not null
#  managed        :boolean          default(FALSE), not null
#  name           :string           not null
#  nature         :string           not null
#  signed         :boolean          default(FALSE), not null
#  updated_at     :datetime         not null
#  updater_id     :integer
#

require 'test_helper'

class DocumentTemplateTest < Ekylibre::Testing::ApplicationTestCase::WithFixtures
  test_model_actions
  # Tests all templates
  test 'compile all templates' do
    # Load all templates
    assert_nothing_raised do
      DocumentTemplate.load_defaults
    end

    managed_purchase_invoice = DocumentTemplate.where(nature: :sales_invoice, managed: true)
    assert_equal 1, managed_purchase_invoice.count
    assert_equal 'odt', managed_purchase_invoice.first.file_extension
    # TODO: Check that XML are good to use
  end
end
