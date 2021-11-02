(function (E, $) {

  E.onDomReady(function() {
    E.mattersMerger = new MattersMerger();
  });

  class MattersMerger{
    constructor() {
      this.selectedMatters = [];
      this.handleButtonClick();
    }

    handleMergeButtonClick(){
      $(document).on("click", ".merge-matter-btn", (e) => {
        this.selected = [];
      })
    };

    handleButtonClick(){
      $(document).on("click", "#matters-list td > input[data-list-selector]", (e) => {
        if (e.target.checked){
          this.selectedMatters.push(e.target.value);
        } else {
          var index = this.selectedMatters.indexOf(e.target.value);
          this.selectedMatters.splice(index, 1);
        }
        if (this.selectedMatters.length > 1) {
          $.ajax('/backend/receptions/mergeable_matters', {
            type: 'get',
            data: {
              "selected": this.selectedMatters
            },
            success: ((data) => {
              if (data){
                var url = `/backend/receptions/merge_matters?id=${this.selectedMatters}`
                $('.merge-matter-btn').attr('href', url)
                $('.merge-matter-div').show();
              } else {
                $('.merge-matter-div').hide();
              }
            }),
            dataType: 'json'
          });
        } else{
          $('.merge-matter-div').hide();
        }
      });
    }
  }
  E.MattersMerger = MattersMerger;
})(ekylibre, jQuery);