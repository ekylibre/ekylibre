module FormObjects
    module Backend
        module ControllerHelpers
            module ActivityProductionCreations
                class CreationHelper < FormObjects::Base
                    # @return [String]
                    attr_accessor :activity
                    # @return [String]
                    attr_accessor :campaign
                    # @return [String]
                    attr_accessor :cultivable_zone

                    validates :campaign, presence: true
                    validates :activity, presence: true
                    
                    validate do
                        # test if activity exists and add :invalid error
                        if Activity.find_by(id: activity).nil?
                          errors.add(:activity, :invalid)
                        end
                        
                        # test if campaign exists and add :invalid error
                        if Campaign.find_by(id: campaign).nil?
                          errors.add(:campaign, :invalid)
                        end

                        # test if cultivable_zone exists and add :invalid error
                        if cultivable_zone.present? && CultivableZone.find_by(id: cultivable_zone).nil?
                          errors.add(:cultivable_zone, :invalid)
                        end
                    end
                end
            end
        end
    end
end