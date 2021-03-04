import 'whatwg-fetch';
import 'pages/index';

import { StateBadgeSet, StateSet } from 'components/state_badge_set';
import { ajax, customFetch } from 'services/ajax';
import RBush from 'rbush';
import * as moment from 'moment';
import { notify, setup } from 'services/notification';
import { enableDatePicker, enableDateRangePicker, enableDatetimePicker } from 'lib/flatpickr';
import { open, openFromElementDataAttributes, openRemote } from 'components/modal';
import { I18n } from 'services/i18n/index';
import * as Behave from 'services/behave';
import { delegateListener, onDomReady, onElementDetected } from 'lib/domEventUtils';
import autosize from 'autosize/dist/autosize';
import { openDialog } from 'components/dialog';
import _ from 'lodash';
import L from 'leaflet';
import 'leaflet-draw';
import 'lib/leaflet/default-icon';
import { MasterProductionNatureService } from 'services/masterProductionNatureService';
import { VarietyService } from 'services/varietyService';
import { CultivableZoneService } from 'services/cultivableZoneService';

export let Ekylibre = {
    ajax,
    delegateListener,
    Dialog: { open: openDialog },
    fetch: customFetch,
    forms: {
        date: { enableDatePicker, enableDateRangePicker, enableDatetimePicker },
    },
    notification: { setup, notify },
    onElementDetected,
    onDomReady,
    MasterProductionNatureService,
    VarietyService,
    CultivableZoneService,
};

export let globals = {
    Behave,
    calcul: {},
    DynamicModal: {
        open,
        openFromElementDataAttributes,
        openRemote,
    },
    golumn: {},
    mapeditor: {},
    StateBadgeSet,
    StateSet,
    visualization: {},
};

export let vendors = {
    _,
    autosize,
    I18n,
    moment,
    RBush,
    L,
};
