import flatpickr from "flatpickr"
import confirmDatePlugin from "flatpickr/dist/plugins/confirmDate/confirmDate"
import {French} from "flatpickr/dist/l10n/fr"
import {Arabic} from "flatpickr/dist/l10n/ar"
import {German} from "flatpickr/dist/l10n/de"
import {Spanish} from "flatpickr/dist/l10n/es"
import {Italian} from "flatpickr/dist/l10n/it"
import {Japanese} from "flatpickr/dist/l10n/ja"
import {Portuguese} from "flatpickr/dist/l10n/pt"
import {Mandarin} from "flatpickr/dist/l10n/zh"

const locales = {
  ar: Arabic,
  de: German,
  es: Spanish,
  fr: French,
  it: Italian,
  ja: Japanese,
  pt: Portuguese,
  zh: Mandarin
}

function getLocale(element) {
  return locales[element.lang || I18n.locale.substr(0, 2)]
}

function baseDateOptions(element) {
  return {
    locale: getLocale(element),
    dateFormat: 'Y-m-d',
    altInput: true,
    allowInput: true,
    altFormat: 'd-m-Y',
    static: true
  }
}

function baseDateTimeOptions(element) {
  return {
    ...baseDateOptions(element),
    enableTime: true,
    dateFormat: 'Y-m-d H:i',
    altFormat: 'd-m-Y H:i',
    time_24hr: true,
    plugins: [new confirmDatePlugin({
      showAlways: true
    })]
  }
}

function baseDateRangeOptions(element) {
  return {
    ...baseDateOptions(element),
    mode: 'range',
    dateFormat: 'Y-m-d',
    showMonths: 2,
    static: false
  }
}

function setupBlurListener(flatInstance) {
  const input = flatInstance.altInput
  input.addEventListener('blur', e => flatInstance.setDate(input.value, true, flatInstance.config.altFormat))
}

export function enableDatePicker(element) {
  if (element === null || element.dataset.flatpickr === "false") {
    return
  }

  const options = baseDateOptions(element)
  const flatInstance = flatpickr(element, options)

  setupBlurListener(flatInstance)

  return flatInstance
}

export function enableDatetimePicker(element) {
  const options = baseDateTimeOptions(element)
  const flatInstance = flatpickr(element, options)

  setupBlurListener(flatInstance)

  return flatInstance
}

export function enableDateRangePicker(element) {
  element.type = 'text'

  const options = baseDateRangeOptions(element)
  const flatInstance = flatpickr(element, options)

  setupBlurListener(flatInstance)

  return flatInstance
}
