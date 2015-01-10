# = Informations
# 
# == License
# 
# Ekylibre - Simple ERP
# Copyright (C) 2009-2015 Brice Texier, Thibaud Merigon
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
# == Table: documents
#
#  company_id    :integer          not null
#  created_at    :datetime         not null
#  creator_id    :integer          
#  crypt_key     :binary           
#  crypt_mode    :string(255)      not null
#  extension     :string(255)      
#  filename      :string(255)      
#  filesize      :integer          
#  id            :integer          not null, primary key
#  lock_version  :integer          default(0), not null
#  nature_code   :string(255)      
#  original_name :string(255)      not null
#  owner_id      :integer          
#  owner_type    :string(255)      
#  printed_at    :datetime         
#  sha256        :string(255)      not null
#  subdir        :string(255)      
#  template_id   :integer          
#  updated_at    :datetime         not null
#  updater_id    :integer          
#


