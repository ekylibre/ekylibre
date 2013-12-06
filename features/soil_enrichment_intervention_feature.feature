Feature: Soil enrichment intervention

  In order to produce some plant derivative product
  As a user
  I want to feed my plant
  
  Background:
  	Given "XXXX" is registred as a plant
  	Given "XXXX" is registred as a cultivable_land_parcel	
  
  Scenario: Collect phytosanitary items
    Given a supplier entitiy exist
    And one or more product_nature_variants exist 
    When I am on incoming_deliveries page
    And I click on new button
    Then I should fill incoming_deliveries form
