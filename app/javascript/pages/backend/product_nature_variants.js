import { onDomReady } from 'lib/domEventUtils';
import { MeasureService } from 'services/measureService';
import { UnitService } from 'services/unitService';
import { round } from 'lodash';

onDomReady(() => {
    const formElement = document.querySelector('#new_product_nature_variant, #edit_product_nature_variant');
    if (formElement !== null && !!formElement.querySelector('#product_nature_variant_nature_id').value) {
        form.init(formElement);
    }
});

const form = { init, bindDefaultUnitToUnitName, bindDefaultUnitInputToIndicatorInput, bindSeedIndicators, disableNetMassWhenUnity };

function init(formElement) {
    form.bindDefaultUnitInputToIndicatorInput();
    form.bindDefaultUnitToUnitName();
    const natureSelector = formElement.querySelector('#product_nature_variant_nature_id');
    if (natureSelector != null && natureSelector.dataset.selectorId.includes('seed_and_plant_article')) {
        form.bindSeedIndicators();
        form.disableNetMassWhenUnity();
    }
}

// Autocomplete thousand grains mass when grains count is filled and vice versa
function bindSeedIndicators() {
    const unitService = new UnitService();
    const defaultUnitSelector = document.querySelector('#product_nature_variant_default_unit_id');
    const thousandGrainsMassIndicatorField = getIndicatorField('thousand_grains_mass');
    const grainsCountIndicatorField = getIndicatorField('grains_count');
    const netMassIndicatorField = getIndicatorField('net_mass');
    const conversionFactor = 1000;

    thousandGrainsMassIndicatorField.element.addEventListener('change', function (event) {
        getDefaultUnitName().then(function (referenceName) {
            if (referenceName !== 'unity') {
                updateGrainsCount(event.target.value);
            }
        });
    });

    grainsCountIndicatorField.element.addEventListener('change', function (event) {
        getDefaultUnitName().then(function (referenceName) {
            if (referenceName !== 'unity') {
                updateThousandGrainsMass(event.target.value);
            }
        });
    });

    function getDefaultUnitName() {
        const unitId = defaultUnitSelector.nextSibling.value;
        return unitService.get(unitId).then(function (unit) {
            return unit.reference_name;
        });
    }

    function updateGrainsCount(thousandGrainsMassValue) {
        const netMass = netMassIndicatorField.indicator.value;
        const grainsCount = (netMass * conversionFactor) / thousandGrainsMassValue;
        if (netMass !== null && typeof grainsCount === 'number') {
            grainsCountIndicatorField.update(round(grainsCount, 2));
        }
    }

    function updateThousandGrainsMass(grainsCount) {
        const netMass = netMassIndicatorField.indicator.value;
        const thousandGrainsMassValue = (netMass * conversionFactor) / grainsCount;
        if (netMass !== null && typeof thousandGrainsMassValue === 'number') {
            thousandGrainsMassIndicatorField.update(round(thousandGrainsMassValue, 2));
        }
    }
}

// Disable and nullify indicator net mass, when default unit is unity
function disableNetMassWhenUnity() {
    const unitService = new UnitService();
    const defaultUnitSelector = document.querySelector('#product_nature_variant_default_unit_id');
    const netMassIndicatorField = getIndicatorField('net_mass');

    defaultUnitSelector.addEventListener('unroll:selector:change', handleUnitChange);

    function handleUnitChange() {
        const unitId = defaultUnitSelector.nextSibling.value;
        unitService.get(unitId).then(function (unit) {
            if (unit.reference_name === 'unity') {
                netMassIndicatorField.disable();
                netMassIndicatorField.update('');
            }
        });
    }
}

// Autocomplete unit name when default unit is selected
function bindDefaultUnitToUnitName() {
    const defaultUnitSelector = document.querySelector('#product_nature_variant_default_unit_id');
    const unitNameInput = document.querySelector('#product_nature_variant_unit_name');
    const defaultQuantityInput = document.querySelector('#product_nature_variant_default_quantity');

    defaultUnitSelector.addEventListener('unroll:selector:change', handleUnitChange);

    function handleUnitChange(event) {
        const detail = event.detail;
        if (!detail.wasInitializing) {
            if (parseFloat(defaultQuantityInput.value) === 1) {
                unitNameInput.value = this.value;
            }
        }
    }
}

// Autocomplete and disable indicator matching the default unit
function bindDefaultUnitInputToIndicatorInput() {
    const measureService = new MeasureService();
    const unitService = new UnitService();
    const defaultQuantityInput = document.querySelector('#product_nature_variant_default_quantity');
    const defaultUnitSelector = document.querySelector('#product_nature_variant_default_unit_id');
    const dimensionIndicatorName = {
        mass: 'net_mass',
        volume: 'net_volume',
        none: 'grains_count',
    };

    const allowedDimension = Object.keys(dimensionIndicatorName);

    // Attach event listeners to the default quantity input and unit selector
    defaultQuantityInput.addEventListener('change', handleQuantityChange);
    defaultUnitSelector.addEventListener('unroll:selector:change', handleUnitChange);

    // Handle the change of default quantity input and unit selector
    function handleQuantityChange(event) {
        updateIndicatorField(event.target.value);
    }

    function handleUnitChange(event) {
        const detail = event.detail;
        if (!detail.wasInitializing) {
            enableAllIndicators();
        }
        updateIndicatorField(defaultQuantityInput.value, true);
    }

    // Update the indicator field with the new quantity and unit
    function updateIndicatorField(quantity, disable = false) {
        const unitId = defaultUnitSelector.nextSibling.value;

        unitService.get(unitId).then(function (unit) {
            if (!allowedDimension.includes(unit.dimension)) {
                return;
            }
            const indicatorName = getIndicatorName(unit.dimension);
            const indicatorField = getIndicatorField(indicatorName);
            if (indicatorField != null) {
                const siblingUnitName = indicatorField.indicator.unit;

                measureService.convert(quantity, unit.reference_name, siblingUnitName).then((measure) => {
                    indicatorField.update(measure.value);
                });
                if (disable) {
                    indicatorField.disable();
                }
            }
        });
    }

    // reset all indicator measure value value elements by removing the disabled class and nullifying the value
    function enableAllIndicators() {
        const indicatorValueInputs = document.querySelectorAll('input[id$=measure_value_value]');
        indicatorValueInputs.forEach(function (input) {
            input.classList.remove('disabled');
        });
    }

    function getIndicatorName(dimension) {
        return dimensionIndicatorName[dimension];
    }
}

class IndicatorField {
    constructor(indicatorNameInputElement) {
        const element = indicatorNameInputElement.closest('.nested-fields');
        this.element = element;
        this.valueInput = element.querySelector('input[id$=measure_value_value]');
        this.unitInput = element.querySelector('input[id$=measure_value_unit]');
    }

    get indicator() {
        return {
            value: this.valueInput.value,
            unit: this.unitInput.value,
        };
    }

    update(value) {
        this.valueInput.value = value;
        this.valueInput.dispatchEvent(new Event('change'));
    }

    disable() {
        this.valueInput.classList.add('disabled');
    }
}

// Get the indicator field by the indicator name
function getIndicatorField(indicatorName) {
    const indicatorNameInputElement = document.querySelector(`[id$=indicator_name][value=${indicatorName}]`);
    if (indicatorNameInputElement != null) {
        return new IndicatorField(indicatorNameInputElement);
    }
}
