# -*- coding: utf-8 -*-
# == License
# Ekylibre - Simple ERP
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

class SettingsController < AdminController

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


  # Simple page dedicated to backup management
  # FIXME Rebuild backup system with SQL approach ?
  def backups
  end


  # Create a backup in a zipball
  def backup
    backup = Ekylibre::Backup.create(:creator => current_user.full_name, :with_prints => params[:with_prints])
    send_file(backup) # , :stream => false
    # File.delete(backup)
  end


  # Removes existing data and restore all data contained in zipball
  # All the operations are included in one transaction
  def restore
    backup = params[:file][:path]
    file = Rails.root.join("tmp", "uploads", backup.original_filename + "." + rand.to_s[2..-1].to_i.to_s(36))
    FileUtils.mkdir_p(file.dirname)
    File.open(file, "wb") { |f| f.write(backup.read) }
    user_name = current_user.user_name
    start = Time.now
    if Ekylibre::Backup.restore(file)
      # TODO: Restore session of current_user ?
      notify_success_now(:restoration_finished, :value => (Time.now - start).to_s)
    else
      notify_error_now(:unvalid_version_for_restore)
    end
    render :backups
  end



  def import
    @supported_files = [["EBP.EDI", :ebp_edi]]
    if request.post?
      data = params[:upload]
      file = "#{Rails.root.to_s}/tmp/uploads/#{data.original_filename}.#{rand.to_s[2..-1].to_i.to_s(36)}"
      File.open(file, "wb") {|f| f.write(data.read)}
      if params[:nature] == "ebp_edi"
        File.open(file, "rb:CP1252") do |f|
          unless f.readline.match(/^EBP\.EDI$/)
            notify_error_now(:bad_file)
            return
          end
          encoding = f.readline
          f.readline
          owner = f.readline
          started_on = f.readline
          started_on = Date.civil(started_on[4..7].to_i, started_on[2..3].to_i, started_on[0..1].to_i)
          stopped_on = f.readline
          stopped_on = Date.civil(stopped_on[4..7].to_i, stopped_on[2..3].to_i, stopped_on[0..1].to_i)
          ic = Iconv.new("utf-8", "cp1252")
          begin
            ActiveRecord::Base.transaction do
              while 1
                begin
                  line = f.readline.gsub(/\n/, '')
                rescue
                  break
                end
                unless @current_company.financial_years.find_by_started_on_and_stopped_on(started_on, stopped_on)
                  @current_company.financial_years.create!(:started_on=>started_on, :stopped_on=>stopped_on)
                end
                line = ic.iconv(line).split(/\;/)
                if line[0] == "C"
                  unless @current_company.accounts.find_by_number(line[1])
                    @current_company.accounts.create!(:number=>line[1], :name=>line[2])
                  end
                elsif line[0] == "E"
                  unless journal = @current_company.journals.find_by_code(line[3])
                    journal = @current_company.journals.create!(:code=>line[3], :name=>line[3], :nature=>Journal.natures[-1][1].to_s, :closed_on=>started_on-1)
                  end
                  number = line[4].blank? ? "000000" : line[4]
                  line[2] = Date.civil(line[2][4..7].to_i, line[2][2..3].to_i, line[2][0..1].to_i)
                  unless entry = journal.entries.find_by_number_and_printed_on(number, line[2])
                    entry = journal.entries.create!(:number=>number, :printed_on=>line[2])
                  end
                  unless account = @current_company.accounts.find_by_number(line[1])
                    account = @current_company.accounts.create!(:number=>line[1], :name=>line[1])
                  end
                  line[8] = line[8].strip.to_f
                  if line[7] == "D"
                    entry.add_debit(line[6], account, line[8], :letter=>line[10])
                  else
                    entry.add_credit(line[6], account, line[8], :letter=>line[10])
                  end
                end
              end
            end
            notify_success_now(:importation_finished)
          rescue Exception => e
            notify_error_now(:importation_cancelled)
          end
        end
      else
        notify_error_now(:invalid_file_nature)
      end
    end

  end


end
