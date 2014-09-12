# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
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

class Backend::ImportsController < BackendController

  def index
    @supported_files = [["EBP.EDI", :ebp_edi]]
  end

  def ask
  end

  def run
    @supported_files = [["EBP.EDI", :ebp_edi]]
    if request.post?
      data = params[:upload]
      file = Rails.root.join("tmp", "uploads", "#{data.original_filename}.#{rand.to_s[2..-1].to_i.to_s(36)}")
      FileUtils.mkdir_p(file.dirname)
      File.open(file, "wb:ASCII-8BIT") do |f|
        f.write data.read
      end
      if params[:nature] == "ebp_edi"
        Exchanges::EbpEdi.import(file)
      else
        notify_error_now(:invalid_file_nature)
      end
    end

  end

end
