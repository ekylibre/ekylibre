# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2008-2011 Brice Texier, Thibaud Merigon
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

class Backend::SettingsController < BackendController

  def edit
  end

  def update
    saved = true
    ActiveRecord::Base.transaction do
      for key, data in params[:preference]
        if preference = Preference.get(key)
          preference.value = params[:value]
          preference.save
        else
          saved = false
        end
      end
    end
    redirect_to_back and return if saved
    render :edit
  end


  def about
    @properties = []
    @properties.insert(0, ["Ekylibre version", Ekylibre.version])
    @properties << ["Database version", ActiveRecord::Migrator.current_version]
  end


  # # Simple page dedicated to backup management
  # # FIXME Rebuild backup system with SQL approach ?
  # def backups
  # end


  # # Create a backup in a zipball
  # def backup
  #   backup = Ekylibre::Backup.create(:creator => current_user.full_name, :with_prints => params[:with_prints])
  #   send_file(backup) # , :stream => false
  #   # File.delete(backup)
  # end


  # # Removes existing data and restore.all data contained in zipball
  # # All the operations are included in one transaction
  # def restore
  #   backup = params[:file][:path]
  #   file = Rails.root.join("tmp", "uploads", backup.original_filename + "." + rand.to_s[2..-1].to_i.to_s(36))
  #   FileUtils.mkdir_p(file.dirname)
  #   File.open(file, "wb") { |f| f.write(backup.read) }
  #   user_name = current_user.user_name
  #   start = Time.now
  #   if Ekylibre::Backup.restore(file)
  #     # TODO: Restore session of current_user ?
  #     notify_success_now(:restoration_finished, :value => (Time.now - start).to_s)
  #   else
  #     notify_error_now(:unvalid_version_for_restore)
  #   end
  #   render :backups
  # end


  def import
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
