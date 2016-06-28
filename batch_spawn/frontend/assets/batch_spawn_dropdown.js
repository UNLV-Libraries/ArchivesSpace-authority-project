//= require linker 
$(function () {

  var init = function () {
    $("#batch-spawn-dropdown .linker:not(.initialised)").linker();
    
    $('.batch-spawn-form .btn-cancel').on('click', function () {
      $('.batch-spawn-action').trigger("click");
    });

    // Override the default bootstrap dropdown behaviour here to
    // ensure that this modal stays open even when another modal is
    // opened within it.
    $(".batch-spawn-action").on("click", function(event) {
      event.preventDefault();
      event.stopImmediatePropagation();

      if ($(this).attr('disabled')) {
        return;
      }

      if ($(".batch-spawn-form")[0].style.display === "block") {
        // Hide it
        $(".batch-spawn-form").css("display", "");
      } else {
        // Show it
        $(".batch-spawn-form").css("display", "block");
      }
    });

    // Stop the modal from being hidden by clicks within the form
    $(".batch-spawn-form").on("click", function(event) {
      event.stopPropagation();
    });


    $(".batch-spawn-form .linker-wrapper .dropdown-toggle").on("click", function(event) {
      event.stopPropagation();
      $(this).parent().toggleClass("open");
    });


    $(".batch-spawn-form .batch-spawn-button").on("click", function(event) {
      var formvals = $(".batch-spawn-form").serializeObject();
      
      if ( formvals["batch_spawn[target]"] && !formvals["batch_spawn[target][]"] ) {
        formvals["batch_spawn[target][]"] = formvals["batch_spawn[target]"]; 
      }
      
      if (!formvals["batch_spawn[target][]"]) {
        $(".missing-target-message", ".batch-spawn-form").show();
        event.preventDefault();
        event.stopImmediatePropagation();
        return false;
      } else {
        $(".missing-target-message", ".batch-spawn-form").hide();
        $(this).data("form-data", {"target": formvals["batch_spawn[target][]"]});
      }
    });
  };


  if ($('.batch-spawn-form').length > 0) {
    init();
  } else {
    $(document).bind("loadedrecordform.aspace", init);
  }

});