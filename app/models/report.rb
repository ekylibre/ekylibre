class Report < ActiveRecord::Base
  


  PRIVATE='private/'
  REPORTS='reports/'
  
 # this function saves the pdf document genererated by the function render_report in the table reports in the database
  def self.register(digest,id,binary,title,extension=nil)  
    Dir.mkdir('#{RAILS_ROOT}/'+PRIVATE+REPORTS) unless Dir.entries '#{RAILS_ROOT}/'+PRIVATE+REPORTS 
   
    binary_digest=Digest::SHA256.hexdigest(binary)
   
    unless Report.exists?(["sha256 LIKE ?", "%#{binary_digest}%"])
      report=Report.new
      report.key=id 
      report.template_md5=digest
      report.sha256=binary_digest
      report.original_name=title
      report.printed_at=Time.now  
      report.save!     
      report.filename=PRIVATE+REPORTS+report.id.to_s
      send_data binary, :filename=>PRIVATE+REPORTS+report.id.to_s+extension
      report.save!
    end
    
  end
end
