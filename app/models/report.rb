# == Schema Information
# Schema version: 20080819191919
#
# Table name: reports
#
#  id            :integer       not null, primary key
#  filename      :string(255)   not null
#  original_name :string(255)     not null
#  template_md5  :string(255)     
#  printed_at    :datetime
#  company_id    :integer


class Report < ActiveRecord::Base
  

  PRIVATE='private/'
  REPORTS='reports/'
  
 # this function saves the pdf document genererated by the function render_report in the table reports in the database
  def self.register(template_md5,key,binary,title)  

    Dir.mkdir(PRIVATE+REPORTS) unless File.directory? PRIVATE+REPORTS 
    
    binary_digest=Digest::SHA256.hexdigest(binary)

    unless Report.exists?(["template_md5 = ? AND key = ?", template_md5, key])
      report=Report.create!(:key=>key,:template_md5=>template_md5,:sha256=>binary_digest, :original_name=>title, :printed_at=>Time.now,:company_id=>1)
      report.filename=PRIVATE+REPORTS+report.id.to_s
      
      f=File.open(PRIVATE+REPORTS+report.id.to_s,'wb')
      f.write(binary)
      f.close()
      
      report.save!
      
    end

  end
end
