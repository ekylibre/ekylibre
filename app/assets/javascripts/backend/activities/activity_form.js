(function (E, $) {
    const varietyService = new E.VarietyService();
    const masterProductionService = new E.MasterProductionNatureService();

    class ActivityForm {
        constructor($formElement) {
            this.$formElement = $formElement;

            this.$productionNatureControl = this.$formElement.find('.control-group.activity_production_nature:first').first();
            this.$productionNatureInput = this.$formElement.find('#activity_production_nature_id').first();
            this.$productionCycleInput = this.$formElement.find("input[type=radio][name='activity[production_cycle]']").first();

            this.fpStartedOn = this.$formElement.find('input#activity_production_started_on').get(0)._flatpickr;
            this.fpStoppedOn = this.$formElement.find('input#activity_production_stopped_on').get(0)._flatpickr;
        }

        init() {
            if (this.$productionNatureInput.val() !== '') {
                this.setProductionCycleDisabling(true);
            }

            this.$productionCycleInput.on('change', event => {
                if (event.target.value === 'annual') {
                    this.resetPerenialInputs();
                }
            });

            this.$productionNatureInput.on('selector:change', (_event, _selectedElement, was_initializing) => {
                this.hideHint();
                if (!was_initializing) {
                    this.onProductionNatureChange();
                }
            });
        }

        onProductionNatureChange() {
            this.reset();

            const productionNaturesId = this.$productionNatureInput.selector('value');
            masterProductionService
                .get(productionNaturesId)
                .then(productionNature => {
                    if (productionNature.started_on && productionNature.stopped_on) {
                        this.setProductionPeriod(productionNature.started_on, productionNature.stopped_on, productionNature.start);
                    }

                    if (productionNature.specie) {
                        this._updateSelectWithFamilyVarieties(productionNature.specie);
                    }

                    if (productionNature.start_state_of_production && productionNature.start_state_of_production.length > 0) {
                        this.setProductionCycle('perennial');
                        this.setSelectOptions(
                            'select#activity_start_state_of_production_year',
                            optionsForSelect(productionNature.start_state_of_production, {
                                label: e => e.label,
                                value: e => e.year,
                                selected: e => e['default']
                            })
                        );
                    } else {
                        this.setProductionCycle('annual');
                        $('select#activity_start_state_of_production_year').empty();
                    }

                    if (productionNature.life_duration) {
                        this.setLifeDuration(productionNature.life_duration);
                    }
                });
        }

        reset() {
            this.resetPerenialInputs();
            this.setProductionPeriod();
            this.setLifeDuration();
            this.resetVarieties();
            this.setSelectOptions('select#activity_start_state_of_production_year');
            this.setProductionCycleDisabling(false);
        }

        resetVarieties() {
            const familyCultivationVariety = $('select#activity_cultivation_variety').data('family-cultivation-variety');
            this._updateSelectWithFamilyVarieties(familyCultivationVariety);
        }

        _updateSelectWithFamilyVarieties(familyCultivationVariety) {
            varietyService.selection(familyCultivationVariety)
                          .then(varietySelection => {
                              if (varietySelection.length >= 1) {
                                  this.setSelectOptions(
                                      'select#activity_cultivation_variety',
                                      optionsForSelect(varietySelection, {
                                          label: e => e.label,
                                          value: e => e.referenceName
                                      })
                                  );
                              }
                          });
        }

        resetPerenialInputs() {
            $('input#activity_life_duration').val(null);
            $('select#activity_start_state_of_production_year').val(null);
        }

        hideHint() {
            const $hint = this.$productionNatureControl.find('p.help-block');
            $hint.hide();
        }

        setProductionPeriod(startedOn, stoppedOn, start) {
            this.fpStartedOn.setDate(startedOn);
            this.fpStoppedOn.setDate(stoppedOn);
            $('select#activity_production_campaign').val(start);
        }

        setProductionCycle(type) {
            const $radioButton = $('#activity_production_cycle_' + type);
            if (!$radioButton.prop('checked')) {
                $radioButton.prop('checked', true).trigger('change');
            }

            this.setProductionCycleDisabling(true);
        }

        setProductionCycleDisabling(value) {
            let $radioButton;

            if (value) {
                $radioButton = $('[id^=activity_production_cycle]:not(:checked)');
            } else {
                $radioButton = $('[id^=activity_production_cycle]');
            }

            $radioButton.attr('disabled', value);
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
        const {label, value, selected = () => false} = config;

        return options.map(option => {
            return $('<option>').html(label(option))
                                .attr('value', value(option))
                                .attr('selected', selected(option));
        });
    }

    function initForm() {
        const $formElement = $('form#new_activity,form[id^=edit_activity]');
        if ($formElement.length === 0 || $('select#activity_family').val() === '') {
            return;
        }

        new ActivityForm($formElement).init();
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
