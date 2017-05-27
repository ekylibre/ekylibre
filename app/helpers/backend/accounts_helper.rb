# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2013 Brice Texier
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
  module AccountsHelper
    def major_accounts_tabs_tag
      majors = Account.majors
      if majors.count > 0
        html = content_tag(:dt, :accounts.tl)
        html << content_tag(:dd, link_to(:all_accounts.tl, params.merge(controller: :accounts, action: :index, prefix: nil)), (params[:prefix].blank? ? { class: :active } : nil))
        for account in majors
          html << content_tag(:dd, link_to(account.label, params.merge(controller: :accounts, action: :index, prefix: account.number)), (params[:prefix] == account.number.to_s ? { class: :active } : nil))
        end
        return content_tag(:dl, html, id: 'major-accounts')
      end
      ''
    end

    # Create a widget to select ranges of account
    # See Account#range_condition
    def accounts_range_crit(*_args)
      id = :accounts
      params[id] = Account.clean_range_condition(params[id])
      code = ''
      code << content_tag(:label, :accounts.tl, for: id)
      code << ' ' << text_field_tag(id, params[id], size: 30)
      code.html_safe
    end
  end
end
