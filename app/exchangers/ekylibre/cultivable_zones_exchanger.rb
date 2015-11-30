class Ekylibre::CultivableZonesExchanger < ActiveExchanger::Base
  # Create or updates cultivable zones
  def import
    rows = CSV.read(file, headers: true).delete_if { |r| r[0].blank? }
    w.count = rows.size

    born_at = Time.utc(1900, 1, 1, 0, 0, 0)

    rows.each do |row|
      r = {
        name: row[0].to_s,
        nature: (row[1].blank? ? nil : row[1].to_sym),
        code: (row[2].blank? ? nil : row[2].to_s),
        georeading_number: (row[3].blank? ? nil : row[3].to_s)
        # members: row[4].blank? ? [] : row[4].to_s.strip.split(/[[:space:]]*\,[[:space:]]*/)
      }.to_struct

      georeading = Georeading.find_by(number: r.georeading_number)
      fail "Cannot find georeading: #{r.georeading_number}" unless georeading
      zone = CultivableZone.find_or_initialize_by(work_number: r.code)
      zone.name = r.name
      zone.shape = georeading.content
      zone.save!
      w.check_point
    end
  end
end
