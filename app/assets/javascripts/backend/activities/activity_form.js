(function (E, $) {
    const varietyService = new E.VarietyService();
    const masterCropProductionService = new E.MasterCropProductionService();
    const campaignService = new E.CampaignService();
    const defaultStateStateOfProduction = [
        { label: '', year: null, default: true },
        { label: 'N+1', year: 1, default: false },
        { label: 'N+2', year: 2, default: false },
        { label: 'N+3', year: 3, default: false },
        { label: 'N+4', year: 4, default: false },
        { label: 'N+5', year: 5, default: false },
    ];

    class ActivityForm {
        constructor($formElement) {
            this.$formElement = $formElement;

            this.$productionNatureControl = this.$formElement.find('.control-group.activity_production_nature:first').first();
            this.$productionNatureInput = this.$formElement.find('#activity_reference_name').first();
            this.$productionCycleInput = this.$formElement.find("input[type=radio][name='activity[production_cycle]']");

            this.fpStartedOn = this.$formElement.find('input#activity_production_started_on').get(0)._flatpickr;
            this.fpStoppedOn = this.$formElement.find('input#activity_production_stopped_on').get(0)._flatpickr;
        }

        init() {
            this.$productionCycleInput.on('change', (event) => {
                if (event.target.value === 'annual') {
                    this.resetPerenialInputs();
                } else {
                    const $productionStoppedOnYear = $('select#activity_production_stopped_on_year');
                    $productionStoppedOnYear.val(0);
                    $productionStoppedOnYear.addClass('disabled');
                }
            });

            this.$productionNatureInput.on('selector:change selector:cleared', (_event, _selectedElement, was_initializing) => {
                this.hideHint();
                if (!was_initializing) {
                    this.onProductionNatureChange();
                }
            });

            $('#tactics-field').on('cocoon:after-insert', () => {
                const referenceName = this.$productionNatureInput.next().val();
                const campaignId = $('.period-selector .period').data('campaign-id');
                this.setTechnicalInputsScope(referenceName);
                this.setTacticCampaign(campaignId);
                $('.activity_tactics_Date').find('.date').val(this.setActivityTacticDate());
            });

            this.$formElement.find('input#activity_production_started_on').on('change', () => {
                $('.activity_tactics_Date').find('.date').get(0)._flatpickr.setDate(this.setActivityTacticDate());
            });

            this.$formElement.find('#activity_production_started_on_year').on('change', () => {
                $('.activity_tactics_Date').find('.date').get(0)._flatpickr.setDate(this.setActivityTacticDate());
            });
        }

        onProductionNatureChange() {
            const productionReferenceName = this.$productionNatureInput.next().val();
            if (productionReferenceName == null) {
                this.resetVarieties();
                this.showHint();
            } else {
                this.setTechnicalInputsScope(productionReferenceName);
                this.reset();
                masterCropProductionService.get(productionReferenceName).then((productionNature) => {
                    if (
                        productionNature.started_on_year != null &&
                        productionNature.stopped_on_year != null &&
                        productionNature.started_on &&
                        productionNature.stopped_on
                    ) {
                        this.setProductionPeriod(
                            productionNature.started_on,
                            productionNature.stopped_on,
                            productionNature.started_on_year,
                            productionNature.stopped_on_year
                        );
                    }

                    if (productionNature.specie) {
                        this._updateSelectWithFamilyVarieties(productionNature.specie);
                    } else {
                        this.resetVarieties();
                    }

                    if (productionNature.cycle) {
                        this.setProductionCycle(productionNature.cycle);
                    }

                    let startStateOfProduction;
                    if (productionNature.start_states && productionNature.start_states.length > 0) {
                        startStateOfProduction = productionNature.start_states;
                    } else {
                        startStateOfProduction = defaultStateStateOfProduction;
                    }
                    this.setSelectOptions(
                        'select#activity_start_state_of_production_year',
                        optionsForSelect(startStateOfProduction, {
                            label: (e) => e.label,
                            value: (e) => e.year,
                            selected: (e) => e['default'],
                        })
                    );

                    if (productionNature.cycle == 'perennial' && productionNature.life_duration) {
                        this.setLifeDuration(productionNature.life_duration);
                    }
                });
            }
        }

        reset() {
            this.resetPerenialInputs();
            this.setProductionPeriod();
            this.setLifeDuration();
        }

        resetVarieties() {
            const familyCultivationVariety = $('select#activity_cultivation_variety').data('family-cultivation-variety');
            this._updateSelectWithFamilyVarieties(familyCultivationVariety);
        }

        get $technicalWorkflowInput() {
            return this.$formElement.find("[id ^='activity_tactics_attributes'][id $='_technical_workflow_id']");
        }

        get $technicalSequenceInput() {
            return this.$formElement.find("[id ^='activity_tactics_attributes'][id $='_technical_sequence_id']");
        }

        get $tacticCampaignInput() {
            return this.$formElement.find("[id ^='activity_tactics_attributes'][id $='_campaign_id']");
        }

        setTechnicalInputsScope(referenceName) {
            const scope = `unroll?scope[of_production]=${referenceName}`              

            if (this.$technicalWorkflowInput.length > 0 &&  referenceName !== '' ) {
                const unrollUrl = this.$technicalWorkflowInput.data('selector').replace(/unroll.*/, scope);
                this.$technicalWorkflowInput.attr('data-selector', unrollUrl);
            }

            if (this.$technicalSequenceInput.length > 0 &&  referenceName !== '' ) {
                const unrollUrl = this.$technicalSequenceInput.data('selector').replace(/unroll.*/, scope);
                this.$technicalSequenceInput.attr('data-selector', unrollUrl);
            }
        }

        _updateSelectWithFamilyVarieties(familyCultivationVariety) {
            varietyService.selection(familyCultivationVariety).then((varietySelection) => {
                if (varietySelection.length >= 1) {
                    this.setSelectOptions(
                        'select#activity_cultivation_variety',
                        optionsForSelect(varietySelection, {
                            label: (e) => e.label,
                            value: (e) => e.referenceName,
                        })
                    );
                }
            });
        }

        resetPerenialInputs() {
            $('input#activity_life_duration').val(null);
            $('select#activity_start_state_of_production_year').val(null);
            const $productionStoppedOnYear = $('select#activity_production_stopped_on_year');
            if ($productionStoppedOnYear.hasClass('disabled')) {
                $productionStoppedOnYear.removeClass('disabled');
            }
        }

        hideHint() {
            const $hint = this.$productionNatureControl.find('p.help-block');
            $hint.hide();
        }

        showHint() {
            const $hint = this.$productionNatureControl.find('p.help-block');
            $hint.show();
        }

        setTacticCampaign(value) {
            if (this.$tacticCampaignInput.length > 0) {
                this.$tacticCampaignInput.val(value);
            }
        }

        setActivityTacticDate() {       
            const isActivityProductionPerennial = $('#activity_production_cycle_perennial').is(":checked");

            if (isActivityProductionPerennial) {
                const activityProductionStartedOn = $('#activity_production_started_on').val();
                const activityProductionStartedOnYear = $('#activity_production_started_on_year').val();

                if (activityProductionStartedOn !== ''  && activityProductionStartedOnYear !== '') {
                    const campaignYear = document.querySelector('[data-campaign-id]').innerText;
                    const startedYearOfCurrentCampaign = parseInt(campaignYear) + parseInt(activityProductionStartedOnYear);

                    const startedDateOfCurrentCampaign = startedYearOfCurrentCampaign + activityProductionStartedOn.slice(4);
                    return startedDateOfCurrentCampaign;
                }
            }  
        }

        setProductionPeriod(startedOn, stoppedOn, startedOnYear, stoppedOnYear) {
            this.fpStartedOn.setDate(startedOn);
            this.fpStoppedOn.setDate(stoppedOn);
            $('select#activity_production_started_on_year').val(startedOnYear);
            $('select#activity_production_stopped_on_year').val(stoppedOnYear);
        }

        setProductionCycle(type) {
            const $radioButton = $('#activity_production_cycle_' + type);
            if (!$radioButton.prop('checked')) {
                $radioButton.prop('checked', true).trigger('change');
            }
        }

        setLifeDuration(value) {
            const $activity_life_duration_input = $('input#activity_life_duration');
            $activity_life_duration_input.val(value);
        }

        setSelectOptions(selector, options) {
            $(selector).empty();

            if (options) {
                $(selector).append(options);
            }
        }
    }

    function optionsForSelect(options, config) {
        const { label, value, selected = () => false } = config;

        return options.map((option) => {
            return $('<option>').html(label(option)).attr('value', value(option)).attr('selected', selected(option));
        });
    }

    function initForm() {
        const $formElement = $('form#new_activity,form[id^=edit_activity]');
        if ($formElement.length === 0 || $('select#activity_family').val() === '') {
            return;
        }

        const activity_form = new ActivityForm($formElement);
        activity_form.init();

        const periodSelectorElement = document.querySelector('.period-selector');
        if (!!periodSelectorElement) {
            new CampaignSelector(periodSelectorElement, activity_form).bindEvents();
        }
    }

    class CampaignSelector {
        constructor(element, activityForm) {
            this.element = element;
            this.activityForm = activityForm;
            this.nextButton = element.querySelector('.btn-next');
            this.previousButton = element.querySelector('.btn-previous');
            this.currentButton = element.querySelector('.period');
            this.campaignInput = element.querySelector('#campaign_name');
        }

        bindEvents() {
            this.previousButton.addEventListener('click', () => {
                this.changeCampaign('previous');
            });

            this.nextButton.addEventListener('click', () => {
                this.changeCampaign('next');
            });
        }

        get currentYear() {
            return parseInt(this.currentButton.innerText);
        }

        changeCampaign(action) {
            let year;
            if (action == 'next') {
                year = this.currentYear + 1;
            } else {
                year = this.currentYear - 1;
            }
            this.campaignInput.value = year
            this.currentButton.innerText = year;
            campaignService.getByName(this.currentYear).then((campaing) => {
                this.activityForm.setTacticCampaign(campaing.id);
                this.currentButton.dataset.campaignId = campaing.id;
            });

            $('.activity_tactics_Date').find('.date').get(0)._flatpickr.setDate(this.activityForm.setActivityTacticDate());
        }
    }

    E.onDomReady(function () {
        initForm();

        $(document).on('change keyup', '.plant-density-abacus .activity_plant_density_abaci_seeding_density_unit select', function () {
            const $element = $(this);
            const label = $element.find('option:selected').html();
            $element.closest('.plant-density-abacus').find('.seeding-density-unit').html(label);
        });

        $(document).on('change keyup', '.plant-density-abacus .activity_plant_density_abaci_sampling_length_unit select', function () {
            const $element = $(this);
            const label = $element.find('option:selected').html();
            $element.closest('.plant-density-abacus').find('.sampling-length-unit').html(label);
        });

        $(document).on('cocoon:after-insert', '.plant-density-abacus #items-field', function () {
            $(this).closest('.plant-density-abacus').find('select').trigger('change');
        });

        $(document).on(
            'change keyup',
            '.inspection-calibration-scale .activity_inspection_calibration_scales_size_unit_name select',
            function () {
                const $element = $(this);
                const label = $element.find('option:selected').html();

                $element.closest('.inspection-calibration-scale').find('.scale-unit').html(label);
            }
        );

        $(document).on('cocoon:after-insert', '.inspection-calibration-scale #natures-field', function () {
            $(this)
                .closest('.inspection-calibration-scale')
                .find('.activity_inspection_calibration_scales_size_unit_name select')
                .trigger('change');
        });
    });
})(ekylibre, jQuery);
