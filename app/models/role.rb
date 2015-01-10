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
# == Table: roles
#
#  company_id   :integer          not null
#  created_at   :datetime         not null
#  creator_id   :integer          
#  id           :integer          not null, primary key
#  lock_version :integer          default(0), not null
#  name         :string(255)      not null
#  rights       :text             
#  updated_at   :datetime         not null
#  updater_id   :integer          
#


class Role < CompanyRecord
  #[VALIDATORS[
  # Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :name, :allow_nil => true, :maximum => 255
  #]VALIDATORS]
  attr_readonly :company_id
  belongs_to :company
  has_many :users
  validates_uniqueness_of :name, :scope=>:company_id

  before_validation do
    self.rights_array=self.rights_array # Clean the rights
  end

  after_validation(:on=>:update) do
    old_rights_array = []
    new_rights_array = []
    old_rights = Role.find_by_id_and_company_id(self.id, self.company_id).rights.to_s.split(" ")
    
    for right in old_rights
      old_rights_array << right.to_sym
    end
    for right in self.rights.split(/\s+/)
      new_rights_array << right.to_sym
    end

    added_rights = new_rights_array-old_rights_array
    deleted_rights = old_rights_array- new_rights_array
    
    users = User.find_all_by_role_id_and_company_id_and_admin(self.id, self.company_id, false)
    for user in users
      # puts user.rights.inspect
      user_rights_array = []
      for right in user.rights.split(/\s+/)
        user_rights_array << right.to_sym
      end
      
      user_rights_array.delete_if {|r| deleted_rights.include?(r) }
      for added_right in added_rights
        user_rights_array << added_right unless user_rights_array.include?(added_right)
      end
         
      user.rights = ""
        for right in user_rights_array
          user.rights += right.to_s+" "
        end
      user.save
      # puts user.rights.inspect
    end
  end

  def rights_array
    self.rights.to_s.split(/\s+/).collect{|x| x.to_sym}
  end

  def rights_array=(array)
    self.rights = array.select{|x| User.rights_list.include?(x.to_sym)}.join(" ")
  end

  protect_on_destroy do
    self.users.size <= 0
  end

  def diff_more; ''; end
  def diff_less; ''; end

end
