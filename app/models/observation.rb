class Observation < ActiveRecord::Base

  belongs_to :company
  belongs_to :entity


  
 def self.importances
   [:important, :normal, :notice].collect{|x| [tc('importances.'+x.to_s), x] }
 end


 def text_importance
    tc('importances.'+self.importance.to_s)
 end

 def status
   status = ""
   case self.importance
   when "important"
     status = "critic"
   when "normal"
     status = "minimum"
   end
   status
 end
 
end
