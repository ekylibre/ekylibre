# Aggregator

Introduces concept of aggregators in Ekylibre. Aggregator defines a structure
of heterogeneous data extracted from many models of Ekylibre.

Rules:

* Attributes and sub-items must have different names!

## Markup

These lines describes the major attributes to define the aggregation model:

Standard markup:

    aggregators:
      aggregator*

    aggregator(name):
      parameters?
      (section|sections|matrix)

    parameters:
      parameter(name, type, of?, default?)

Main markup:

    section(name, value?, level?, if?):
      variable*
      title?
      property*
      section*
      sections*
      matrix*

    sections(for?, in, name?, level?, if?): # Describe item structure like a section
      variable*
      title?
      property*
      section*
      sections*
      matrix*

    matrix(name?, for?, in?, level?, if?):
      variable*
      (cell|matrix)+

    [title|property|cell](name, value?, of?, level?, if?):

Special markup `<within>` permits to set default name or value for a group of
`<title>`, `<property>` or `<cell>`.

    within(name?, value?, of?, if?, level?):

    variable(name, value, if?):

## Sample

These following codes compose the Rosetta Stone to unciffer the Aggregator
XML.

### Aggregator XML

    <?xml version="1.0" encoding="UTF-8"?>
    <aggregators>
      <aggregator name="veterinary_booklet">
        <parameters>
          <parameter name="campaigns" type="record-list"/>
          <parameter name="company" type="record"/>
          <parameter name="breeding_number" type="string"/>
        </parameters>
        <sections name="interventions" with="procedures">
          <title name="name"/>
          <property name="id" level="api"/>
          <matrix name="inputs" with="intervention.variables.of_generic_role(:input)">
            <cell name="id" level="api"/>
            <cell name="role_label" value="input.role.text"/>
            <cell name="indicator" level="api"/>
            <cell name="indicator_label" value="input.indicator.text" if="input.indicator != 'net_surface_area'"/>
          </matrix>
        </sections>
      </aggregator>
    </aggregators>

### JSON

    [
      {"name": "First intervention",
       "id": "1",
       "inputs": [
         ["1", "Input", "net_surface_area", null],
         ["2", "Input", "net_weight", "Net weight"]
       ]
      },
      {"name": "Second intervention",
       "id": "2",
       "inputs": [
         ["7", "Input", "net_volume", "Net volume"],
       ]
      }
    ]

### XML

    <interventions>
      <intervention name="First intervention" id="1">
        <inputs>
          <input id="1" role-label="Input" indicator="net_surface_area"/>
          <input id="2" role-label="Input" indicator="net_weight" indicator-label="Net weight"/>
        </inputs>
      </intervention>
      <intervention name="Second intervention" id="2">
        <inputs>
          <input id="7" role-label="Input" indicator="net_volume" indicator-label="Net volume"/>
        </inputs>
      </intervention>
    </interventions>

Then through JasperReports (and a report), it gives: PDF, ODS, ODT, XLSX,
DOCX, CSV...

### HTML

    <ul class="interventions">
      <li class="intervention" data-api-id="1">
        <h2>First intervention</h2>
        <table class="inputs">
          <thead>
            <tr>
              <th class="role-label">Role label</th> <!-- How to translate properly? -->
              <th class="indicator-label">Indicator label</th> <!-- How to translate properly? -->
            </tr>
          </thead>
          <tbody>
            <tr class="input" data-api-id="1" data-api-indicator="net_surface_area">
              <td class="role-label">Input</td>
              <td class="indicator-label"></td>
            </tr>
            <tr class="input" data-api-id="2" data-api-indicator="net_weight">
              <td class="role-label">Input</td>
              <td class="indicator-label">Net weight</td>
            </tr>
          </tbody>
        </table>
      </li>
      <li class="intervention" data-api-id="2">
        <h2>Second intervention</h2>
        <table class="inputs">
          <thead>
            <tr>
              <th class="role-label">Role label</th> <!-- How to translate properly? -->
              <th class="indicator-label">Indicator label</th> <!-- How to translate properly? -->
            </tr>
          </thead>
          <tbody>
            <tr class="input" data-api-id="7" data-api-indicator="net_surface_area">
              <td class="role-label">Input</td>
              <td class="indicator-label">Net volume</td>
            </tr>
          </tbody>
        </table>
      </li>
    </ul>

### CSV ?

    "intervention.name","intervention.id","input.id","input.role_label"
    "First intervention","1","1","Input",...
    "","","2","Input",...
    ...

### Other formats

ODS and ODT could be generated automatically without reports.

