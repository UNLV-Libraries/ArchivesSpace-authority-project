//= require linker 
$(function () {

  var init = function () {
    $("#overlay-dropdown .linker:not(.initialised)").linker();
    
    $('.overlay-form .btn-cancel').on('click', function () {
      $('.overlay-action').trigger("click");
    });

    // Override the default bootstrap dropdown behaviour here to
    // ensure that this modal stays open even when another modal is
    // opened within it.
    $(".overlay-action").on("click", function(event) {
      event.preventDefault();
      event.stopImmediatePropagation();

      if ($(this).attr('disabled')) {
        return;
      }

      if ($(".overlay-form")[0].style.display === "block") {
        // Hide it
        $(".overlay-form").css("display", "");
      } else {
        // Show it
        $(".overlay-form").css("display", "block");
      }
    });

    // Stop the modal from being hidden by clicks within the form
    $(".overlay-form").on("click", function(event) {
      event.stopPropagation();
    });


    $(".overlay-form .linker-wrapper .dropdown-toggle").on("click", function(event) {
      event.stopPropagation();
      $(this).parent().toggleClass("open");
    });


    $(".overlay-form .overlay-button").on("click", function(event) {
      var formvals = $(".overlay-form").serializeObject();
      
      if ( formvals["overlay[target]"] && !formvals["overlay[target][]"] ) {
        formvals["overlay[target][]"] = formvals["overlay[target]"]; 
      }
	  if ( formvals["overlay[victim]"] && !formvals["overlay[victim][]"] ) {
        formvals["overlay[victim][]"] = formvals["overlay[victim]"]; 
      }
      
      if (!formvals["overlay[target][]"] && !formvals["overlay[victim][]"]) {
        $(".missing-target-message", ".overlay-form").show();
        event.preventDefault();
        event.stopImmediatePropagation();
        return false;
      } else {
        $(".missing-target-message", ".overlay-form").hide();
        $(this).data("form-data", {"target": formvals["overlay[target][]"],
								   "victim": formvals["overlay[victim][]"]});
      }
    });
  };


  if ($('.overlay-form').length > 0) {
    init();
  } else {
    $(document).bind("loadedrecordform.aspace", init);
  }

});