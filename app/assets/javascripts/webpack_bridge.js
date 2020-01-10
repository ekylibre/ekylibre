function import_module(module, into) {
  for (var prop in module) {
    if (module.hasOwnProperty(prop)) {
      into[prop] = module[prop]
    }
  }
}

import_module(Packs.legacy.vendors, window)

var ekylibre = window.ekylibre = Packs.legacy.Ekylibre

import_module(Packs.legacy.globals, window)