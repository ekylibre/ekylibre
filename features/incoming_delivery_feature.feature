Feature: Incoming delivery feature
  In order to produce some products
  As a user
  I want to grab incoming items

  Scenario: Collect phytosanitary items
    Given a supplier entitiy exist
    And one or more product_nature_variants exist 
    When I am on incoming_deliveries page
    And I click on new button
    Then I should fill incoming_deliveries form
