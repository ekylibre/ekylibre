# = Informations
#
# == License
#
# Ekylibre - Simple agricultural ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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

class ImportRunJob < ApplicationJob
  queue_as :default

  def safe_perform(import)
    begin
      import.run_result
    rescue StandardError => e
      ActiveExchanger::Result.failed('Unknown error while running job', exception: e)
    end
  end

  def perform(import_id)
    import = Import.find(import_id)

    Version.with_current_user(import.creator) do
      result = safe_perform(import)
      if result.success?
        import.notify(:import_finished_successfully)
      else
        import.notify(:import_failed, { message: result.message }, level: :error)

        raise result.exception if result.exception.present?
      end
    end
  end
end
