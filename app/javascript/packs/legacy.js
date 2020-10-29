import 'whatwg-fetch'
import {StateSet, StateBadgeSet} from "components/state_badge_set"
import {customFetch, ajax} from "services/ajax"
import RBush from "rbush"
import * as moment from 'moment'
import {setup, notify} from 'services/notification'
import {enableDatePicker, enableDateRangePicker, enableDatetimePicker} from "lib/flatpickr"

export let Ekylibre = {
  fetch: customFetch,
  ajax: ajax,
  notification: {setup, notify},
  forms: {
    date: {enableDatePicker, enableDateRangePicker, enableDatetimePicker}
  }
}

export let globals = {
  visualization: {},
  mapeditor: {},
  calcul: {},
  golumn: {},
  StateSet: StateSet,
  StateBadgeSet: StateBadgeSet
}

export let vendors = {
  _: require('lodash'),
  RBush: RBush,
  moment: moment
}

