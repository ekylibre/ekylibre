# Change Log

## [2.10.0](https://github.com/ekylibre/ekylibre/tree/2.10.0) (2016-10-04)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.9.0...2.10.0)

## [2.9.0](https://github.com/ekylibre/ekylibre/tree/2.9.0) (2016-09-30)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.8.2...2.9.0)

**Implemented enhancements:**

- Allows conversion of an intervention to a Sale or a Purchase [\#1093](https://github.com/ekylibre/ekylibre/issues/1093)
- Adds preferences to configure default radix for entity [\#1145](https://github.com/ekylibre/ekylibre/pull/1145) ([burisu](https://github.com/burisu))
- Add missing taxes \(fr,es,pt\) and update label in purchase and sale. [\#1144](https://github.com/ekylibre/ekylibre/pull/1144) ([burisu](https://github.com/burisu))
- Product movements rework [\#1128](https://github.com/ekylibre/ekylibre/pull/1128) ([Aquaj](https://github.com/Aquaj))
- Intervention billing [\#1103](https://github.com/ekylibre/ekylibre/pull/1103) ([Aquaj](https://github.com/Aquaj))
- Add stock and inventory accounting [\#1094](https://github.com/ekylibre/ekylibre/pull/1094) ([ionosphere](https://github.com/ionosphere))

**Fixed bugs:**

- Double click on intervention modal change state create other interventions [\#1149](https://github.com/ekylibre/ekylibre/issues/1149)
- ActivityBudget\#activity\_name delegated to activity.name, but activity is nil [\#1148](https://github.com/ekylibre/ekylibre/issues/1148)
- Bug when i click on intervention on kanban board [\#1143](https://github.com/ekylibre/ekylibre/issues/1143)
- Intervention kanban top bar is not correctly displayed when i scroll down the page [\#1141](https://github.com/ekylibre/ekylibre/issues/1141)
- Too much activity labels in intervention details modal [\#1140](https://github.com/ekylibre/ekylibre/issues/1140)
- journal\_entries\#create "comparison of Fixnum with nil failed" [\#1136](https://github.com/ekylibre/ekylibre/issues/1136)

## [2.8.2](https://github.com/ekylibre/ekylibre/tree/2.8.2) (2016-09-29)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.8.1...2.8.2)

## [2.8.1](https://github.com/ekylibre/ekylibre/tree/2.8.1) (2016-09-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.8.0...2.8.1)

**Fixed bugs:**

- PG::AmbiguousColumn: ERREUR:  la référence à la colonne « id » est ambigue [\#1131](https://github.com/ekylibre/ekylibre/issues/1131)
- Intervention show page doesn't work [\#1130](https://github.com/ekylibre/ekylibre/issues/1130)
- Filter on intervention doesn't work for month and year [\#1129](https://github.com/ekylibre/ekylibre/issues/1129)
- French translation of "new intervention" is wrong in matters view [\#1123](https://github.com/ekylibre/ekylibre/issues/1123)
- Bug with the journal\_entries create action [\#1115](https://github.com/ekylibre/ekylibre/issues/1115)
- Products of parcels can be updated after being received [\#882](https://github.com/ekylibre/ekylibre/issues/882)

## [2.8.0](https://github.com/ekylibre/ekylibre/tree/2.8.0) (2016-09-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.7.2...2.8.0)

**Implemented enhancements:**

- Add codes columns to store ID in external systems [\#1126](https://github.com/ekylibre/ekylibre/pull/1126) ([burisu](https://github.com/burisu))
- Procedures normalization [\#1109](https://github.com/ekylibre/ekylibre/pull/1109) ([EmmaDorie](https://github.com/EmmaDorie))
- Improve interventions-activities links performance [\#1099](https://github.com/ekylibre/ekylibre/pull/1099) ([burisu](https://github.com/burisu))
- Create the interventions taskboard system [\#1073](https://github.com/ekylibre/ekylibre/pull/1073) ([igkyab](https://github.com/igkyab))

**Fixed bugs:**

- listings\#mail \(SyntaxError\) [\#1127](https://github.com/ekylibre/ekylibre/issues/1127)
- Actvities are no more by default in map cell [\#1104](https://github.com/ekylibre/ekylibre/issues/1104)
- Procedures normalization [\#1109](https://github.com/ekylibre/ekylibre/pull/1109) ([EmmaDorie](https://github.com/EmmaDorie))

**Closed issues:**

- product\_nature\_variants\#edit "undefined method `any?' for nil:NilClass" [\#1124](https://github.com/ekylibre/ekylibre/issues/1124)

## [2.7.2](https://github.com/ekylibre/ekylibre/tree/2.7.2) (2016-09-27)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.7.1...2.7.2)

**Fixed bugs:**

- parcels\#update \(Ekylibre::Record::RecordNotUpdateable\) "Record cannot be updated" [\#1121](https://github.com/ekylibre/ekylibre/issues/1121)
- Attempted to destroy a stale object: Attachment [\#1120](https://github.com/ekylibre/ekylibre/issues/1120)
- nil can't be coerced into Float on interventions\#compute [\#1119](https://github.com/ekylibre/ekylibre/issues/1119)
- Undefined method 'round' for nil:NilClass on interventions\#compute [\#1118](https://github.com/ekylibre/ekylibre/issues/1118)
- Attempted to update a stale object on purchases list page [\#1117](https://github.com/ekylibre/ekylibre/issues/1117)
- Bug when i click on new button in journal\_entries page [\#1112](https://github.com/ekylibre/ekylibre/issues/1112)
- \[Exception\] interventions\#compute \(FloatDomainError\) "Infinity" [\#1111](https://github.com/ekylibre/ekylibre/issues/1111)
- Error in production / inspection [\#1106](https://github.com/ekylibre/ekylibre/issues/1106)
- Informations are no longer fulfilled automatically at creation of a new inspection [\#988](https://github.com/ekylibre/ekylibre/issues/988)

## [2.7.1](https://github.com/ekylibre/ekylibre/tree/2.7.1) (2016-09-26)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.7.0...2.7.1)

**Fixed bugs:**

- listings\#edit \(ActionView::Template::Error\) "wrong number of arguments \(2 for 0..1\)" [\#1110](https://github.com/ekylibre/ekylibre/issues/1110)
- Error when deleting production [\#1107](https://github.com/ekylibre/ekylibre/issues/1107)

## [2.7.0](https://github.com/ekylibre/ekylibre/tree/2.7.0) (2016-09-20)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.6.1...2.7.0)

**Implemented enhancements:**

- Adds activity filter on backend/equipment\#index [\#1070](https://github.com/ekylibre/ekylibre/issues/1070)
- Adds analytic accountancy [\#1071](https://github.com/ekylibre/ekylibre/pull/1071) ([burisu](https://github.com/burisu))

**Fixed bugs:**

- Parcel invoicing fails due to a not updateable record [\#1102](https://github.com/ekylibre/ekylibre/issues/1102)
- Labellings doesn't work on animal\_group [\#1101](https://github.com/ekylibre/ekylibre/issues/1101)
- When updating an intervention, the quantity population of an actor is not computed. [\#1100](https://github.com/ekylibre/ekylibre/issues/1100)
- View inspections\#show fails when inspections data are not filled [\#1098](https://github.com/ekylibre/ekylibre/issues/1098)

## [2.6.1](https://github.com/ekylibre/ekylibre/tree/2.6.1) (2016-09-19)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.6.0...2.6.1)

**Fixed bugs:**

- Can click on destroy of  product nature category although it's not destroyable [\#1096](https://github.com/ekylibre/ekylibre/issues/1096)
- Impossible to delete sales containing a suscription. [\#1020](https://github.com/ekylibre/ekylibre/issues/1020)

## [2.6.0](https://github.com/ekylibre/ekylibre/tree/2.6.0) (2016-09-19)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.5.3...2.6.0)

**Implemented enhancements:**

- Rename "work" in equipment\_maintenance procedure [\#1050](https://github.com/ekylibre/ekylibre/issues/1050)
- Add a categorization system for equipment [\#1044](https://github.com/ekylibre/ekylibre/issues/1044)
- Add labels for interventions [\#1041](https://github.com/ekylibre/ekylibre/issues/1041)
- Add a label tagging system for cross categorization through all app [\#1040](https://github.com/ekylibre/ekylibre/issues/1040)
- Restore entities export system [\#1095](https://github.com/ekylibre/ekylibre/pull/1095) ([burisu](https://github.com/burisu))
- Add tool maintaining production [\#1091](https://github.com/ekylibre/ekylibre/pull/1091) ([burisu](https://github.com/burisu))
- Adds labelling on interventions and products [\#1082](https://github.com/ekylibre/ekylibre/pull/1082) ([burisu](https://github.com/burisu))
- Record a repair of a component of an equipment without input in an equipment\_maintenance intervention [\#1038](https://github.com/ekylibre/ekylibre/pull/1038) ([burisu](https://github.com/burisu))
- Oauth sign in [\#1002](https://github.com/ekylibre/ekylibre/pull/1002) ([jonathanpa](https://github.com/jonathanpa))

**Fixed bugs:**

- Inspection\#calibration\_values fails when nil values to sum [\#1083](https://github.com/ekylibre/ekylibre/issues/1083)
- Cannot search on postal code or city in backend/entities\#index [\#1053](https://github.com/ekylibre/ekylibre/issues/1053)
- Entity number should be updateable and importable through ekylibre/entities exchanger [\#1027](https://github.com/ekylibre/ekylibre/issues/1027)
- Maintenance activities should permit to link equiment as productions in order to complete targets distribution [\#1022](https://github.com/ekylibre/ekylibre/issues/1022)
- Restore entities export system [\#1095](https://github.com/ekylibre/ekylibre/pull/1095) ([burisu](https://github.com/burisu))
- Add tool maintaining production [\#1091](https://github.com/ekylibre/ekylibre/pull/1091) ([burisu](https://github.com/burisu))

**Merged pull requests:**

- Integration visualization [\#1092](https://github.com/ekylibre/ekylibre/pull/1092) ([Aquaj](https://github.com/Aquaj))

## [2.5.3](https://github.com/ekylibre/ekylibre/tree/2.5.3) (2016-09-10)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.5.2...2.5.3)

## [2.5.2](https://github.com/ekylibre/ekylibre/tree/2.5.2) (2016-09-10)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.5.1...2.5.2)

**Fixed bugs:**

- New bug on Integrations assets due to different conf data between production and development [\#1081](https://github.com/ekylibre/ekylibre/issues/1081)
- display problem in the recording of a parcel [\#1079](https://github.com/ekylibre/ekylibre/issues/1079)

## [2.5.1](https://github.com/ekylibre/ekylibre/tree/2.5.1) (2016-09-10)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.5.0...2.5.1)

**Fixed bugs:**

- Logging fails due to unknown method ip\_address on ActionDispatch::Request [\#1078](https://github.com/ekylibre/ekylibre/issues/1078)
- Cannot go on Integrations index [\#1077](https://github.com/ekylibre/ekylibre/issues/1077)

## [2.5.0](https://github.com/ekylibre/ekylibre/tree/2.5.0) (2016-09-09)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.4.1...2.5.0)

**Implemented enhancements:**

- Display the name of intervention at creation of a new intervention [\#1075](https://github.com/ekylibre/ekylibre/issues/1075)
- Payment cancelation doesn't exist [\#1037](https://github.com/ekylibre/ekylibre/issues/1037)
- Create the Integration system. [\#1032](https://github.com/ekylibre/ekylibre/pull/1032) ([Aquaj](https://github.com/Aquaj))
- Add ActionCaller module to control calls to other API and track all exchanges [\#1007](https://github.com/ekylibre/ekylibre/pull/1007) ([burisu](https://github.com/burisu))

**Fixed bugs:**

- When dates are not touched in intervention form, selectors failed [\#1074](https://github.com/ekylibre/ekylibre/issues/1074)
- Crumbs aren't visible [\#1072](https://github.com/ekylibre/ekylibre/issues/1072)
- Overflow makes scroll on "big" affairs in deals [\#1069](https://github.com/ekylibre/ekylibre/issues/1069)
- Colors of activities changed and are not representative of cultivations [\#1063](https://github.com/ekylibre/ekylibre/issues/1063)
- Child components must have diffrent name [\#1060](https://github.com/ekylibre/ekylibre/issues/1060)
- Duplication of indicator field at creation of a new product\_nature\_variant [\#861](https://github.com/ekylibre/ekylibre/issues/861)

## [2.4.1](https://github.com/ekylibre/ekylibre/tree/2.4.1) (2016-09-07)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.4.0...2.4.1)

**Fixed bugs:**

- Fields of part\_replacement are cleared after adding a new part\_replacement in equipment\_maintenance procedure [\#1054](https://github.com/ekylibre/ekylibre/issues/1054)
- Cannot filter on equipment component after adding a new input for replacement [\#1039](https://github.com/ekylibre/ekylibre/issues/1039)
- Bug when i want to bill a parcel [\#949](https://github.com/ekylibre/ekylibre/issues/949)

**Closed issues:**

- Cannot select a land\_parcel in plant\_covering intervention \(solarization\) [\#1067](https://github.com/ekylibre/ekylibre/issues/1067)

## [2.4.0](https://github.com/ekylibre/ekylibre/tree/2.4.0) (2016-09-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.3.3...2.4.0)

**Implemented enhancements:**

- Send request intervention to zero [\#1049](https://github.com/ekylibre/ekylibre/issues/1049)
- Translation update : "item" in maintenance intervention [\#767](https://github.com/ekylibre/ekylibre/issues/767)
- Completes nomenclatures [\#1065](https://github.com/ekylibre/ekylibre/pull/1065) ([burisu](https://github.com/burisu))
- Extend API to adds interventions\#index action [\#1064](https://github.com/ekylibre/ekylibre/pull/1064) ([burisu](https://github.com/burisu))

## [2.3.3](https://github.com/ekylibre/ekylibre/tree/2.3.3) (2016-09-02)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.3.2...2.3.3)

## [2.3.2](https://github.com/ekylibre/ekylibre/tree/2.3.2) (2016-09-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.3.1...2.3.2)

**Fixed bugs:**

- Production costs with forecast interventions [\#1016](https://github.com/ekylibre/ekylibre/issues/1016)
- Crash if measure grading net mass misses [\#908](https://github.com/ekylibre/ekylibre/issues/908)

## [2.3.1](https://github.com/ekylibre/ekylibre/tree/2.3.1) (2016-08-31)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.3.0...2.3.1)

**Fixed bugs:**

- Cannot display a worker page [\#1059](https://github.com/ekylibre/ekylibre/issues/1059)
- Geolocation input field on equipment edit page doesn't work on Chrome and Vivaldi browsers [\#975](https://github.com/ekylibre/ekylibre/issues/975)
- Printing an intervention sheet provides an empty file [\#907](https://github.com/ekylibre/ekylibre/issues/907)

## [2.3.0](https://github.com/ekylibre/ekylibre/tree/2.3.0) (2016-08-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.2.0...2.3.0)

**Implemented enhancements:**

- add more informations on cultivable zone [\#1024](https://github.com/ekylibre/ekylibre/issues/1024)

**Fixed bugs:**

- Completed bank statement item from a journal entry item in bank statement reconciliation are not taken in account [\#1036](https://github.com/ekylibre/ekylibre/issues/1036)
- Intervention inputs can be filled without given product [\#1035](https://github.com/ekylibre/ekylibre/issues/1035)
- Missing translation : Sales [\#1021](https://github.com/ekylibre/ekylibre/issues/1021)
- Cannot add a equipment\_maintenance directly from interventions\#index [\#1009](https://github.com/ekylibre/ekylibre/issues/1009)
- Surface and perimeter are no longer displayed when the map is not in edition mode [\#954](https://github.com/ekylibre/ekylibre/issues/954)
- Intervention creation form raise error if containing empty working period [\#902](https://github.com/ekylibre/ekylibre/issues/902)
- Error in "new worker" form when you click on "add a new worker" button [\#862](https://github.com/ekylibre/ekylibre/issues/862)
- The date "dead\_at" of land parcels should be filled automatically with the date of the end of the production [\#839](https://github.com/ekylibre/ekylibre/issues/839)
- Fieldset in inspections view gets out of screen when zoomed on in then back out. [\#766](https://github.com/ekylibre/ekylibre/issues/766)
- Piece replacement can be fill without any component [\#765](https://github.com/ekylibre/ekylibre/issues/765)

## [2.2.0](https://github.com/ekylibre/ekylibre/tree/2.2.0) (2016-08-17)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.1.0...2.2.0)

**Implemented enhancements:**

- Add purchase type for staff remuneration [\#1011](https://github.com/ekylibre/ekylibre/issues/1011)
- Error message when clicking too quickly on production dashboard [\#856](https://github.com/ekylibre/ekylibre/issues/856)

**Fixed bugs:**

- Interventions compute fails when derivative-of or variety attribute is set [\#1015](https://github.com/ekylibre/ekylibre/issues/1015)
- Interventions compute action fails on working\_periods [\#1014](https://github.com/ekylibre/ekylibre/issues/1014)
- New product\_nature\_variants without a given nature failed [\#1013](https://github.com/ekylibre/ekylibre/issues/1013)
- Updates Rails to 4.2.7.1 to fix vulnerability CVE-2016-6316 and CVE-2016-6317 [\#1012](https://github.com/ekylibre/ekylibre/issues/1012)

## [2.1.0](https://github.com/ekylibre/ekylibre/tree/2.1.0) (2016-08-17)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.5...2.1.0)

**Implemented enhancements:**

- Adds a slide to introduce new menu in production [\#1005](https://github.com/ekylibre/ekylibre/issues/1005)
- Adds activity\_id attribute in plant\_countings and plant\_density\_abaci API [\#1003](https://github.com/ekylibre/ekylibre/issues/1003)
- Possibility to create land parcel from CAP declaration [\#991](https://github.com/ekylibre/ekylibre/issues/991)
- Improve production Menu [\#978](https://github.com/ekylibre/ekylibre/issues/978)
- Budget could be rounded [\#955](https://github.com/ekylibre/ekylibre/issues/955)
- Sort list by alphabetical order in dropdown "reference name" [\#951](https://github.com/ekylibre/ekylibre/issues/951)
- Redundant information in timeline on Entities. [\#921](https://github.com/ekylibre/ekylibre/issues/921)
- Display duplication on a worker show view [\#887](https://github.com/ekylibre/ekylibre/issues/887)
- Client addresses are not loaded automatically when the client is selected in a sale form [\#846](https://github.com/ekylibre/ekylibre/issues/846)
- Add a way to simplify the cropping plan graph in production dashboard [\#590](https://github.com/ekylibre/ekylibre/issues/590)
- Add activity seasons and tactics [\#857](https://github.com/ekylibre/ekylibre/pull/857) ([burisu](https://github.com/burisu))
- Adds equipment maintenance \(CMMS\) features [\#851](https://github.com/ekylibre/ekylibre/pull/851) ([burisu](https://github.com/burisu))

**Fixed bugs:**

- Reviews productions activity card alignment in \#index [\#1004](https://github.com/ekylibre/ekylibre/issues/1004)
- Worker "dead on" date [\#1001](https://github.com/ekylibre/ekylibre/issues/1001)
- Conflicting translations in indicator names [\#945](https://github.com/ekylibre/ekylibre/issues/945)
- Edition of an inventory keeps us on the form page without confirmation of changes. [\#937](https://github.com/ekylibre/ekylibre/issues/937)
- Redundant information in timeline on Entities. [\#921](https://github.com/ekylibre/ekylibre/issues/921)
- When making a new plant by sowing, no target repartition appears. [\#913](https://github.com/ekylibre/ekylibre/issues/913)
- incoming parcel's dates must be the same. [\#912](https://github.com/ekylibre/ekylibre/issues/912)
- Adding a target distribution on a new product fails [\#901](https://github.com/ekylibre/ekylibre/issues/901)
- Intervention view total cost is calculated from rounded values [\#897](https://github.com/ekylibre/ekylibre/issues/897)
- Currency used in "Draft Journal" is not the absolute one [\#895](https://github.com/ekylibre/ekylibre/issues/895)
- Purchase: convert balance into loss raise a StandardError [\#893](https://github.com/ekylibre/ekylibre/issues/893)
- Display duplication on a worker show view [\#887](https://github.com/ekylibre/ekylibre/issues/887)
- When creating a new matter directly, the product is created and no redirection is made [\#886](https://github.com/ekylibre/ekylibre/issues/886)

**Closed issues:**

- List alphabetical sorting puts \[empty\] before 'A'  [\#918](https://github.com/ekylibre/ekylibre/issues/918)

## [2.0.5](https://github.com/ekylibre/ekylibre/tree/2.0.5) (2016-08-10)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.4...2.0.5)

**Fixed bugs:**

- Error in modification of an activity [\#999](https://github.com/ekylibre/ekylibre/issues/999)

## [2.0.4](https://github.com/ekylibre/ekylibre/tree/2.0.4) (2016-08-10)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.3...2.0.4)

**Implemented enhancements:**

- We don't display the dashboard description [\#940](https://github.com/ekylibre/ekylibre/issues/940)
- French \(FRA\) translations are missing [\#914](https://github.com/ekylibre/ekylibre/issues/914)

**Fixed bugs:**

- Text length limitation at 100000 character is too small for Document [\#995](https://github.com/ekylibre/ekylibre/issues/995)
- Label "required" is missing on the field "net surface area" at creation of a new inspection [\#989](https://github.com/ekylibre/ekylibre/issues/989)
- Crumbs validation is not working [\#986](https://github.com/ekylibre/ekylibre/issues/986)
- Filter on land parcel/cultivation in production/new intervention doesn't work in all cases [\#983](https://github.com/ekylibre/ekylibre/issues/983)
- Remove the button "new" in "Land Parcels" view [\#979](https://github.com/ekylibre/ekylibre/issues/979)
- Cancel button without any effect [\#977](https://github.com/ekylibre/ekylibre/issues/977)
- X-mas tree effect [\#976](https://github.com/ekylibre/ekylibre/issues/976)
- Bug with the validation of empty attachments [\#964](https://github.com/ekylibre/ekylibre/issues/964)
- Duplication of fields possible in Analyses [\#943](https://github.com/ekylibre/ekylibre/issues/943)
- Distribute unaffected products is too long to load. [\#941](https://github.com/ekylibre/ekylibre/issues/941)
- Product update wrongly updates population. [\#934](https://github.com/ekylibre/ekylibre/issues/934)
- Destroyed product appear in outgoing parcels [\#933](https://github.com/ekylibre/ekylibre/issues/933)
- Graphs don't show on switch to new face. [\#927](https://github.com/ekylibre/ekylibre/issues/927)
- Missing validation on Fixed Asset dates. [\#926](https://github.com/ekylibre/ekylibre/issues/926)
- Fixed asset creation fails without error message. [\#925](https://github.com/ekylibre/ekylibre/issues/925)
- AJAX error on date pick in Journal Entry. [\#922](https://github.com/ekylibre/ekylibre/issues/922)
- Entity language incorrect update. [\#920](https://github.com/ekylibre/ekylibre/issues/920)
- French \\(FRA\\) translations are missing [\#914](https://github.com/ekylibre/ekylibre/issues/914)
- Unwanted cycling movements chart [\#898](https://github.com/ekylibre/ekylibre/issues/898)
- plant\_watering intervention fails selecting land\_parcel or plant when empty dates [\#896](https://github.com/ekylibre/ekylibre/issues/896)
- Button "pick" is still available when no item in choice list for product nature variants [\#894](https://github.com/ekylibre/ekylibre/issues/894)
- When adding a new entity\_address through dialog box, the form is full of all field despite chosen canal [\#890](https://github.com/ekylibre/ekylibre/issues/890)
- Adding deal title print "Select for affair %{number}" [\#888](https://github.com/ekylibre/ekylibre/issues/888)

## [2.0.3](https://github.com/ekylibre/ekylibre/tree/2.0.3) (2016-08-04)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.2...2.0.3)

**Implemented enhancements:**

- Outdated favicon  [\#916](https://github.com/ekylibre/ekylibre/issues/916)
- Filter of land parcel doesn't work at creation of new intervention [\#605](https://github.com/ekylibre/ekylibre/issues/605)

**Fixed bugs:**

- No maximum characters in editable zone [\#972](https://github.com/ekylibre/ekylibre/issues/972)
- Numbers too long in edit text zones [\#968](https://github.com/ekylibre/ekylibre/issues/968)
- Bug when i print an inventory [\#947](https://github.com/ekylibre/ekylibre/issues/947)
- Missing translation on "Accountancy dashboard" [\#885](https://github.com/ekylibre/ekylibre/issues/885)

## [2.0.2](https://github.com/ekylibre/ekylibre/tree/2.0.2) (2016-08-02)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.1...2.0.2)

**Implemented enhancements:**

- Parcel number is missing in last incoming parcels cell [\#864](https://github.com/ekylibre/ekylibre/issues/864)
- Reference number is missing on incoming parcel [\#863](https://github.com/ekylibre/ekylibre/issues/863)
- Translation missing for linkage\_points items in product nature form [\#723](https://github.com/ekylibre/ekylibre/issues/723)

**Fixed bugs:**

- backend/crumbs\#index fails due to cobble name repetition [\#874](https://github.com/ekylibre/ekylibre/issues/874)
- Impossible to enter a spraying intervention or fertilization [\#871](https://github.com/ekylibre/ekylibre/issues/871)
- API fails when parameters doesn't match exactly [\#870](https://github.com/ekylibre/ekylibre/issues/870)
- Some fields should be mandatory and a unit symbol is missing in countings form [\#869](https://github.com/ekylibre/ekylibre/issues/869)
- Translation missing in "Listing and Mailing" [\#868](https://github.com/ekylibre/ekylibre/issues/868)
- Deliveries fails on finish action [\#866](https://github.com/ekylibre/ekylibre/issues/866)
- Invalid message sent after inventory reflection action [\#865](https://github.com/ekylibre/ekylibre/issues/865)
- Parcel number is missing in last incoming parcels cell [\#864](https://github.com/ekylibre/ekylibre/issues/864)
- Reference number is missing on incoming parcel [\#863](https://github.com/ekylibre/ekylibre/issues/863)

## [2.0.1](https://github.com/ekylibre/ekylibre/tree/2.0.1) (2016-08-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0...2.0.1)

**Implemented enhancements:**

- Building definition: double area system [\#787](https://github.com/ekylibre/ekylibre/issues/787)
- List build from nomenclatures must be ordered by default in current user langage [\#346](https://github.com/ekylibre/ekylibre/issues/346)

**Fixed bugs:**

- Teaspoon test failure introduced in "I18nize map editor tooltips on production" [\#859](https://github.com/ekylibre/ekylibre/issues/859)
- Add a plant\_density\_abacus doesn't work if the name is already used [\#855](https://github.com/ekylibre/ekylibre/issues/855)
- No error messages when something is wrong in journal\_entry form [\#841](https://github.com/ekylibre/ekylibre/issues/841)
- Map editor tooltips of draw buttons aren't translated on production environment [\#801](https://github.com/ekylibre/ekylibre/issues/801)
- The unroll parameters from form are not considered [\#493](https://github.com/ekylibre/ekylibre/issues/493)

## [2.0.0](https://github.com/ekylibre/ekylibre/tree/2.0.0) (2016-07-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc30...2.0.0)

**Implemented enhancements:**

- Crops list enhancement [\#835](https://github.com/ekylibre/ekylibre/issues/835)
- Parcels selection in deliveries form is too unreadable [\#830](https://github.com/ekylibre/ekylibre/issues/830)
- "Given" state should be named "Received" in incoming parcels [\#828](https://github.com/ekylibre/ekylibre/issues/828)
- In parcels, last state \("Given"\) should be accessed directly when no delivery associated [\#827](https://github.com/ekylibre/ekylibre/issues/827)
- No "-" wanted in nomenclature item's names [\#824](https://github.com/ekylibre/ekylibre/issues/824)
- Need an image for Jerusalem artichoke variety [\#817](https://github.com/ekylibre/ekylibre/issues/817)
- Update the calculation results of inspections in activities view [\#771](https://github.com/ekylibre/ekylibre/issues/771)
- Display the shadow of plants when drawing a sowing intervention [\#768](https://github.com/ekylibre/ekylibre/issues/768)
- Intervention list / Resquest [\#762](https://github.com/ekylibre/ekylibre/issues/762)
- Cropping plan widget feature [\#757](https://github.com/ekylibre/ekylibre/issues/757)
- Building is not displayed when drawing building divisions [\#742](https://github.com/ekylibre/ekylibre/issues/742)
- Enhancement request : diplay stock variant evolution [\#735](https://github.com/ekylibre/ekylibre/issues/735)
- Add the possibility to add an attachement on a production [\#730](https://github.com/ekylibre/ekylibre/issues/730)
- No search bar for Product Category [\#722](https://github.com/ekylibre/ekylibre/issues/722)
- Missing translation in Tools [\#720](https://github.com/ekylibre/ekylibre/issues/720)
- Issue with a matter with a "Work number" while creatind a parcel [\#710](https://github.com/ekylibre/ekylibre/issues/710)
- Enhance intervention destroy [\#706](https://github.com/ekylibre/ekylibre/issues/706)
- Fertirrigation [\#700](https://github.com/ekylibre/ekylibre/issues/700)
- Intervention "facilities modifications" is wrong [\#698](https://github.com/ekylibre/ekylibre/issues/698)
- Translation missing in dashboard module manager [\#695](https://github.com/ekylibre/ekylibre/issues/695)
- Missing translation in Production / Plants [\#681](https://github.com/ekylibre/ekylibre/issues/681)
- Area/perimeter tooltip pointer is not always on good side [\#676](https://github.com/ekylibre/ekylibre/issues/676)
- Traduction error in production dashboard [\#660](https://github.com/ekylibre/ekylibre/issues/660)
- "Documents management" translation [\#658](https://github.com/ekylibre/ekylibre/issues/658)
- Translation "Plan comptable" [\#656](https://github.com/ekylibre/ekylibre/issues/656)
- All crops have yields grain even if they do not produce grain [\#655](https://github.com/ekylibre/ekylibre/issues/655)
- Missing function when creating interventions [\#644](https://github.com/ekylibre/ekylibre/issues/644)
- "Storage" and "sender" required but not labeled as required [\#622](https://github.com/ekylibre/ekylibre/issues/622)
- Sort missing in new products [\#616](https://github.com/ekylibre/ekylibre/issues/616)
- Bad EN translation in Production/Interventions/Harvesting [\#609](https://github.com/ekylibre/ekylibre/issues/609)
- Missing operation in production/operation/harvesting [\#608](https://github.com/ekylibre/ekylibre/issues/608)
- Missing equipment variant : bale loader [\#607](https://github.com/ekylibre/ekylibre/issues/607)
- Add a way to close an activity [\#603](https://github.com/ekylibre/ekylibre/issues/603)
- Update workers exchanger [\#601](https://github.com/ekylibre/ekylibre/issues/601)
- Sowing interventions needs doers [\#598](https://github.com/ekylibre/ekylibre/issues/598)
- Cannot manage easily supplier in purchase form [\#594](https://github.com/ekylibre/ekylibre/issues/594)
- "Initial owner" in workers form [\#593](https://github.com/ekylibre/ekylibre/issues/593)
- French translation of tool is wrong in the superficial plowing intervention [\#591](https://github.com/ekylibre/ekylibre/issues/591)
- Translation error Production / Analyses [\#589](https://github.com/ekylibre/ekylibre/issues/589)
- Add production systems [\#583](https://github.com/ekylibre/ekylibre/issues/583)
- Help message on maps is unreadable [\#579](https://github.com/ekylibre/ekylibre/issues/579)
- Improve the display of informations in campaigns dashboard [\#578](https://github.com/ekylibre/ekylibre/issues/578)
- Add filters to sort matters [\#576](https://github.com/ekylibre/ekylibre/issues/576)
- Add a column with the name of the company attached to the pacage number [\#573](https://github.com/ekylibre/ekylibre/issues/573)
- Fertilizing with liquid nitrogen [\#565](https://github.com/ekylibre/ekylibre/issues/565)
- Display of net surface area is too precise in cap statement dashboard [\#562](https://github.com/ekylibre/ekylibre/issues/562)
- Question : what is "initial owner" in new worker form ? [\#556](https://github.com/ekylibre/ekylibre/issues/556)
- Langage error when creating new worker [\#555](https://github.com/ekylibre/ekylibre/issues/555)
- No capacity for spayer [\#544](https://github.com/ekylibre/ekylibre/issues/544)
- Creation of an accounting account : usage is open-nomenclature name [\#534](https://github.com/ekylibre/ekylibre/issues/534)
- Precipitation indicator isn't displayed [\#533](https://github.com/ekylibre/ekylibre/issues/533)
- Add additive type variants to spraying intervention [\#526](https://github.com/ekylibre/ekylibre/issues/526)
- Add i18n to leaflet measure plugin [\#492](https://github.com/ekylibre/ekylibre/issues/492)
- Entity transactions graph should include current month [\#484](https://github.com/ekylibre/ekylibre/issues/484)
- Badges should be more readable [\#480](https://github.com/ekylibre/ekylibre/issues/480)
- Fullscreen dashboards should match between browsers [\#479](https://github.com/ekylibre/ekylibre/issues/479)
- Land parcels index map should take full height [\#462](https://github.com/ekylibre/ekylibre/issues/462)
- Missing toolbar allowing printing on exports [\#460](https://github.com/ekylibre/ekylibre/issues/460)
- Leaflet draw tools are not translated [\#434](https://github.com/ekylibre/ekylibre/issues/434)
- Rename associated\_account to associate\_account in Cash [\#418](https://github.com/ekylibre/ekylibre/issues/418)
- Removes state\_label methods in models [\#361](https://github.com/ekylibre/ekylibre/issues/361)
- Legend Control should be reduce-able \(and reduced by default\) [\#284](https://github.com/ekylibre/ekylibre/issues/284)
- Add some field products [\#263](https://github.com/ekylibre/ekylibre/issues/263)
- Filter intervention type [\#253](https://github.com/ekylibre/ekylibre/issues/253)
- Add an option for setting a default zoom level in visualization component [\#157](https://github.com/ekylibre/ekylibre/issues/157)
- Add a default value indicator management for parcels [\#125](https://github.com/ekylibre/ekylibre/issues/125)
- Adds missing email in CODE\_OF\_CONDUCT [\#829](https://github.com/ekylibre/ekylibre/pull/829) ([kakahuete](https://github.com/kakahuete))
- Ofx import and bank statement auto reconciliate \(rebased\) [\#798](https://github.com/ekylibre/ekylibre/pull/798) ([lcoq](https://github.com/lcoq))
- Simplifies delivery/parcel system [\#775](https://github.com/ekylibre/ekylibre/pull/775) ([burisu](https://github.com/burisu))
- Bank reconciliation [\#697](https://github.com/ekylibre/ekylibre/pull/697) ([lcoq](https://github.com/lcoq))
- Simplify and re-renable subscriptions [\#640](https://github.com/ekylibre/ekylibre/pull/640) ([burisu](https://github.com/burisu))
- Adds surface and perimeter measures when drawing on maps [\#639](https://github.com/ekylibre/ekylibre/pull/639) ([burisu](https://github.com/burisu))
- Add grading tool to estimate "in ground" stocks [\#628](https://github.com/ekylibre/ekylibre/pull/628) ([burisu](https://github.com/burisu))
- Add map backgrounds management [\#625](https://github.com/ekylibre/ekylibre/pull/625) ([burisu](https://github.com/burisu))

**Fixed bugs:**

- Translations missing on state machine steps of sales, purchases sale\_opportunities [\#837](https://github.com/ekylibre/ekylibre/issues/837)
- Routing error in backend/events\#index view [\#836](https://github.com/ekylibre/ekylibre/issues/836)
- Migration to fill number in existing inventories is needed [\#834](https://github.com/ekylibre/ekylibre/issues/834)
- Adding "Work number" for an equipment in "Building divisions" doesn't work [\#833](https://github.com/ekylibre/ekylibre/issues/833)
- Unit in outgoing parcel items are always "\#" [\#832](https://github.com/ekylibre/ekylibre/issues/832)
- Inventory print doesn't work [\#831](https://github.com/ekylibre/ekylibre/issues/831)
- Parcels selection in deliveries form is too unreadable [\#830](https://github.com/ekylibre/ekylibre/issues/830)
- "Given" state should be named "Received" in incoming parcels [\#828](https://github.com/ekylibre/ekylibre/issues/828)
- In parcels, last state \\("Given"\\) should be accessed directly when no delivery associated [\#827](https://github.com/ekylibre/ekylibre/issues/827)
- Plant density abacus must belongs to activity [\#826](https://github.com/ekylibre/ekylibre/issues/826)
- Activity production chronology period doesn't match [\#825](https://github.com/ekylibre/ekylibre/issues/825)
- No "-" wanted in nomenclature item's names [\#824](https://github.com/ekylibre/ekylibre/issues/824)
- Product reading read\_at doesn't match with product born at  [\#823](https://github.com/ekylibre/ekylibre/issues/823)
- Crops dead date seems not work [\#821](https://github.com/ekylibre/ekylibre/issues/821)
- The field "mettre en place" is incomprehensible in harvesting intervention [\#820](https://github.com/ekylibre/ekylibre/issues/820)
- Issue on productions still persist when a quantity is in "unity" in the budget [\#819](https://github.com/ekylibre/ekylibre/issues/819)
- We get an error when trying to print an intervention [\#818](https://github.com/ekylibre/ekylibre/issues/818)
- Impossible to create a new entity [\#816](https://github.com/ekylibre/ekylibre/issues/816)
- Problem of unity in hervest intervention [\#815](https://github.com/ekylibre/ekylibre/issues/815)
- Shape of land parcels doesn't take into account the intervention's date [\#814](https://github.com/ekylibre/ekylibre/issues/814)
- Calendar cell fails in production while looking for a route [\#813](https://github.com/ekylibre/ekylibre/issues/813)
- Yield estimation fails when budget is not given in matching dimension [\#812](https://github.com/ekylibre/ekylibre/issues/812)
- Impossible to open an activity\_production [\#811](https://github.com/ekylibre/ekylibre/issues/811)
- Edit a land parcel doesn't work [\#810](https://github.com/ekylibre/ekylibre/issues/810)
- At creation of a new future production land parcels are empty [\#809](https://github.com/ekylibre/ekylibre/issues/809)
- backend/journal\_entries\#create fails [\#808](https://github.com/ekylibre/ekylibre/issues/808)
- Intervention "facilities modifications" don't work [\#807](https://github.com/ekylibre/ekylibre/issues/807)
- Country in backend/entities form is always set to default country [\#805](https://github.com/ekylibre/ekylibre/issues/805)
- Export of aggregator land\_parcel\_register fails [\#804](https://github.com/ekylibre/ekylibre/issues/804)
- Export of aggregator activity\_cost fails [\#803](https://github.com/ekylibre/ekylibre/issues/803)
- Listings fails when want to extract only a custom field column [\#802](https://github.com/ekylibre/ekylibre/issues/802)
- Intervention working periods aren't reflected on intervention parameter dropdowns [\#799](https://github.com/ekylibre/ekylibre/issues/799)
- Listings can export custom fields  [\#797](https://github.com/ekylibre/ekylibre/issues/797)
- Error when right clic on the button "map" to open in a new tab [\#795](https://github.com/ekylibre/ekylibre/issues/795)
- Update net surface area of a polygon when a point is removed [\#794](https://github.com/ekylibre/ekylibre/issues/794)
- Products from new parcel don't appear in inventory [\#793](https://github.com/ekylibre/ekylibre/issues/793)
- Seeding price calculation error [\#792](https://github.com/ekylibre/ekylibre/issues/792)
- Error on activity show [\#790](https://github.com/ekylibre/ekylibre/issues/790)
- Impossible to change a parcel from the status "in preparation" to the status "prepared" [\#789](https://github.com/ekylibre/ekylibre/issues/789)
- Update the form of inspection creation [\#782](https://github.com/ekylibre/ekylibre/issues/782)
- Last intervention widget [\#781](https://github.com/ekylibre/ekylibre/issues/781)
- Stewardship label errors [\#780](https://github.com/ekylibre/ekylibre/issues/780)
- Attachments aren't removed on an edit form [\#778](https://github.com/ekylibre/ekylibre/issues/778)
- Attachments aren't protected against concurrent editing [\#777](https://github.com/ekylibre/ekylibre/issues/777)
- Plant density abaci is not finished [\#776](https://github.com/ekylibre/ekylibre/issues/776)
- Some computation failed during entry creation in journal [\#773](https://github.com/ekylibre/ekylibre/issues/773)
- We should not be able to distribute targets on activity\_productions when there is nothing to distribute [\#772](https://github.com/ekylibre/ekylibre/issues/772)
- Update the calculation results of inspections in activities view [\#771](https://github.com/ekylibre/ekylibre/issues/771)
- Unpredictable sorting behavior in views because some columns are 'sortable' when they shouldn't be. [\#769](https://github.com/ekylibre/ekylibre/issues/769)
- Invalid tool in soil loosening intervention [\#764](https://github.com/ekylibre/ekylibre/issues/764)
- ProductMovements don't reflect an updated stock mouvement [\#761](https://github.com/ekylibre/ekylibre/issues/761)
- Subsoiling : crop target is not available [\#760](https://github.com/ekylibre/ekylibre/issues/760)
- Error on display of map at creation of a new intervention [\#759](https://github.com/ekylibre/ekylibre/issues/759)
- Unchecked indicator's field is still visible in variant product [\#754](https://github.com/ekylibre/ekylibre/issues/754)
- Update the container of an equipement is impossible [\#751](https://github.com/ekylibre/ekylibre/issues/751)
- Bad timing on matter tracking \(stocks\) [\#749](https://github.com/ekylibre/ekylibre/issues/749)
- Fertilization : crop target is not available [\#748](https://github.com/ekylibre/ekylibre/issues/748)
- Building is not displayed when drawing building divisions [\#742](https://github.com/ekylibre/ekylibre/issues/742)
- Mousewheel map zoom on production dashboard [\#740](https://github.com/ekylibre/ekylibre/issues/740)
- List view of settlements doesn't work [\#739](https://github.com/ekylibre/ekylibre/issues/739)
- Add an annotation on product variant when adding a new purchase fails [\#731](https://github.com/ekylibre/ekylibre/issues/731)
- Repayments dates of yearly-paid loans are still monthly [\#728](https://github.com/ekylibre/ekylibre/issues/728)
- No way to add multiple journal entry items manually [\#727](https://github.com/ekylibre/ekylibre/issues/727)
- Auto-numeration of product natures doesn't work [\#724](https://github.com/ekylibre/ekylibre/issues/724)
- At creation of a new intervention, actions are marked "required" even if they're not [\#718](https://github.com/ekylibre/ekylibre/issues/718)
- First-run : Arable Area - loading files [\#715](https://github.com/ekylibre/ekylibre/issues/715)
- Plants : Water concentration // Bad translation [\#713](https://github.com/ekylibre/ekylibre/issues/713)
- Issue with a matter with a "Work number" while creatind a parcel [\#710](https://github.com/ekylibre/ekylibre/issues/710)
- On cultivable zones, when we toggle between map and list views, map backgrounds disappear [\#708](https://github.com/ekylibre/ekylibre/issues/708)
- After a supplier removal, related purchases become "invisible" [\#705](https://github.com/ekylibre/ekylibre/issues/705)
- Creating a new fixed asset starting before first financial year raises an exception [\#704](https://github.com/ekylibre/ekylibre/issues/704)
- purchases\#create \(NoMethodError\) "undefined method `zero?' for nil:NilClass" [\#703](https://github.com/ekylibre/ekylibre/issues/703)
- Cannot find water variety [\#702](https://github.com/ekylibre/ekylibre/issues/702)
- Fertirrigation [\#700](https://github.com/ekylibre/ekylibre/issues/700)
- Missing translation of minutes in matter show view [\#699](https://github.com/ekylibre/ekylibre/issues/699)
- Intervention "facilities modifications" is wrong [\#698](https://github.com/ekylibre/ekylibre/issues/698)
- VAT count round error [\#696](https://github.com/ekylibre/ekylibre/issues/696)
- Inventory problem [\#691](https://github.com/ekylibre/ekylibre/issues/691)
- Missing attachment on analysis form [\#687](https://github.com/ekylibre/ekylibre/issues/687)
- Intervention : state = undone ? [\#686](https://github.com/ekylibre/ekylibre/issues/686)
- Action backend/activities\#family fails with tool\_maintaining activty parameter [\#685](https://github.com/ekylibre/ekylibre/issues/685)
- Perennial campaign bug [\#684](https://github.com/ekylibre/ekylibre/issues/684)
- rc21 purchase error [\#683](https://github.com/ekylibre/ekylibre/issues/683)
- Campaign budget and intervention costs [\#682](https://github.com/ekylibre/ekylibre/issues/682)
- unpaid's sales and purchases are badly computes in trade cell. [\#680](https://github.com/ekylibre/ekylibre/issues/680)
- Phytosanitary register export fails on intersection computation [\#679](https://github.com/ekylibre/ekylibre/issues/679)
- When deleting a point during a polygon drawing, area and perimeter are not refreshed in tooltip [\#677](https://github.com/ekylibre/ekylibre/issues/677)
- Area/perimeter tooltip pointer is not always on good side [\#676](https://github.com/ekylibre/ekylibre/issues/676)
- Map intercepts RETURN key event to show file import but it's not expected [\#675](https://github.com/ekylibre/ekylibre/issues/675)
- "Mechanical harvesting" traduction [\#674](https://github.com/ekylibre/ekylibre/issues/674)
- No need of geometry label in map\_editor for classical forms [\#672](https://github.com/ekylibre/ekylibre/issues/672)
- Area/perimeter tooltip can be under the cursor and disturbs user [\#671](https://github.com/ekylibre/ekylibre/issues/671)
- Varieties aren't filtered during typing on first run activities step [\#670](https://github.com/ekylibre/ekylibre/issues/670)
- When many categories used in one visualization, geometry clustering is made but unwanted [\#669](https://github.com/ekylibre/ekylibre/issues/669)
- Impossible to draw new building [\#668](https://github.com/ekylibre/ekylibre/issues/668)
- During intervention, the shape is missing when selecting a target [\#667](https://github.com/ekylibre/ekylibre/issues/667)
- Travis-CI seems to dislike Teaspoon driver [\#665](https://github.com/ekylibre/ekylibre/issues/665)
- Unit not showing when adding new ParcelItem - Parcel creation [\#664](https://github.com/ekylibre/ekylibre/issues/664)
- User can choose unactivated map background by default [\#663](https://github.com/ekylibre/ekylibre/issues/663)
- No currency symbol return in sale or purchase report [\#662](https://github.com/ekylibre/ekylibre/issues/662)
- Map error on new issue page [\#661](https://github.com/ekylibre/ekylibre/issues/661)
- In productions, chain deletions doesn't work [\#659](https://github.com/ekylibre/ekylibre/issues/659)
- Display and edit the number of a product nature [\#657](https://github.com/ekylibre/ekylibre/issues/657)
- Map backgrounds not loaded during migration [\#653](https://github.com/ekylibre/ekylibre/issues/653)
- Impossible to record new intervention [\#652](https://github.com/ekylibre/ekylibre/issues/652)
- rc16 Map Background not working [\#649](https://github.com/ekylibre/ekylibre/issues/649)
- Intervention problem with Windrower [\#648](https://github.com/ekylibre/ekylibre/issues/648)
- Analyses map missing background selector [\#642](https://github.com/ekylibre/ekylibre/issues/642)
- Crash on export Interventions [\#641](https://github.com/ekylibre/ekylibre/issues/641)
- Missing error message when deleting Land Parcel [\#637](https://github.com/ekylibre/ekylibre/issues/637)
- Button "New" in Production Plants [\#636](https://github.com/ekylibre/ekylibre/issues/636)
- Edit a journal entry removes its items bank statement [\#635](https://github.com/ekylibre/ekylibre/issues/635)
- Wrong journal entry items currency in bank statement point [\#634](https://github.com/ekylibre/ekylibre/issues/634)
- Wrong bank account balance currency [\#633](https://github.com/ekylibre/ekylibre/issues/633)
- Auto-completion on doesn't work on entity mail address line\_6 [\#630](https://github.com/ekylibre/ekylibre/issues/630)
- Maps seems to fail when no map backgrounds loaded [\#629](https://github.com/ekylibre/ekylibre/issues/629)
- Some catalog items make backend/interventions\#show fail [\#626](https://github.com/ekylibre/ekylibre/issues/626)
- Search in the field "Storage" in parcel [\#623](https://github.com/ekylibre/ekylibre/issues/623)
- Duplication of the field "work number" in the form "edit equipment" [\#620](https://github.com/ekylibre/ekylibre/issues/620)
- Add a new contact at creation of a new workers doesn't work [\#617](https://github.com/ekylibre/ekylibre/issues/617)
- backend/trial\_balances fails with specific parameters [\#614](https://github.com/ekylibre/ekylibre/issues/614)
- Bug with sum\_working\_zone\_areas on all\_in\_one\_sowing intervention recording [\#613](https://github.com/ekylibre/ekylibre/issues/613)
- Merge third and organization [\#611](https://github.com/ekylibre/ekylibre/issues/611)
- Missing translations in English for some configuration parameters [\#604](https://github.com/ekylibre/ekylibre/issues/604)
- Stock after intervention deletion [\#592](https://github.com/ekylibre/ekylibre/issues/592)
- Translation error Production / Analyses [\#589](https://github.com/ekylibre/ekylibre/issues/589)
- Button "New" is missing in product nature variants [\#587](https://github.com/ekylibre/ekylibre/issues/587)
- Local search bar in backend/product is not made on name [\#586](https://github.com/ekylibre/ekylibre/issues/586)
- Missing french translation of linkage\_points [\#585](https://github.com/ekylibre/ekylibre/issues/585)
- Crumbs import doesn't work [\#575](https://github.com/ekylibre/ekylibre/issues/575)
- Search Product types [\#574](https://github.com/ekylibre/ekylibre/issues/574)
- Storage areas doesn't appear [\#572](https://github.com/ekylibre/ekylibre/issues/572)
- Add an attachment to entities fails [\#571](https://github.com/ekylibre/ekylibre/issues/571)
- Multiplication of cultivable zones when create activities from telepac [\#570](https://github.com/ekylibre/ekylibre/issues/570)
- French translations are missing for pictograms [\#568](https://github.com/ekylibre/ekylibre/issues/568)
- Quantity of plant in matters [\#566](https://github.com/ekylibre/ekylibre/issues/566)
- Delete a product in a parcel [\#563](https://github.com/ekylibre/ekylibre/issues/563)
- French translations or text are missing on mouse over the cartography buttons [\#561](https://github.com/ekylibre/ekylibre/issues/561)
- French translation of "required" is missing in all forms [\#559](https://github.com/ekylibre/ekylibre/issues/559)
- Matters doesn't appear [\#551](https://github.com/ekylibre/ekylibre/issues/551)
- Remove an intervention fails [\#550](https://github.com/ekylibre/ekylibre/issues/550)
-  Save a new sowing intervention fails [\#549](https://github.com/ekylibre/ekylibre/issues/549)
- Creation of a default land parcel LP00 [\#548](https://github.com/ekylibre/ekylibre/issues/548)
- Missing french translation in cultivable\_zones [\#547](https://github.com/ekylibre/ekylibre/issues/547)
- Map control button error [\#546](https://github.com/ekylibre/ekylibre/issues/546)
- "variety" label for equipment is not adapted in english [\#541](https://github.com/ekylibre/ekylibre/issues/541)
- Container in new product tab [\#540](https://github.com/ekylibre/ekylibre/issues/540)
- Translation in add equipement tab [\#538](https://github.com/ekylibre/ekylibre/issues/538)
- Translation : category of worker [\#537](https://github.com/ekylibre/ekylibre/issues/537)
- Tax display in invoice entry [\#535](https://github.com/ekylibre/ekylibre/issues/535)
- No document templates for delivery docket works [\#532](https://github.com/ekylibre/ekylibre/issues/532)
- List of transporters is not displayed when creating a new delivery [\#530](https://github.com/ekylibre/ekylibre/issues/530)
- Error of calculation in the age of matter [\#529](https://github.com/ekylibre/ekylibre/issues/529)
- List of interventions doesn't appear in backend/activity\_productions\#show view [\#528](https://github.com/ekylibre/ekylibre/issues/528)
- sensor data aren't automatically recorded [\#527](https://github.com/ekylibre/ekylibre/issues/527)
- Cannot add a new equipment\_item\_replacement intervention [\#524](https://github.com/ekylibre/ekylibre/issues/524)
- Add an attachment to incoming payments [\#523](https://github.com/ekylibre/ekylibre/issues/523)
- View backend/custom\_fields\#show fails [\#521](https://github.com/ekylibre/ekylibre/issues/521)
- Loan creation fails when currencies in loan and journals are different [\#520](https://github.com/ekylibre/ekylibre/issues/520)
- Invalid file import fails in backend\#map\_editors controller [\#519](https://github.com/ekylibre/ekylibre/issues/519)
- Save a new sowing intervention fails [\#518](https://github.com/ekylibre/ekylibre/issues/518)
- ActivityBudgets seems to fails on invalid items [\#517](https://github.com/ekylibre/ekylibre/issues/517)
- JasperReports doesn't compile jasper without raising error at this moment [\#516](https://github.com/ekylibre/ekylibre/issues/516)
- Calendar cell fails on relationship dashboard [\#515](https://github.com/ekylibre/ekylibre/issues/515)
- New matter don't appear in the inventory [\#514](https://github.com/ekylibre/ekylibre/issues/514)
- Error when trying to access to analyses form with sensor\_analysis nature in url  [\#512](https://github.com/ekylibre/ekylibre/issues/512)
- The worker list isn't displayed [\#511](https://github.com/ekylibre/ekylibre/issues/511)
- Error when adding an animal farming production with a blank size\_value [\#510](https://github.com/ekylibre/ekylibre/issues/510)
- Missing translations and balance in budget view [\#508](https://github.com/ekylibre/ekylibre/issues/508)
- How to see a movement after updating a parcel [\#506](https://github.com/ekylibre/ekylibre/issues/506)
- Error message are not humanized [\#505](https://github.com/ekylibre/ekylibre/issues/505)
- ISTEA doesn't import entries properly [\#504](https://github.com/ekylibre/ekylibre/issues/504)
- No way to add an activity production [\#503](https://github.com/ekylibre/ekylibre/issues/503)
- Error when trying to add a product through modal [\#502](https://github.com/ekylibre/ekylibre/issues/502)
- Error on retrieving dates for perennial productions [\#501](https://github.com/ekylibre/ekylibre/issues/501)
- Enter an incident on a parcel [\#500](https://github.com/ekylibre/ekylibre/issues/500)
- display problem when creating a product [\#499](https://github.com/ekylibre/ekylibre/issues/499)
- Can't create a new activity [\#497](https://github.com/ekylibre/ekylibre/issues/497)
- When click on import button nothing shown by default in map editors [\#496](https://github.com/ekylibre/ekylibre/issues/496)
- Error when trying to update activity\_production [\#494](https://github.com/ekylibre/ekylibre/issues/494)
- Bad message are send to report when no downpayment are present [\#491](https://github.com/ekylibre/ekylibre/issues/491)
- undefined method `attachments\_backend\_cultivable\_zone\_path' when accessing to a cultivable\_zone [\#490](https://github.com/ekylibre/ekylibre/issues/490)
- An error occurred in last\_incoming\_parcels\_cells\#show [\#489](https://github.com/ekylibre/ekylibre/issues/489)
- Tax are not loaded during first\_run [\#488](https://github.com/ekylibre/ekylibre/issues/488)
- Data lost when changing cultivable areas [\#487](https://github.com/ekylibre/ekylibre/issues/487)
- Cannot display attachments, popup is empty [\#485](https://github.com/ekylibre/ekylibre/issues/485)
- Entity transactions graph should include current month [\#484](https://github.com/ekylibre/ekylibre/issues/484)
- Empty cells are not wanted anymore in dashboards [\#475](https://github.com/ekylibre/ekylibre/issues/475)
- Fullscreen map on chromium [\#461](https://github.com/ekylibre/ekylibre/issues/461)
- Leaflet draw tools are not translated [\#434](https://github.com/ekylibre/ekylibre/issues/434)
- Removes state\\_label methods in models [\#361](https://github.com/ekylibre/ekylibre/issues/361)
- Pasteque v5 API tests don't work [\#339](https://github.com/ekylibre/ekylibre/issues/339)
- Cannot perform home\_coming \(\[driver\] moves in default storage\) when driver has no default storage in intervention run [\#330](https://github.com/ekylibre/ekylibre/issues/330)
- Simplifies delivery/parcel system [\#775](https://github.com/ekylibre/ekylibre/pull/775) ([burisu](https://github.com/burisu))
- Simplify and re-renable subscriptions [\#640](https://github.com/ekylibre/ekylibre/pull/640) ([burisu](https://github.com/burisu))

**Closed issues:**

- Qestion : lot management in stock. [\#750](https://github.com/ekylibre/ekylibre/issues/750)
- Equipment: "undefined container" in Inventory [\#746](https://github.com/ekylibre/ekylibre/issues/746)
- Save some interventions fail [\#719](https://github.com/ekylibre/ekylibre/issues/719)
- First-run : map enhanchment [\#717](https://github.com/ekylibre/ekylibre/issues/717)
- Intervention list is missing in activities [\#714](https://github.com/ekylibre/ekylibre/issues/714)
- Plants map default loaded layers [\#712](https://github.com/ekylibre/ekylibre/issues/712)
- Translation problem : "plants" [\#709](https://github.com/ekylibre/ekylibre/issues/709)
- ERROR MESSAGE - Cannot add "Doer" in intervention [\#647](https://github.com/ekylibre/ekylibre/issues/647)
- Bug importing workers [\#627](https://github.com/ekylibre/ekylibre/issues/627)
- Labels in Sowing intervention [\#599](https://github.com/ekylibre/ekylibre/issues/599)
- Bad label "land parcel" [\#596](https://github.com/ekylibre/ekylibre/issues/596)
- French translation "Rhodes Grass" [\#595](https://github.com/ekylibre/ekylibre/issues/595)
- French translation is missing for population\_counting [\#569](https://github.com/ekylibre/ekylibre/issues/569)
- User language is not used after login [\#553](https://github.com/ekylibre/ekylibre/issues/553)
- Translation problem "planting" [\#543](https://github.com/ekylibre/ekylibre/issues/543)
- Word usage in worker [\#539](https://github.com/ekylibre/ekylibre/issues/539)
- Entry number with decimal in parcels \(comma, not point\) [\#536](https://github.com/ekylibre/ekylibre/issues/536)
- Since interventions have many targets, the visualization show only one. [\#507](https://github.com/ekylibre/ekylibre/issues/507)
- Error when trying to navigate between campaigns with selector on card view  [\#495](https://github.com/ekylibre/ekylibre/issues/495)
- Attachments on product form [\#455](https://github.com/ekylibre/ekylibre/issues/455)
- i18n - Translation for portuguese [\#411](https://github.com/ekylibre/ekylibre/issues/411)
- Legend masks menu on dashboard maps [\#251](https://github.com/ekylibre/ekylibre/issues/251)

## [2.0.0.rc30](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc30) (2016-07-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc29...2.0.0.rc30)

## [2.0.0.rc29](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc29) (2016-07-22)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc28...2.0.0.rc29)

## [2.0.0.rc28](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc28) (2016-07-20)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc27...2.0.0.rc28)

## [2.0.0.rc27](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc27) (2016-07-12)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc26...2.0.0.rc27)

## [2.0.0.rc26](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc26) (2016-07-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc25...2.0.0.rc26)

## [2.0.0.rc25](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc25) (2016-07-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc24...2.0.0.rc25)

## [2.0.0.rc24](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc24) (2016-06-15)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc23...2.0.0.rc24)

## [2.0.0.rc23](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc23) (2016-06-05)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc22...2.0.0.rc23)

## [2.0.0.rc22](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc22) (2016-05-30)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc21...2.0.0.rc22)

## [2.0.0.rc21](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc21) (2016-05-27)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc20...2.0.0.rc21)

## [2.0.0.rc20](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc20) (2016-05-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc19...2.0.0.rc20)

## [2.0.0.rc19](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc19) (2016-05-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc18...2.0.0.rc19)

## [2.0.0.rc18](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc18) (2016-05-24)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc17...2.0.0.rc18)

## [2.0.0.rc17](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc17) (2016-05-24)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc16...2.0.0.rc17)

## [2.0.0.rc16](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc16) (2016-05-18)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc15...2.0.0.rc16)

## [2.0.0.rc15](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc15) (2016-05-17)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc14...2.0.0.rc15)

## [2.0.0.rc14](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc14) (2016-05-16)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc13...2.0.0.rc14)

## [2.0.0.rc13](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc13) (2016-05-10)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc12...2.0.0.rc13)

**Merged pull requests:**

- User sign up confirmed by admin [\#554](https://github.com/ekylibre/ekylibre/pull/554) ([jonathanpa](https://github.com/jonathanpa))

## [2.0.0.rc12](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc12) (2016-04-26)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc11...2.0.0.rc12)

## [2.0.0.rc11](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc11) (2016-04-18)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc10...2.0.0.rc11)

## [2.0.0.rc10](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc10) (2016-04-02)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc9...2.0.0.rc10)

**Merged pull requests:**

- User invitation [\#509](https://github.com/ekylibre/ekylibre/pull/509) ([jonathanpa](https://github.com/jonathanpa))

## [2.0.0.rc9](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc9) (2016-03-24)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc8...2.0.0.rc9)

## [2.0.0.rc8](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc8) (2016-03-22)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc7...2.0.0.rc8)

## [2.0.0.rc7](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc7) (2016-03-16)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc6...2.0.0.rc7)

## [2.0.0.rc6](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc6) (2016-03-15)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc5...2.0.0.rc6)

**Merged pull requests:**

- Add a Gitter chat badge to README.md [\#498](https://github.com/ekylibre/ekylibre/pull/498) ([gitter-badger](https://github.com/gitter-badger))

## [2.0.0.rc5](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc5) (2016-03-14)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc4...2.0.0.rc5)

## [2.0.0.rc4](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc4) (2016-02-26)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc3...2.0.0.rc4)

## [2.0.0.rc3](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc3) (2016-02-15)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc2...2.0.0.rc3)

## [2.0.0.rc2](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc2) (2016-02-13)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.rc1...2.0.0.rc2)

## [2.0.0.rc1](https://github.com/ekylibre/ekylibre/tree/2.0.0.rc1) (2016-02-11)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta8...2.0.0.rc1)

## [2.0.0.beta8](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta8) (2016-02-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta7...2.0.0.beta8)

## [2.0.0.beta7](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta7) (2016-01-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.4...2.0.0.beta7)

## [1.3.4](https://github.com/ekylibre/ekylibre/tree/1.3.4) (2016-01-19)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.3...1.3.4)

## [1.3.3](https://github.com/ekylibre/ekylibre/tree/1.3.3) (2016-01-18)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta6...1.3.3)

## [2.0.0.beta6](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta6) (2016-01-13)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta5...2.0.0.beta6)

## [2.0.0.beta5](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta5) (2016-01-13)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta4...2.0.0.beta5)

## [2.0.0.beta4](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta4) (2016-01-13)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta3...2.0.0.beta4)

## [2.0.0.beta3](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta3) (2016-01-12)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta2...2.0.0.beta3)

## [2.0.0.beta2](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta2) (2016-01-12)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/2.0.0.beta1...2.0.0.beta2)

## [2.0.0.beta1](https://github.com/ekylibre/ekylibre/tree/2.0.0.beta1) (2016-01-11)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.2...2.0.0.beta1)

## [1.3.2](https://github.com/ekylibre/ekylibre/tree/1.3.2) (2015-11-24)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.1...1.3.2)

## [1.3.1](https://github.com/ekylibre/ekylibre/tree/1.3.1) (2015-11-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.0...1.3.1)

**Implemented enhancements:**

- Cannot perform work\_number input during equipment creation [\#465](https://github.com/ekylibre/ekylibre/issues/465)
- Display pretty errors on form [\#453](https://github.com/ekylibre/ekylibre/issues/453)
- How to upload a \(prescription\) file and link it to an intervention [\#300](https://github.com/ekylibre/ekylibre/issues/300)
- Improve first\_run on interventions import [\#245](https://github.com/ekylibre/ekylibre/issues/245)

**Fixed bugs:**

- Tax price / quantity in invoice purchases [\#483](https://github.com/ekylibre/ekylibre/issues/483)
- Removes attachments field set in field sets [\#482](https://github.com/ekylibre/ekylibre/issues/482)
- Round on sales is not enough precise in the interface [\#481](https://github.com/ekylibre/ekylibre/issues/481)
- Parcel to sale/purchase conversion fails on empty item population [\#478](https://github.com/ekylibre/ekylibre/issues/478)
- ExpensesByProductNatureCategory cell displays nothing without any message [\#477](https://github.com/ekylibre/ekylibre/issues/477)
- A NoMethodError occurred in bank\_statements\#point [\#476](https://github.com/ekylibre/ekylibre/issues/476)
- Beehive updates fails because of use of backend form system [\#474](https://github.com/ekylibre/ekylibre/issues/474)
- Fails badly in matters\#index when destroying product with parcel\_items [\#473](https://github.com/ekylibre/ekylibre/issues/473)
- StaleObjectError occurs on Preference\#save [\#472](https://github.com/ekylibre/ekylibre/issues/472)
- Crumbs\#index fails on working\_sets expression [\#471](https://github.com/ekylibre/ekylibre/issues/471)
- Fails badly when RSS feed can't be opened by Faraday [\#470](https://github.com/ekylibre/ekylibre/issues/470)
- Interventions register fails due to ProductionSupport\#vine\_yield method [\#469](https://github.com/ekylibre/ekylibre/issues/469)
- LWGEOMCOLLECTION operation error while adding an intervention [\#468](https://github.com/ekylibre/ekylibre/issues/468)
- Error on adding a rss cell on dashboard [\#467](https://github.com/ekylibre/ekylibre/issues/467)
- Missing constant GoogleVisualr Error in placeholder cells [\#466](https://github.com/ekylibre/ekylibre/issues/466)
- Error creation of purchase with attached document [\#464](https://github.com/ekylibre/ekylibre/issues/464)
- In stock / delivery of parcels, the list doesn't filter on transporters only [\#463](https://github.com/ekylibre/ekylibre/issues/463)
- Missing french translation on production form [\#459](https://github.com/ekylibre/ekylibre/issues/459)
- Dates on intervention form [\#457](https://github.com/ekylibre/ekylibre/issues/457)
- When calling a variant selector in procedure, we 've got list of product [\#451](https://github.com/ekylibre/ekylibre/issues/451)
- How to call a method which call a nomenclature in a plugin when the plugin is not here [\#450](https://github.com/ekylibre/ekylibre/issues/450)
- No way too delete crumbs [\#447](https://github.com/ekylibre/ekylibre/issues/447)

## [1.3.0](https://github.com/ekylibre/ekylibre/tree/1.3.0) (2015-10-20)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.0.rc1...1.3.0)

**Implemented enhancements:**

- When creating a new legal person, the form should ask for a "name" instead of a "last name" [\#172](https://github.com/ekylibre/ekylibre/issues/172)
- Localize currency number in invoices [\#164](https://github.com/ekylibre/ekylibre/issues/164)

**Fixed bugs:**

- Error on performing animal treatment [\#458](https://github.com/ekylibre/ekylibre/issues/458)
- Internal error on a new sowing intervention [\#456](https://github.com/ekylibre/ekylibre/issues/456)
- Error on adding a new cultivable zone shape [\#454](https://github.com/ekylibre/ekylibre/issues/454)
- Print income statement [\#449](https://github.com/ekylibre/ekylibre/issues/449)
- undefined method `human\_name' for nil:NilClass in land parcel list [\#448](https://github.com/ekylibre/ekylibre/issues/448)
- Unknown leaflet-custom.scss [\#446](https://github.com/ekylibre/ekylibre/issues/446)
- mistake on purchase item [\#443](https://github.com/ekylibre/ekylibre/issues/443)
- A SystemStackError occurred in interventions\#compute [\#388](https://github.com/ekylibre/ekylibre/issues/388)

## [1.3.0.rc1](https://github.com/ekylibre/ekylibre/tree/1.3.0.rc1) (2015-09-29)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.0.beta3...1.3.0.rc1)

## [1.3.0.beta3](https://github.com/ekylibre/ekylibre/tree/1.3.0.beta3) (2015-09-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.0.beta2...1.3.0.beta3)

## [1.3.0.beta2](https://github.com/ekylibre/ekylibre/tree/1.3.0.beta2) (2015-09-17)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.3.0.beta1...1.3.0.beta2)

**Merged pull requests:**

- New portuguese translations to newly added terms [\#442](https://github.com/ekylibre/ekylibre/pull/442) ([danimaribeiro](https://github.com/danimaribeiro))

## [1.3.0.beta1](https://github.com/ekylibre/ekylibre/tree/1.3.0.beta1) (2015-07-14)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.1...1.3.0.beta1)

## [1.2.1](https://github.com/ekylibre/ekylibre/tree/1.2.1) (2015-07-08)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.4...1.2.1)

**Fixed bugs:**

- When we change page on ActiveList in a dashboard cell, content doesn't follow [\#441](https://github.com/ekylibre/ekylibre/issues/441)
- Undefined method `self\_and\_children' for nil occured when try to run synchronization of Unicoque data [\#440](https://github.com/ekylibre/ekylibre/issues/440)
- When many animals are selected and dragged to another place, the dragging widget is too wide [\#439](https://github.com/ekylibre/ekylibre/issues/439)
- Internal error on intervention recorder when animals are dropped [\#438](https://github.com/ekylibre/ekylibre/issues/438)
- When a transfer fails in animal interface \(golumn\), the form seems frozen [\#437](https://github.com/ekylibre/ekylibre/issues/437)
- When an animal is dragged alone in an existing container, it doesn't appears in popup form [\#436](https://github.com/ekylibre/ekylibre/issues/436)
- An error occurred on animal variant intervention [\#432](https://github.com/ekylibre/ekylibre/issues/432)

## [0.3.4](https://github.com/ekylibre/ekylibre/tree/0.3.4) (2015-06-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0...0.3.4)

## [1.2.0](https://github.com/ekylibre/ekylibre/tree/1.2.0) (2015-06-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.rc1...1.2.0)

**Implemented enhancements:**

- Buttons in cobbles are not aligned [\#425](https://github.com/ekylibre/ekylibre/issues/425)
- Rename FinancialAsset to FixedAsset [\#408](https://github.com/ekylibre/ekylibre/issues/408)
- Fix orthograph error on Intervention\#ressource, only one "s" is better [\#259](https://github.com/ekylibre/ekylibre/issues/259)
- Improve use of redirect [\#250](https://github.com/ekylibre/ekylibre/issues/250)
- Print screen could be seperated vertically and doc presented inline if possible [\#195](https://github.com/ekylibre/ekylibre/issues/195)
- Converts Nomen::Item translation pattern from Nomen::MyItems\[foobar\].human\_name to Nomen::MyItems.human\_name\(foobar\) [\#180](https://github.com/ekylibre/ekylibre/issues/180)
- Externalize General ledger, Balance and Draft journal to specific controllers  [\#169](https://github.com/ekylibre/ekylibre/issues/169)
- Add paper\_trail by default in all models [\#82](https://github.com/ekylibre/ekylibre/issues/82)
- Add tools to manage picture with paperclip in form [\#81](https://github.com/ekylibre/ekylibre/issues/81)
- Add a column in Price to track amounts variations [\#28](https://github.com/ekylibre/ekylibre/issues/28)

**Fixed bugs:**

- Cannot re-print sale estimate after first print, it always returns first archive [\#435](https://github.com/ekylibre/ekylibre/issues/435)
- Crumbs cannot be displayed [\#433](https://github.com/ekylibre/ekylibre/issues/433)
- An error occurred on animal moving intervention [\#431](https://github.com/ekylibre/ekylibre/issues/431)
- Error in backend/gaps\#edit view [\#430](https://github.com/ekylibre/ekylibre/issues/430)
- Purchase show view fails with missing entity\_id column error [\#429](https://github.com/ekylibre/ekylibre/issues/429)
- Cannot save purchase/sale with blank items [\#428](https://github.com/ekylibre/ekylibre/issues/428)
- Manual computation method in purchases produced error [\#427](https://github.com/ekylibre/ekylibre/issues/427)
- No way to duplicate sale [\#424](https://github.com/ekylibre/ekylibre/issues/424)
- reporting of a sale\_credit is blank [\#423](https://github.com/ekylibre/ekylibre/issues/423)
- Remove the "add product" during intervention recording [\#422](https://github.com/ekylibre/ekylibre/issues/422)
- No way to load account\_chart [\#421](https://github.com/ekylibre/ekylibre/issues/421)
- The price is not set automaticaly by the variant catalog price [\#420](https://github.com/ekylibre/ekylibre/issues/420)
- 'ic' CSS class conflict with ActiveList unique column classes [\#419](https://github.com/ekylibre/ekylibre/issues/419)
- ActionView::Template::Error campaigns / campaign link to Janus [\#417](https://github.com/ekylibre/ekylibre/issues/417)
- No route matches \[GET\] "/backend/map" when accessing to map then list [\#416](https://github.com/ekylibre/ekylibre/issues/416)
- When no opened productions, no family are used to group them [\#415](https://github.com/ekylibre/ekylibre/issues/415)
- Open production from activities fails because of empty campaign [\#414](https://github.com/ekylibre/ekylibre/issues/414)
- icon are not in place in intervention show view [\#412](https://github.com/ekylibre/ekylibre/issues/412)
- Sale cancellation produces differents numbers [\#410](https://github.com/ekylibre/ekylibre/issues/410)
- HTTPS error on \#details action in \(sales|purchases\)/\_item\_fields.html.haml in production mode [\#409](https://github.com/ekylibre/ekylibre/issues/409)
- 1 cent error on total appears in purchase [\#407](https://github.com/ekylibre/ekylibre/issues/407)
- purchase\_item\_id are not set in DB where creating a purchase from incoming delivery [\#406](https://github.com/ekylibre/ekylibre/issues/406)
- Ensures that model name translation are uniques per locale [\#405](https://github.com/ekylibre/ekylibre/issues/405)
- Blank type column are not taken in account in Listing [\#404](https://github.com/ekylibre/ekylibre/issues/404)
- vat\_taxe\_registry is an invalid name [\#347](https://github.com/ekylibre/ekylibre/issues/347)
- Add a way to insert analyses items on an analysis [\#309](https://github.com/ekylibre/ekylibre/issues/309)
- Translation of yaml reserved words [\#266](https://github.com/ekylibre/ekylibre/issues/266)
- Fix orthograph error on Intervention\\#ressource, only one "s" is better [\#259](https://github.com/ekylibre/ekylibre/issues/259)

**Closed issues:**

- How to know the rate of a tax during sale ? [\#391](https://github.com/ekylibre/ekylibre/issues/391)

## [1.2.0.rc1](https://github.com/ekylibre/ekylibre/tree/1.2.0.rc1) (2015-06-17)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta9...1.2.0.rc1)

## [1.2.0.beta9](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta9) (2015-06-07)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta8...1.2.0.beta9)

## [1.2.0.beta8](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta8) (2015-05-31)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta7...1.2.0.beta8)

## [1.2.0.beta7](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta7) (2015-05-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta6...1.2.0.beta7)

**Merged pull requests:**

- Portuguese translation for files access, formats and support. [\#413](https://github.com/ekylibre/ekylibre/pull/413) ([danimaribeiro](https://github.com/danimaribeiro))

## [1.2.0.beta6](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta6) (2015-05-18)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta5...1.2.0.beta6)

## [1.2.0.beta5](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta5) (2015-05-04)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta4...1.2.0.beta5)

## [1.2.0.beta4](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta4) (2015-04-29)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta3...1.2.0.beta4)

## [1.2.0.beta3](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta3) (2015-04-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta2...1.2.0.beta3)

## [1.2.0.beta2](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta2) (2015-04-22)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.2.0.beta1...1.2.0.beta2)

## [1.2.0.beta1](https://github.com/ekylibre/ekylibre/tree/1.2.0.beta1) (2015-04-13)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.1.3...1.2.0.beta1)

## [1.1.3](https://github.com/ekylibre/ekylibre/tree/1.1.3) (2015-04-03)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.1.2...1.1.3)

**Fixed bugs:**

- Redirection fails after deposit creation [\#403](https://github.com/ekylibre/ekylibre/issues/403)
- Cannot update cashes without country [\#402](https://github.com/ekylibre/ekylibre/issues/402)
- When supports are hidden in production form, the working unit dependent budget are set to 0 [\#401](https://github.com/ekylibre/ekylibre/issues/401)
- Account marking doesn't work automatically like before [\#400](https://github.com/ekylibre/ekylibre/issues/400)
- Search fails when SaleItem/PurchaseItem are found [\#399](https://github.com/ekylibre/ekylibre/issues/399)
- Last\_interventions\_cells returns 404 on some interventions [\#398](https://github.com/ekylibre/ekylibre/issues/398)

## [1.1.2](https://github.com/ekylibre/ekylibre/tree/1.1.2) (2015-03-31)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.1.1...1.1.2)

**Fixed bugs:**

- No way to add an incoming delivery item [\#397](https://github.com/ekylibre/ekylibre/issues/397)
- IE seems to be incompatible with AJAX requests [\#396](https://github.com/ekylibre/ekylibre/issues/396)
- A NameError occurred in synchronizations\#run [\#395](https://github.com/ekylibre/ekylibre/issues/395)
- An ActionView::Template::Error occurred in inventories\#new: [\#394](https://github.com/ekylibre/ekylibre/issues/394)
- A 500 error raised when all cells are removed on beehive [\#393](https://github.com/ekylibre/ekylibre/issues/393)
- negative argument in first\_run when instance name is too long [\#392](https://github.com/ekylibre/ekylibre/issues/392)
- An ActiveRecord::StaleObjectError occurred in beehives\#update [\#390](https://github.com/ekylibre/ekylibre/issues/390)

## [1.1.1](https://github.com/ekylibre/ekylibre/tree/1.1.1) (2015-03-26)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.4.4...1.1.1)

**Fixed bugs:**

- An ActionView::Template::Error occurred in plants\#show [\#389](https://github.com/ekylibre/ekylibre/issues/389)
- An ActionController::ParameterMissing occurred in building\_divisions\#update: [\#387](https://github.com/ekylibre/ekylibre/issues/387)
- A NameError occurred in plants [\#385](https://github.com/ekylibre/ekylibre/issues/385)
- An ActionView::Template::Error occurred in crumbs [\#384](https://github.com/ekylibre/ekylibre/issues/384)
- An ActionController::UrlGenerationError occurred in matters [\#383](https://github.com/ekylibre/ekylibre/issues/383)
- An ActionController::UrlGenerationError occurred in matters [\#382](https://github.com/ekylibre/ekylibre/issues/382)
- An ActionController::UrlGenerationError occurred in matters [\#381](https://github.com/ekylibre/ekylibre/issues/381)
- An ActionView::Template::Error occurred in crumbs [\#380](https://github.com/ekylibre/ekylibre/issues/380)
- An ActionView::Template::Error occurred in map\_cells [\#379](https://github.com/ekylibre/ekylibre/issues/379)
- A JSON::ParserError occurred in weather\_cells [\#378](https://github.com/ekylibre/ekylibre/issues/378)
- invalid byte sequence in UTF-8 during first run georeadings import [\#377](https://github.com/ekylibre/ekylibre/issues/377)
- Need to check if entity exist before creating it during first\_run [\#371](https://github.com/ekylibre/ekylibre/issues/371)
- PG::InternalError: Relate Operation called with a LWGEOMCOLLECTION type in crumbs\#index [\#293](https://github.com/ekylibre/ekylibre/issues/293)

## [0.4.4](https://github.com/ekylibre/ekylibre/tree/0.4.4) (2015-03-26)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.3...0.4.4)

**Implemented enhancements:**

- Need a db/tables.yml to manage backup import in Ekylibre ≥  1 versions [\#386](https://github.com/ekylibre/ekylibre/issues/386)

**Fixed bugs:**

- Need a db/tables.yml to manage backup import in Ekylibre ≥  1 versions [\#386](https://github.com/ekylibre/ekylibre/issues/386)

**Closed issues:**

- Error when calling "Bilan Comptable" document\_templates/1/print.pdf [\#35](https://github.com/ekylibre/ekylibre/issues/35)

## [0.3.3](https://github.com/ekylibre/ekylibre/tree/0.3.3) (2015-03-26)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.1.0...0.3.3)

**Fixed bugs:**

- After a new payment creation in incoming\_payment\_use creation, "Conflict" error raises sometimes [\#204](https://github.com/ekylibre/ekylibre/issues/204)
- Entity links don't seem to work perfectly on 0.3.2.4 [\#116](https://github.com/ekylibre/ekylibre/issues/116)

## [1.1.0](https://github.com/ekylibre/ekylibre/tree/1.1.0) (2015-03-23)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.1.0.rc2...1.1.0)

**Implemented enhancements:**

- Adds a "seed" manager for newly created companies [\#29](https://github.com/ekylibre/ekylibre/issues/29)

**Fixed bugs:**

- Pasturing interventions are present anymore in \(provisional\_\)manure\_management\_plan aggregators [\#376](https://github.com/ekylibre/ekylibre/issues/376)
- ActivityCost document template raises "java.lang.IllegalArgumentException: Null 'key' argument" [\#375](https://github.com/ekylibre/ekylibre/issues/375)
- Missing interpolation of variety and soil\_nature in MMP report [\#374](https://github.com/ekylibre/ekylibre/issues/374)
- General ledger must be order by date [\#373](https://github.com/ekylibre/ekylibre/issues/373)
- Error when updating animal budget with  [\#370](https://github.com/ekylibre/ekylibre/issues/370)
- Activity are not correctly created from budget ods import [\#369](https://github.com/ekylibre/ekylibre/issues/369)
- The cash balances in accountancy dashboards are wrong [\#368](https://github.com/ekylibre/ekylibre/issues/368)
- Weather cell use a too long timeout on HTTP request [\#367](https://github.com/ekylibre/ekylibre/issues/367)
- No way to add an intervention from production\_support list [\#366](https://github.com/ekylibre/ekylibre/issues/366)
- Calendar cell next/previous buttons doesn't works [\#365](https://github.com/ekylibre/ekylibre/issues/365)
- Shape is not set by creating a new intervention from a Zone support [\#364](https://github.com/ekylibre/ekylibre/issues/364)
- Remove AnalyticDistribution model which is useless [\#363](https://github.com/ekylibre/ekylibre/issues/363)
- Unique violation in DMS with a sale [\#362](https://github.com/ekylibre/ekylibre/issues/362)
- Cannot export LandParcelRegistry due to ProductionSupport\#grains\_yield return [\#360](https://github.com/ekylibre/ekylibre/issues/360)
- Fail gracefully when file is not found for a document [\#359](https://github.com/ekylibre/ekylibre/issues/359)
- Undefined method `factory' for \#\<Charta\> [\#358](https://github.com/ekylibre/ekylibre/issues/358)
- Notifications after redirect doesn't work [\#357](https://github.com/ekylibre/ekylibre/issues/357)
- Balances are not computed in JournalEntryItem [\#355](https://github.com/ekylibre/ekylibre/issues/355)
- Can't update budget [\#354](https://github.com/ekylibre/ekylibre/issues/354)
- Access error on archive consultation due to migration runner \(root\) [\#353](https://github.com/ekylibre/ekylibre/issues/353)
- InterventionRegistry export doesn't work [\#352](https://github.com/ekylibre/ekylibre/issues/352)
- View people\#show doesn't work \(ActionView::Template::Error\) "Local type cannot be: cash\_balances. Already taken." [\#351](https://github.com/ekylibre/ekylibre/issues/351)
- Timeline don't work with models without controllers like product\_ownerships [\#350](https://github.com/ekylibre/ekylibre/issues/350)
- Cannot add georeading through the interface [\#345](https://github.com/ekylibre/ekylibre/issues/345)
- Unable to complete import from zip file \(1,9 Mo\) [\#344](https://github.com/ekylibre/ekylibre/issues/344)
- No way to add an extraction on purchase line [\#341](https://github.com/ekylibre/ekylibre/issues/341)
- No way to search by account code in general ledger \(malformed format string - %' \) [\#340](https://github.com/ekylibre/ekylibre/issues/340)
- No way to import purchases original file on production [\#338](https://github.com/ekylibre/ekylibre/issues/338)
- Module buttons on main dashboards don't follows rights restrictions [\#337](https://github.com/ekylibre/ekylibre/issues/337)
- Implement inheritance like products but for entity [\#336](https://github.com/ekylibre/ekylibre/issues/336)
-  undefined method `name' for nil:NilClass on backend/cells/map\_cell [\#335](https://github.com/ekylibre/ekylibre/issues/335)
- undefined method `full\_name' for nil:NilClass in backend/cells/calendar\_cell [\#334](https://github.com/ekylibre/ekylibre/issues/334)
- Purchase report is wrong concerning taxe and unit [\#333](https://github.com/ekylibre/ekylibre/issues/333)
- When missing owner during new incoming delivery, the show view of the concerning product is buggy [\#332](https://github.com/ekylibre/ekylibre/issues/332)
- Unable to export general\_ledger in CSV Excel [\#331](https://github.com/ekylibre/ekylibre/issues/331)
-  NoMethodError in Backend::OutgoingPayments\#show [\#319](https://github.com/ekylibre/ekylibre/issues/319)
- The date component in kujaku doesn't propose parameter in URL [\#315](https://github.com/ekylibre/ekylibre/issues/315)
- Fix some ajax stuff in accountancy form [\#314](https://github.com/ekylibre/ekylibre/issues/314)
- Cannot horizontal scroll on Large list  [\#296](https://github.com/ekylibre/ekylibre/issues/296)
- Fix phytosanitary registry [\#283](https://github.com/ekylibre/ekylibre/issues/283)
- Animal state should reflect incident state [\#262](https://github.com/ekylibre/ekylibre/issues/262)
- Custom fields should appear in \#show view [\#246](https://github.com/ekylibre/ekylibre/issues/246)
- PDF should not be served and stay in memory [\#163](https://github.com/ekylibre/ekylibre/issues/163)
- Fixes block displaying in form [\#91](https://github.com/ekylibre/ekylibre/issues/91)

**Closed issues:**

- Finish to rename Ekylibre to Ekylibre::ERP in code [\#247](https://github.com/ekylibre/ekylibre/issues/247)
- Removes totally libxml which is being replaced by Nokogiri [\#110](https://github.com/ekylibre/ekylibre/issues/110)
- Change sales invoice management to add flexibility on updates until not accounted [\#5](https://github.com/ekylibre/ekylibre/issues/5)

## [1.1.0.rc2](https://github.com/ekylibre/ekylibre/tree/1.1.0.rc2) (2015-03-11)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.1.0.rc1...1.1.0.rc2)

## [1.1.0.rc1](https://github.com/ekylibre/ekylibre/tree/1.1.0.rc1) (2015-03-08)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0...1.1.0.rc1)

**Merged pull requests:**

- Add libicu dependency for packaging [\#348](https://github.com/ekylibre/ekylibre/pull/348) ([crohr](https://github.com/crohr))

## [1.0.0](https://github.com/ekylibre/ekylibre/tree/1.0.0) (2015-01-11)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc29...1.0.0)

**Implemented enhancements:**

- How to make a sale or a purchase invoice for yesterday [\#294](https://github.com/ekylibre/ekylibre/issues/294)
- Add tests for all exports [\#224](https://github.com/ekylibre/ekylibre/issues/224)
- Test 2 Issue on Github [\#140](https://github.com/ekylibre/ekylibre/issues/140)
- Add a method to manage variety between product and product\_nature [\#119](https://github.com/ekylibre/ekylibre/issues/119)
- Reorganize preferences to store all credentials and work ID [\#114](https://github.com/ekylibre/ekylibre/issues/114)
- Convert lib/ekylibre/models.rb to db/graph.yml [\#105](https://github.com/ekylibre/ekylibre/issues/105)
- Refactor core to use all bioproducts together \(operations, events...\) [\#104](https://github.com/ekylibre/ekylibre/issues/104)
- Normalize bank infos of BBAN in Cash [\#101](https://github.com/ekylibre/ekylibre/issues/101)
- Remove use of errors.add\_to\_base [\#100](https://github.com/ekylibre/ekylibre/issues/100)
- Use reflection in unroll labels [\#93](https://github.com/ekylibre/ekylibre/issues/93)
- Replace use of \*\_rate columns where \_percent is more logical [\#86](https://github.com/ekylibre/ekylibre/issues/86)
- Harmonize use of reduction and discount through the application [\#85](https://github.com/ekylibre/ekylibre/issues/85)
- Generalize custom\_fields to all models [\#83](https://github.com/ekylibre/ekylibre/issues/83)
- Themes must be gathered in one place [\#79](https://github.com/ekylibre/ekylibre/issues/79)
- Add tools for Geocoding & Maps [\#75](https://github.com/ekylibre/ekylibre/issues/75)
- Enhance the system menu to work with the new version of Ekylibre [\#72](https://github.com/ekylibre/ekylibre/issues/72)
- Enhance tools and operations management [\#71](https://github.com/ekylibre/ekylibre/issues/71)
- Add an husbandry module to manage animals [\#70](https://github.com/ekylibre/ekylibre/issues/70)
- Add possibilities to draw and decorate the view [\#69](https://github.com/ekylibre/ekylibre/issues/69)
- Adds a way to define global quantity OR density quantity for inputs/outputs in land parcels operations [\#43](https://github.com/ekylibre/ekylibre/issues/43)
- Add a legal types for entities [\#36](https://github.com/ekylibre/ekylibre/issues/36)
- Manage different units of the same product \(use, sale, purchase, stock\) [\#30](https://github.com/ekylibre/ekylibre/issues/30)
- Make estimates transferable from one client to another [\#26](https://github.com/ekylibre/ekylibre/issues/26)
- Add photo management for entities with PaperClip [\#19](https://github.com/ekylibre/ekylibre/issues/19)

**Fixed bugs:**

- Some procedures are not well classified [\#329](https://github.com/ekylibre/ekylibre/issues/329)
- When making an outgoing delivery, the owner must change [\#328](https://github.com/ekylibre/ekylibre/issues/328)
- Cannot access postal zones [\#327](https://github.com/ekylibre/ekylibre/issues/327)
- How to delete an event ? [\#326](https://github.com/ekylibre/ekylibre/issues/326)
- Confusion in nitrogen\_concentration visualization [\#325](https://github.com/ekylibre/ekylibre/issues/325)
- Bug in PPF when adding a new campaign - undefined method `actor' [\#324](https://github.com/ekylibre/ekylibre/issues/324)
- Outgoing payments bookeeping doesn't seem to work [\#323](https://github.com/ekylibre/ekylibre/issues/323)
- Need to know host to build valid QRcode in aggregators [\#322](https://github.com/ekylibre/ekylibre/issues/322)
- undefined method `coordinate' for nil:NilClass [\#321](https://github.com/ekylibre/ekylibre/issues/321)
- pretax\_amount and amont present the same value [\#320](https://github.com/ekylibre/ekylibre/issues/320)
- pretax\_amount and amont pressent the same value [\#318](https://github.com/ekylibre/ekylibre/issues/318)
- Default corporate\_styles.xml must be accessible from private directory to prevent links errors with JasperReports compiler [\#317](https://github.com/ekylibre/ekylibre/issues/317)
- Active list through reflexion are not managed like others [\#316](https://github.com/ekylibre/ekylibre/issues/316)
- Some field of unroll in intervention are not translated as expected [\#308](https://github.com/ekylibre/ekylibre/issues/308)
- Fail gracefully when trying to ship without transporter [\#307](https://github.com/ekylibre/ekylibre/issues/307)
- Fail gracefully when not configured in outgoing\_payments\#create [\#306](https://github.com/ekylibre/ekylibre/issues/306)
- Error : Unknown nature\(s\) for a DocumentTemplate for each export [\#303](https://github.com/ekylibre/ekylibre/issues/303)
- ManureManagementPlan templates raise a Java exception on invalid number \(without more information\) [\#302](https://github.com/ekylibre/ekylibre/issues/302)
-  PG::InvalidRegularExpression on production\_supports\#unroll [\#301](https://github.com/ekylibre/ekylibre/issues/301)
- Test & Fix: Cannot create observation from person\#show [\#299](https://github.com/ekylibre/ekylibre/issues/299)
- All amounts in "My information" stays at 0  [\#298](https://github.com/ekylibre/ekylibre/issues/298)
- Cannot print various exports [\#297](https://github.com/ekylibre/ekylibre/issues/297)
- Fail gracefully when argument out of range on interventions\#create [\#295](https://github.com/ekylibre/ekylibre/issues/295)
- Test & fix: undefined method `variety' on productions\#show [\#292](https://github.com/ekylibre/ekylibre/issues/292)
- Test & fix: undefined method `\>=' for nil:NilClass on matters\#show [\#291](https://github.com/ekylibre/ekylibre/issues/291)
- Test & fix: undefined method `round' for nil:NilClass" on interventions\#show [\#290](https://github.com/ekylibre/ekylibre/issues/290)
- Test & fix: deadlock & attempt to update a stable object on  incoming\_payment\_modes\#reflect  [\#289](https://github.com/ekylibre/ekylibre/issues/289)
- Purchase\_items\#update raise undefined method `model\_name' for NilClass:Class [\#287](https://github.com/ekylibre/ekylibre/issues/287)
- Test & Fix undefined method `l' in catalog\_prices\#create [\#286](https://github.com/ekylibre/ekylibre/issues/286)
- Nomenclature translation not displayed [\#285](https://github.com/ekylibre/ekylibre/issues/285)
- Cannot use backend/cash\_transfers [\#282](https://github.com/ekylibre/ekylibre/issues/282)
- Double record creation on price catalog creation [\#281](https://github.com/ekylibre/ekylibre/issues/281)
- Multi-currency management in production [\#280](https://github.com/ekylibre/ekylibre/issues/280)
- Redirected to nonexistent action \(observations\#index\) after observation destruction [\#279](https://github.com/ekylibre/ekylibre/issues/279)
- All included prices is twice charged [\#278](https://github.com/ekylibre/ekylibre/issues/278)
- Undefined method `meat\_withdrawal\_period',  `name' and `container' on exports [\#276](https://github.com/ekylibre/ekylibre/issues/276)
- Test & Fix undefined local variable or method 'connection' on manure\_management\_plans\#show and custom\_fields\#new [\#275](https://github.com/ekylibre/ekylibre/issues/275)
- Test & Fix undefined method `\>=' in production\_supports\#show [\#273](https://github.com/ekylibre/ekylibre/issues/273)
- Test & Fix a segv when displaying a production [\#272](https://github.com/ekylibre/ekylibre/issues/272)
- Test & fix undefined local variable or method 'connection' in animals\#edit and animals\#new [\#271](https://github.com/ekylibre/ekylibre/issues/271)
- When adding a PNG picture on an entity, the picture is badly cropped [\#270](https://github.com/ekylibre/ekylibre/issues/270)
- Exception on JournalEntry creation when no existing FinancialYear [\#269](https://github.com/ekylibre/ekylibre/issues/269)
- Search engine redirect on nonexistent pages [\#267](https://github.com/ekylibre/ekylibre/issues/267)
- Fail gracefully when user enters wrong date. [\#258](https://github.com/ekylibre/ekylibre/issues/258)
- Cannot save help display status in preference [\#257](https://github.com/ekylibre/ekylibre/issues/257)
- Cannot display a plant [\#256](https://github.com/ekylibre/ekylibre/issues/256)
- Various exceptions on import\#run [\#255](https://github.com/ekylibre/ekylibre/issues/255)
- When showing or editing identifiers, net services names should be displayed [\#249](https://github.com/ekylibre/ekylibre/issues/249)
- When creating an analytic distribution, selector for journal entry item doesn't work [\#248](https://github.com/ekylibre/ekylibre/issues/248)
- Empty FeatureCollection make Charta::Geometry fails [\#243](https://github.com/ekylibre/ekylibre/issues/243)
- InterventionsController\#compute always raise exception [\#241](https://github.com/ekylibre/ekylibre/issues/241)
- Normalizes synchronizations tool [\#240](https://github.com/ekylibre/ekylibre/issues/240)
- Roles must be usable from users form [\#239](https://github.com/ekylibre/ekylibre/issues/239)
- Update resource nomenclature and rights.yml [\#237](https://github.com/ekylibre/ekylibre/issues/237)
- Add missing translations for sequences [\#236](https://github.com/ekylibre/ekylibre/issues/236)
- Translations for CustomField errors are invalid [\#235](https://github.com/ekylibre/ekylibre/issues/235)
- Import of bad file in EBP EDI fails with Exception [\#234](https://github.com/ekylibre/ekylibre/issues/234)
- Integration tests doesn't seem to work on Travis [\#233](https://github.com/ekylibre/ekylibre/issues/233)
- RuntimeError on backend/outgoing\_deliveries\#ship [\#232](https://github.com/ekylibre/ekylibre/issues/232)
- Module:DelegationError on backend/outgoing\_deliveries\#create [\#231](https://github.com/ekylibre/ekylibre/issues/231)
- When adding items to a sale, the selector should show only saleable items [\#230](https://github.com/ekylibre/ekylibre/issues/230)
- se2014 don't first\_run anymore [\#229](https://github.com/ekylibre/ekylibre/issues/229)
- The production support is not set from clicking on cultivable zone map [\#228](https://github.com/ekylibre/ekylibre/issues/228)
- Test & fix intervention deletion [\#227](https://github.com/ekylibre/ekylibre/issues/227)
- Unable to remove a useless price [\#226](https://github.com/ekylibre/ekylibre/issues/226)
- Unable to use the SalesController\#propose\_and\_invoice action [\#225](https://github.com/ekylibre/ekylibre/issues/225)
- BankStatement\#previous/next methods don't work because of use of Datetime [\#223](https://github.com/ekylibre/ekylibre/issues/223)
- Bank statement debit/credit are not refreshed after pointing [\#221](https://github.com/ekylibre/ekylibre/issues/221)
- Empty campaign\_id makes backend/productions\#index fail [\#220](https://github.com/ekylibre/ekylibre/issues/220)
- Undefined method `name' for issue [\#219](https://github.com/ekylibre/ekylibre/issues/219)
- ODS export fails on active lists in production mode [\#218](https://github.com/ekylibre/ekylibre/issues/218)
- Segv when database is empty [\#217](https://github.com/ekylibre/ekylibre/issues/217)
- JasperReport should not try to write file at application root [\#216](https://github.com/ekylibre/ekylibre/issues/216)
- Segv on dashboards\#search [\#215](https://github.com/ekylibre/ekylibre/issues/215)
- Undefined column planned\_at for backend/entities\#unroll [\#214](https://github.com/ekylibre/ekylibre/issues/214)
- Segv on purchase\#update [\#211](https://github.com/ekylibre/ekylibre/issues/211)
- Procedo should be more graceful on unavailable reading during computing [\#210](https://github.com/ekylibre/ekylibre/issues/210)
- Outgoing delivery invoicing fails [\#209](https://github.com/ekylibre/ekylibre/issues/209)
- Unique violation in DMS with a sales estimate [\#207](https://github.com/ekylibre/ekylibre/issues/207)
- Bookkeeping doesn't work [\#205](https://github.com/ekylibre/ekylibre/issues/205)
- When creating an intervention, issue names in selector are not displayed [\#203](https://github.com/ekylibre/ekylibre/issues/203)
- Impossible to create a new bank statement [\#202](https://github.com/ekylibre/ekylibre/issues/202)
- Non-standard interface for Backend::Accounts\#mark [\#201](https://github.com/ekylibre/ekylibre/issues/201)
- Some french help files are incorrect or useless or badly named [\#199](https://github.com/ekylibre/ekylibre/issues/199)
- When creating a new purchase, currency is not set automatically [\#198](https://github.com/ekylibre/ekylibre/issues/198)
- Catalog price amount which are not rounded are directly used to build name [\#196](https://github.com/ekylibre/ekylibre/issues/196)
- Istea General Ledger import doesn't work properly [\#193](https://github.com/ekylibre/ekylibre/issues/193)
- Countries name are not well displayed in attributes\_list [\#192](https://github.com/ekylibre/ekylibre/issues/192)
- Tax and price have to be set on variant selection in purchase creation/update [\#191](https://github.com/ekylibre/ekylibre/issues/191)
- CatalogPrice doesn't set names properly [\#190](https://github.com/ekylibre/ekylibre/issues/190)
- Action backend/product\_nature\_categories\#incorporate fails badly when record is invalid [\#188](https://github.com/ekylibre/ekylibre/issues/188)
- Issue "name" column seems to be useless [\#187](https://github.com/ekylibre/ekylibre/issues/187)
- CSV doesn't seem to be valid to go in DMS [\#186](https://github.com/ekylibre/ekylibre/issues/186)
- Cannot print in ODT, ODS, DOCX, XLSX and CSV in deposits [\#185](https://github.com/ekylibre/ekylibre/issues/185)
- Renames weedkilling to weedkiller in procedures [\#183](https://github.com/ekylibre/ekylibre/issues/183)
-  sales\#create error [\#181](https://github.com/ekylibre/ekylibre/issues/181)
- TypeError in purchases\#create: [\#179](https://github.com/ekylibre/ekylibre/issues/179)
- NoMethodError in Backend::Exports\#show  [\#178](https://github.com/ekylibre/ekylibre/issues/178)
- ActionController::ParameterMissing in Backend::CrumbsController\#update  [\#177](https://github.com/ekylibre/ekylibre/issues/177)
- NoMethodError in Backend::AccountsController\#load  [\#176](https://github.com/ekylibre/ekylibre/issues/176)
- Impossible to close a journal [\#174](https://github.com/ekylibre/ekylibre/issues/174)
- Editing event participation redirects to a view that doesn't exist [\#173](https://github.com/ekylibre/ekylibre/issues/173)
- /backend/dashboards/relationship doesn't show future events  [\#171](https://github.com/ekylibre/ekylibre/issues/171)
- Leaflet markers are not rendered due to its asset management [\#168](https://github.com/ekylibre/ekylibre/issues/168)
- Template error on plant backend [\#166](https://github.com/ekylibre/ekylibre/issues/166)
- When printing the intervention registry, something went wrong. [\#162](https://github.com/ekylibre/ekylibre/issues/162)
- When trying to add a picture directly from my phone, request is too large [\#161](https://github.com/ekylibre/ekylibre/issues/161)
- Under android OS, the input date component doesn't seem to work correctly [\#159](https://github.com/ekylibre/ekylibre/issues/159)
- In production environment, adding a custom\_fied into a model cause error [\#158](https://github.com/ekylibre/ekylibre/issues/158)
- Calendar error when logged with user with less rights [\#155](https://github.com/ekylibre/ekylibre/issues/155)
- Error when try to generate aggregator schema [\#153](https://github.com/ekylibre/ekylibre/issues/153)
- Export ODS fail  [\#152](https://github.com/ekylibre/ekylibre/issues/152)
- Financial asset management have to be reviewed [\#150](https://github.com/ekylibre/ekylibre/issues/150)
- Wrong calculation of VAT when creating profit and loss gap [\#149](https://github.com/ekylibre/ekylibre/issues/149)
- When adding a link on a legal entity, something when wrong [\#146](https://github.com/ekylibre/ekylibre/issues/146)
- After add of a new client account in accounts, I can't see it in person form [\#145](https://github.com/ekylibre/ekylibre/issues/145)
- When trying to add a new record from an unroll field, the new form is foggy [\#144](https://github.com/ekylibre/ekylibre/issues/144)
- When connecting in English, currency doesn't seem to load correctly in the consider view. [\#142](https://github.com/ekylibre/ekylibre/issues/142)
- Test Issue on Github [\#139](https://github.com/ekylibre/ekylibre/issues/139)
- Since Rails 4 migration, the unroll method does not work anymore [\#131](https://github.com/ekylibre/ekylibre/issues/131)
- After adding some replicated attributes in JournalEntryLine we have a PG::AmbiguousColumn: ERROR [\#130](https://github.com/ekylibre/ekylibre/issues/130)
- When creating an issue, the target class name is not set to the given class on inherited models [\#128](https://github.com/ekylibre/ekylibre/issues/128)
- undefined method `fr\_pcg82' for nil:NilClass [\#127](https://github.com/ekylibre/ekylibre/issues/127)
- Map view must have method or tools to consider svg view box [\#122](https://github.com/ekylibre/ekylibre/issues/122)
- undefined method `to\_xml' for "bos":Enumerize::Value [\#121](https://github.com/ekylibre/ekylibre/issues/121)
- the closed icon is hidden in entities form [\#120](https://github.com/ekylibre/ekylibre/issues/120)
- No way to add a price [\#113](https://github.com/ekylibre/ekylibre/issues/113)
- Date picker doesn't appearing on date field [\#112](https://github.com/ekylibre/ekylibre/issues/112)
- When adding many nested forms with unroll all the dropdown buttons work for the first selector [\#107](https://github.com/ekylibre/ekylibre/issues/107)
- Dialogs interact with background fields [\#106](https://github.com/ekylibre/ekylibre/issues/106)
- Unroll list doesn't set the ID value of the selected field in nested form [\#102](https://github.com/ekylibre/ekylibre/issues/102)
- Remove use of errors.add\\_to\\_base [\#100](https://github.com/ekylibre/ekylibre/issues/100)
- Translation in unroll are not used to defined labels [\#99](https://github.com/ekylibre/ekylibre/issues/99)
- Some translations are missing in some view like "extractions" [\#97](https://github.com/ekylibre/ekylibre/issues/97)
- When trying a show form \( in animals or entities\) -\> undefined method `+' for nil:NilClass [\#96](https://github.com/ekylibre/ekylibre/issues/96)
- Calendar popup doesn't work in subform [\#95](https://github.com/ekylibre/ekylibre/issues/95)
- Fixes choices/collection support in form  [\#89](https://github.com/ekylibre/ekylibre/issues/89)
- on redirect /subscription\_natures/new -\> routing error [\#78](https://github.com/ekylibre/ekylibre/issues/78)
- Global routing error when creating [\#77](https://github.com/ekylibre/ekylibre/issues/77)
- NoMethodError error on products\#index [\#76](https://github.com/ekylibre/ekylibre/issues/76)
- When printing nothing append [\#68](https://github.com/ekylibre/ekylibre/issues/68)
- The option of components list is invisible [\#67](https://github.com/ekylibre/ekylibre/issues/67)
- No way to create an entity [\#66](https://github.com/ekylibre/ekylibre/issues/66)
- blank list on :choices=\>{:reflection=\>:j.....  [\#65](https://github.com/ekylibre/ekylibre/issues/65)
- Error when adding an asset because of self.company method's depends [\#64](https://github.com/ekylibre/ekylibre/issues/64)
- Listing Request bad syntax near "Where AND" [\#60](https://github.com/ekylibre/ekylibre/issues/60)

**Closed issues:**

- FATAL error on Production/intervention "Fuel up" [\#313](https://github.com/ekylibre/ekylibre/issues/313)
- No way to select an object by a litteral input with space inside searched name [\#310](https://github.com/ekylibre/ekylibre/issues/310)
- Unroll bug when adding an incoming\_payment on a sale [\#305](https://github.com/ekylibre/ekylibre/issues/305)
- Introduction, conclusion and other fields are missing in sale reports [\#304](https://github.com/ekylibre/ekylibre/issues/304)
- Add some item in nomenclature [\#268](https://github.com/ekylibre/ekylibre/issues/268)
- Test & fix segv on catalog\_prices\#create [\#244](https://github.com/ekylibre/ekylibre/issues/244)
- In Stocks dashboard, charts don't display measurement units [\#222](https://github.com/ekylibre/ekylibre/issues/222)
- Sales statistics don't work [\#206](https://github.com/ekylibre/ekylibre/issues/206)
- When adding item to a new sale, price and tax completion aren't done automatically [\#189](https://github.com/ekylibre/ekylibre/issues/189)
- Fixes intervention fixture or plant\_grinding procedure to get the tests passed [\#184](https://github.com/ekylibre/ekylibre/issues/184)
- Renames all atomic\_\* procedures with valid names [\#182](https://github.com/ekylibre/ekylibre/issues/182)
- Various view problems when closing a journal  [\#175](https://github.com/ekylibre/ekylibre/issues/175)
- Various translations missing for french language [\#170](https://github.com/ekylibre/ekylibre/issues/170)
- Error on land\_parcels\#index view [\#167](https://github.com/ekylibre/ekylibre/issues/167)
- User name is wrongly displayed [\#156](https://github.com/ekylibre/ekylibre/issues/156)
- No document template to print a deposit [\#148](https://github.com/ekylibre/ekylibre/issues/148)
- When adding a new sale, need price, tax and round automatically [\#147](https://github.com/ekylibre/ekylibre/issues/147)
- validation issue for "trip simulation" in demo data [\#143](https://github.com/ekylibre/ekylibre/issues/143)
- A product\_groups controller should create [\#138](https://github.com/ekylibre/ekylibre/issues/138)
- land\_parcel\_groups controller should [\#137](https://github.com/ekylibre/ekylibre/issues/137)
- land\_parcel\_clusters controller should edit, show [\#136](https://github.com/ekylibre/ekylibre/issues/136)
- A intervention\_casts controller should create [\#135](https://github.com/ekylibre/ekylibre/issues/135)
- A incidents controller should create and edit [\#134](https://github.com/ekylibre/ekylibre/issues/134)
- A financial\_years controller should close. [\#133](https://github.com/ekylibre/ekylibre/issues/133)
- undefined method `duration' for \#\<EventNature:0x00000017d1d6b8\> [\#132](https://github.com/ekylibre/ekylibre/issues/132)
- Removes or find a way to update feedzirra/sax-machine [\#129](https://github.com/ekylibre/ekylibre/issues/129)
- Show the translating item coming from XML nomen. [\#118](https://github.com/ekylibre/ekylibre/issues/118)
- when testing and navigating by Capybara, unroll is hidden [\#117](https://github.com/ekylibre/ekylibre/issues/117)
- when printing animal bug append [\#115](https://github.com/ekylibre/ekylibre/issues/115)
- When editing a journal\_entries,  account\_id are not set and get [\#111](https://github.com/ekylibre/ekylibre/issues/111)
- No view in authentification \( Undefined mixin 'button-group \) [\#109](https://github.com/ekylibre/ekylibre/issues/109)
- Generalize attr\_accessible in all models [\#98](https://github.com/ekylibre/ekylibre/issues/98)
- How to translate the enumerate value ? [\#94](https://github.com/ekylibre/ekylibre/issues/94)
- How to resolve unit list translation ? [\#92](https://github.com/ekylibre/ekylibre/issues/92)
- adding the possibilities to print via Jasperreports [\#90](https://github.com/ekylibre/ekylibre/issues/90)
- Backup/restore is out of order [\#74](https://github.com/ekylibre/ekylibre/issues/74)
- Cannot load all default document templates [\#73](https://github.com/ekylibre/ekylibre/issues/73)
- ActionView [\#62](https://github.com/ekylibre/ekylibre/issues/62)
- undefined method `currency' [\#61](https://github.com/ekylibre/ekylibre/issues/61)
- undefined method `country' [\#59](https://github.com/ekylibre/ekylibre/issues/59)
- undefined method `to\_sym' [\#58](https://github.com/ekylibre/ekylibre/issues/58)
- Prices are not rounded when needed [\#44](https://github.com/ekylibre/ekylibre/issues/44)
- Add a way to create/update siret on establishments [\#33](https://github.com/ekylibre/ekylibre/issues/33)
- Need to make difference between sold products and stocked products [\#7](https://github.com/ekylibre/ekylibre/issues/7)
- Install Capybara and adds more integration tests [\#6](https://github.com/ekylibre/ekylibre/issues/6)

## [1.0.0.rc29](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc29) (2015-01-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc28...1.0.0.rc29)

## [1.0.0.rc28](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc28) (2014-12-24)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc27...1.0.0.rc28)

## [1.0.0.rc27](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc27) (2014-11-21)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc26...1.0.0.rc27)

## [1.0.0.rc26](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc26) (2014-11-07)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc25...1.0.0.rc26)

## [1.0.0.rc25](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc25) (2014-11-03)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc24...1.0.0.rc25)

## [1.0.0.rc24](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc24) (2014-10-23)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc23...1.0.0.rc24)

## [1.0.0.rc23](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc23) (2014-10-20)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc22...1.0.0.rc23)

## [1.0.0.rc22](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc22) (2014-10-07)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.2.7...1.0.0.rc22)

## [0.3.2.7](https://github.com/ekylibre/ekylibre/tree/0.3.2.7) (2014-10-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc21...0.3.2.7)

## [1.0.0.rc21](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc21) (2014-09-29)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc20...1.0.0.rc21)

## [1.0.0.rc20](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc20) (2014-09-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc19...1.0.0.rc20)

## [1.0.0.rc19](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc19) (2014-09-22)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc18...1.0.0.rc19)

## [1.0.0.rc18](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc18) (2014-09-15)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc17...1.0.0.rc18)

## [1.0.0.rc17](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc17) (2014-09-03)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc16...1.0.0.rc17)

## [1.0.0.rc16](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc16) (2014-09-03)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc15...1.0.0.rc16)

## [1.0.0.rc15](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc15) (2014-09-02)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc14...1.0.0.rc15)

## [1.0.0.rc14](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc14) (2014-08-14)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc13...1.0.0.rc14)

## [1.0.0.rc13](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc13) (2014-06-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc12...1.0.0.rc13)

## [1.0.0.rc12](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc12) (2014-06-20)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc11...1.0.0.rc12)

## [1.0.0.rc11](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc11) (2014-06-19)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc10...1.0.0.rc11)

## [1.0.0.rc10](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc10) (2014-06-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc9...1.0.0.rc10)

## [1.0.0.rc9](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc9) (2014-06-02)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc8...1.0.0.rc9)

## [1.0.0.rc8](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc8) (2014-05-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc7...1.0.0.rc8)

## [1.0.0.rc7](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc7) (2014-05-23)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc6...1.0.0.rc7)

## [1.0.0.rc6](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc6) (2014-04-03)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc5...1.0.0.rc6)

## [1.0.0.rc5](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc5) (2014-04-03)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc4...1.0.0.rc5)

## [1.0.0.rc4](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc4) (2014-04-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc3...1.0.0.rc4)

## [1.0.0.rc3](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc3) (2014-04-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc2...1.0.0.rc3)

## [1.0.0.rc2](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc2) (2014-03-26)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/1.0.0.rc1...1.0.0.rc2)

## [1.0.0.rc1](https://github.com/ekylibre/ekylibre/tree/1.0.0.rc1) (2014-03-20)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.2.5...1.0.0.rc1)

## [0.3.2.5](https://github.com/ekylibre/ekylibre/tree/0.3.2.5) (2014-01-16)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.4.3...0.3.2.5)

## [0.4.3](https://github.com/ekylibre/ekylibre/tree/0.4.3) (2013-10-31)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.4.2...0.4.3)

**Fixed bugs:**

- Debian installer failed on Wheezy \(beta\) due to thin error [\#52](https://github.com/ekylibre/ekylibre/issues/52)

## [0.4.2](https://github.com/ekylibre/ekylibre/tree/0.4.2) (2013-07-25)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.4.1...0.4.2)

**Closed issues:**

- Apache configuration in Debian package don't work with Passenger 4 [\#126](https://github.com/ekylibre/ekylibre/issues/126)

## [0.4.1](https://github.com/ekylibre/ekylibre/tree/0.4.1) (2013-01-15)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.4.1.beta2...0.4.1)

**Implemented enhancements:**

- Add a more sophisticated Account chart \(BA, BIC, BNC\) [\#37](https://github.com/ekylibre/ekylibre/issues/37)

**Fixed bugs:**

- Accounting uses bad conversion rate between the same currencies [\#57](https://github.com/ekylibre/ekylibre/issues/57)
- Some help are not rendered correctly due to an encoding bug [\#56](https://github.com/ekylibre/ekylibre/issues/56)
- Deposit print template has invalid chars after rendering on currencies [\#55](https://github.com/ekylibre/ekylibre/issues/55)
- Some of print templates are invalid in 0.4.0 [\#54](https://github.com/ekylibre/ekylibre/issues/54)
- Restoring backups fails on 0.4.0 [\#53](https://github.com/ekylibre/ekylibre/issues/53)
- Error when having an incoming deliveries -\> making a stock transfert [\#40](https://github.com/ekylibre/ekylibre/issues/40)
- Prb Install  Ekylibre sous Ubuntu Lucid [\#3](https://github.com/ekylibre/ekylibre/issues/3)

**Closed issues:**

- a lot of pages are not accessible due to incompatible character encodings [\#63](https://github.com/ekylibre/ekylibre/issues/63)
- all number have %s at the end when printing sales\_order DEVISCOM [\#39](https://github.com/ekylibre/ekylibre/issues/39)
- Error when making a stock transfert [\#38](https://github.com/ekylibre/ekylibre/issues/38)

## [0.4.1.beta2](https://github.com/ekylibre/ekylibre/tree/0.4.1.beta2) (2012-10-08)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.4.1.beta1...0.4.1.beta2)

## [0.4.1.beta1](https://github.com/ekylibre/ekylibre/tree/0.4.1.beta1) (2012-10-07)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.4.0...0.4.1.beta1)

## [0.4.0](https://github.com/ekylibre/ekylibre/tree/0.4.0) (2012-09-07)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.2.4...0.4.0)

**Implemented enhancements:**

- Adds \(financial\) assets management [\#17](https://github.com/ekylibre/ekylibre/issues/17)

**Fixed bugs:**

- Adds asset precompilation for installers. [\#50](https://github.com/ekylibre/ekylibre/issues/50)
- Iconv is missing for ruby \>= 1.9 due to spreet removing [\#49](https://github.com/ekylibre/ekylibre/issues/49)
- No route matches when trying to load accounts [\#41](https://github.com/ekylibre/ekylibre/issues/41)
- Moves the test of the help files's titles in the test procedure [\#32](https://github.com/ekylibre/ekylibre/issues/32)
- Sales are not accounted as defined in sale\#nature [\#31](https://github.com/ekylibre/ekylibre/issues/31)
- Can not delete sale or purchase prices [\#27](https://github.com/ekylibre/ekylibre/issues/27)
- Cannot login to the selected company if another company is present in URL [\#21](https://github.com/ekylibre/ekylibre/issues/21)
- Outgoing deliveries do not work well... [\#15](https://github.com/ekylibre/ekylibre/issues/15)
- Ruby 1.9.3 crashes under Win 7 when registering company at the begining [\#14](https://github.com/ekylibre/ekylibre/issues/14)
- Missing translation in view financial\_years\#show: labels.last\_computed\_balance [\#9](https://github.com/ekylibre/ekylibre/issues/9)

**Closed issues:**

- Fixtures of events do not work anymore with MySQL [\#45](https://github.com/ekylibre/ekylibre/issues/45)
- add a method to validate email to prevent error [\#34](https://github.com/ekylibre/ekylibre/issues/34)
- Remove title for unique-item menus in side bar [\#25](https://github.com/ekylibre/ekylibre/issues/25)
- Authorize NBSP and other escape characters in locale files [\#20](https://github.com/ekylibre/ekylibre/issues/20)
- Eliminates deprecated code for Rails 4 [\#18](https://github.com/ekylibre/ekylibre/issues/18)
- Adds an attribute to IncomingPaymentMode to specify the journal where entries are recorded [\#13](https://github.com/ekylibre/ekylibre/issues/13)
- Removes default value in database for Journal\#closed\_on [\#11](https://github.com/ekylibre/ekylibre/issues/11)
- Migrates to Rails 3.2 [\#10](https://github.com/ekylibre/ekylibre/issues/10)

## [0.3.2.4](https://github.com/ekylibre/ekylibre/tree/0.3.2.4) (2012-09-05)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.2.3...0.3.2.4)

**Closed issues:**

- Bug on Debian package update with 0.3.2.4 [\#51](https://github.com/ekylibre/ekylibre/issues/51)
- Fixes MySQL error in fixtures due to date format [\#48](https://github.com/ekylibre/ekylibre/issues/48)
- Fix installer for Windows 7 [\#46](https://github.com/ekylibre/ekylibre/issues/46)

## [0.3.2.3](https://github.com/ekylibre/ekylibre/tree/0.3.2.3) (2012-06-04)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.2.1...0.3.2.3)

## [0.2.1](https://github.com/ekylibre/ekylibre/tree/0.2.1) (2012-06-04)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.2.2...0.2.1)

## [0.3.2.2](https://github.com/ekylibre/ekylibre/tree/0.3.2.2) (2012-04-13)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.2.1...0.3.2.2)

## [0.3.2.1](https://github.com/ekylibre/ekylibre/tree/0.3.2.1) (2012-02-22)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.2...0.3.2.1)

## [0.3.2](https://github.com/ekylibre/ekylibre/tree/0.3.2) (2012-01-10)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.1...0.3.2)

**Closed issues:**

- Fix bug with will\_paginate in RemoteLinkRenderer [\#2](https://github.com/ekylibre/ekylibre/issues/2)

## [0.3.1](https://github.com/ekylibre/ekylibre/tree/0.3.1) (2011-10-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.1.a2...0.3.1)

**Closed issues:**

- Remove every javascript tags in view \(UJS\) [\#1](https://github.com/ekylibre/ekylibre/issues/1)

## [0.3.1.a2](https://github.com/ekylibre/ekylibre/tree/0.3.1.a2) (2011-07-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.1.a1...0.3.1.a2)

## [0.3.1.a1](https://github.com/ekylibre/ekylibre/tree/0.3.1.a1) (2011-06-21)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.3.0...0.3.1.a1)

## [0.3.0](https://github.com/ekylibre/ekylibre/tree/0.3.0) (2011-05-19)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.2.0...0.3.0)

## [0.2.0](https://github.com/ekylibre/ekylibre/tree/0.2.0) (2010-07-01)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.1.5...0.2.0)

## [0.1.5](https://github.com/ekylibre/ekylibre/tree/0.1.5) (2010-05-18)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.1.4...0.1.5)

## [0.1.4](https://github.com/ekylibre/ekylibre/tree/0.1.4) (2010-04-28)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.1.3...0.1.4)

## [0.1.3](https://github.com/ekylibre/ekylibre/tree/0.1.3) (2010-04-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.1.2...0.1.3)

## [0.1.2](https://github.com/ekylibre/ekylibre/tree/0.1.2) (2010-02-08)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.1.1...0.1.2)

## [0.1.1](https://github.com/ekylibre/ekylibre/tree/0.1.1) (2010-02-03)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.1.0...0.1.1)

## [0.1.0](https://github.com/ekylibre/ekylibre/tree/0.1.0) (2010-02-02)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.16...0.1.0)

## [0.0.16](https://github.com/ekylibre/ekylibre/tree/0.0.16) (2010-01-14)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.15...0.0.16)

## [0.0.15](https://github.com/ekylibre/ekylibre/tree/0.0.15) (2009-11-23)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.14...0.0.15)

## [0.0.14](https://github.com/ekylibre/ekylibre/tree/0.0.14) (2009-10-15)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.13...0.0.14)

## [0.0.13](https://github.com/ekylibre/ekylibre/tree/0.0.13) (2009-10-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.12...0.0.13)

## [0.0.12](https://github.com/ekylibre/ekylibre/tree/0.0.12) (2009-09-18)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.11...0.0.12)

## [0.0.11](https://github.com/ekylibre/ekylibre/tree/0.0.11) (2009-07-16)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.10...0.0.11)

## [0.0.10](https://github.com/ekylibre/ekylibre/tree/0.0.10) (2009-07-14)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.9...0.0.10)

## [0.0.9](https://github.com/ekylibre/ekylibre/tree/0.0.9) (2009-06-29)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.8...0.0.9)

## [0.0.8](https://github.com/ekylibre/ekylibre/tree/0.0.8) (2009-05-24)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.7...0.0.8)

## [0.0.7](https://github.com/ekylibre/ekylibre/tree/0.0.7) (2009-05-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.6...0.0.7)

## [0.0.6](https://github.com/ekylibre/ekylibre/tree/0.0.6) (2009-04-24)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.5...0.0.6)

## [0.0.5](https://github.com/ekylibre/ekylibre/tree/0.0.5) (2009-04-06)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.4...0.0.5)

## [0.0.4](https://github.com/ekylibre/ekylibre/tree/0.0.4) (2009-03-31)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.3...0.0.4)

## [0.0.3](https://github.com/ekylibre/ekylibre/tree/0.0.3) (2009-03-09)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.2...0.0.3)

## [0.0.2](https://github.com/ekylibre/ekylibre/tree/0.0.2) (2009-02-22)
[Full Changelog](https://github.com/ekylibre/ekylibre/compare/0.0.1...0.0.2)

## [0.0.1](https://github.com/ekylibre/ekylibre/tree/0.0.1) (2009-02-12)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*