//= require linker 
$(function () {

  var init = function () {
    $("#batch-spawn-dropdown .linker:not(.initialised)").linker();
    
    $(".batch-spawn-form .linker-wrapper .dropdown-toggle").on("click", function(event) {
      event.stopPropagation();
      $(this).parent().toggleClass("open");
    });


    $("button").on("click", function(event) {
		console.log("HERE")
		
      var formvals = $(".batch-spawn-form").serializeObject();
      
		console.log(formvals)
      if ( formvals["batch_spawn[target]"] && !formvals["batch_spawn[target][]"] ) {
        formvals["batch_spawn[target][]"] = formvals["batch_spawn[target]"]; 
      }
      
      if (!formvals["batch_spawn[target][]"]) {
        $(".missing-target-message", ".batch-spawn-form").show();
        event.preventDefault();
        event.stopImmediatePropagation();
        return false;
      } else {
		console.log("FA")
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