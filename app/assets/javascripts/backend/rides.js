(function (E) {
    class RideGroups {
        constructor(element) {
            this.list = element;
            this.listSelectorInputs = element.querySelectorAll('input[data-list-selector]');
            this.interventionRequestBtn = element.parentElement.querySelector('#intervention-request');
            this.interventionRecordBtn = element.parentElement.querySelector('#new-intervention-rides');
            this.interventionRequestUrl = this.interventionRequestBtn.href;
            this.interventionRecordUrl = this.interventionRecordBtn.href;
        }

        init() {
            this.listSelectorInputs.forEach((input) => {
                input.addEventListener('change', () => {
                    setTimeout(() => {
                        const selectedIds = this.selectedIds;
                        this.handleBtnsDisabling(selectedIds);
                        this.updateBtnsHref(selectedIds);
                    }, 300);
                });
            });
        }

        handleBtnsDisabling(ids) {
            const disabled = !ids.length;
            this.interventionRequestBtn.classList.toggle('disabled', !!disabled);
            this.interventionRecordBtn.classList.toggle('disabled', !!disabled);
        }

        updateBtnsHref(ids) {
            const requestUrl = new URL(this.interventionRequestUrl);
            if (ids.length > 0) {
                ids.map((id) => requestUrl.searchParams.append('ride_ids[]', id));
            }
            this.interventionRequestBtn.setAttribute('href', requestUrl);


            const reccordUrl = new URL(this.interventionRecordUrl);
            if (ids.length > 0) {
                ids.map((id) => reccordUrl.searchParams.append('ride_ids[]', id));
            }
            this.interventionRecordBtn.setAttribute('href', reccordUrl);
        }

        get selectedIds() {
            return [...this.listSelectorInputs]
                .filter((input) => input.checked && input.dataset.listSelector != 'all')
                .map((input) => input.dataset.listSelector);
        }
    }

    let disabledRideAffectedSelector = function() {
        const rideAffected = document.querySelectorAll('.affected > .list-selector > input')
        rideAffected.forEach(function(ride) {
            ride.setAttribute("disabled", true)
        })
    };

    let addColorOnRidesList = function(name, color) {
        let title = document.querySelector(`[title=${name}]`);
        title.style.cssText = 'display: flex; align-items: center;'
        let html = `<div style='background-color: ${color}; height: 10px; width: 10px; border-radius: 50px; margin-right: 7px;'></div>`
        title.insertAdjacentHTML('afterbegin', html)
    }

    let loadRidesColorAfterMap = function() {
        const map = $("[data-visualization]").visualization('instance').map
        map.on('async-layers-loaded', function(){
            const getValuesofTargets = Object.values(map._targets)
            const getRides = getValuesofTargets.filter(target => target.options.rideSet == true)
            const ridesData = getRides.map((ride) => { return {name: ride.options.label, color: ride.options.color[0]} } )

            // Test compare ride list and ride legend
            let ridesListNumber = selectRidesOnRideList();
            const ridesDataToSelect = ridesData.filter(ride => ridesListNumber.includes(ride.name) == true)

            ridesDataToSelect.forEach(function(ride){
                addColorOnRidesList(ride.name, ride.color);
            })
        })
    }

    let reloadRidesColorAfterClicOnActiveList = function() {
        $(document).on('list:page:change', function(){  
            disabledRideAffectedSelector();
        
            let ridesListNumber = selectRidesOnRideList();

            ridesListNumber.forEach(function(ride) {
                let setLegendRideNameId = `legend-${ride.toLowerCase()}`
                let legendRideId = document.querySelector(`#${setLegendRideNameId}`);
                let rideLengendColor = legendRideId.querySelector('.leaflet-categories-sample').style.backgroundColor

                addColorOnRidesList(ride, rideLengendColor);
            })
        })
    }

    let selectRidesOnRideList = function() {
        const ridesNumber = []
        const rideList = document.querySelector('#rides-list')
        const ridesTitle = rideList.querySelectorAll('[id] > td.ride-title')
        ridesTitle.forEach(function(ride) {ridesNumber.push(ride.title)})

        return ridesNumber
    }

    E.onDomReady(function () {
        const element = document.querySelector('#rides-list');
        if (element !== null) {
            new RideGroups(element).init();
            disabledRideAffectedSelector();
            loadRidesColorAfterMap();
            reloadRidesColorAfterClicOnActiveList();
        }
    });


    E.onDomReady(function () {
      const button = document.querySelector('#intervention-request');
      if (button !== null){
        button.addEventListener('click', function (event) {
          const title = this.dataset.modalTitle;
          event.preventDefault();
          E.Dialog.open(this.href, {
              title,
              success: (response) => {
                  eval(response.data);
              },
          });
        });
      }
    });

  
})(ekylibre);
