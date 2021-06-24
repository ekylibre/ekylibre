# Components
## Glossary

DMS: Document Management System

## Transitionable: states machines

TODO

## ODT Printers architecture
### Overview
Starting with 3.20, the system work as as follows:
- Printers should extend the `Printers::PrinterBase` class and provide implementation for `key` and `generate`
- `Ekylibre::DocumentManagement::DocumentGenerator` that is responsible to generate a PDF or ODT from a given printer and `DocumentTemplate`
- `Ekylibre::DocumentManagement::DocumentArchiver` that archives a provided PDF document in a Document in the Document Management System and signs it using `Ekylibre::DocumentManagement::SignatureManager` if necessary.

There are more low level components:
- `Ekylibre::DocumentManagement::TemplateFileProvider` that, for a given template (or Onoma::DocumentNature) returns the path of the template file.
- `Ekylibre::DocumentManagement::PdfConverter` that converts a binary representation of a ODT file to the binary representation of a PDF file

### Usage
#### Creating a new printer

The file should be in `app/services/printers`. If multiple printers exist for the same model (or they are related somehow), the possibility of grouping them in a specific module should be considered.

The class should extend `Printers::PrinterBase` and implement `key` and `generate`
- `key` is used to identify in the DMS the documents belonging to the same database record.
- `generate` should be providing to the given `report` the data that should be interpolated into the template.

By convention, all code related to building the dataset to interpolate in the template should be put in a `compute_dataset` method.  

#### Generating a ODT/PDF file

``` ruby
# Given a DocumentTemplate and a printer
template = DocumentTemplate.find(...)
printer = Printers::MyPrinter.new(...)

generator = Ekylibre::DocumentManagement::DocumentGenerator.build
odt_data = generator.generate_odt(template: template, printer: printer)
# OR
pdf_data = generator.generate_pdf(template: template, printer: printer)

# If a file needs to be generated, it should be done by writing to the file in _binary_ mode:
Pathname.new('path/to/the/file.pdf").binwrite(pdf_data)
```

#### Archiving a PDF file

``` ruby
# Given the pdf_data generated as above
pdf_data = ...

archiver = Ekylibre::DocumentManagement::DocumentArchiver.build
document = archiver.archive_document(pdf_content: pdf_data, template: template, key: printer.key, name: printer.document_name)
```
