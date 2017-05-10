$(function() {
	var $spawnForm = $("#spawn");
	var $results = $("#results");
	
	var renderResults = function(json) {
		var i = 0;//title counter 
		$results.empty();
		$.each(json.spawn.target, function(i, spawn) {
			var $result = $(AS.renderTemplate("template_spawn_result", {spawn: spawn.split('/').pop(), title: json.titles.title[i]}));
			i++; //increment title counter
			$results.append($result);

		});
  };
  
  $spawnForm.ajaxForm({
    dataType: "json",
    type: "POST",
    beforeSubmit: function(arr,$form,options) {
		var titles = [];
		var resolve;
		delete arr[1]; //Delete Lock version
		for (var i in arr) {
			//Delete Resolved
			if(arr[i].name == "spawn[_resolved][]"){
				resolve = JSON.parse(arr[i].value);
				arr.push({name: 'titles[title][]', value: resolve.title});
				delete arr[i];
			}
		}
      $(".btn", $spawnForm).attr("disabled", "disabled").addClass("disabled").addClass("busy");
    },
    success: function(json) {
      $(".btn", $spawnForm).removeAttr("disabled").removeClass("disabled").removeClass("busy");
	  console.log(json);
      renderResults(json);
    },
    error: function(err) {
      $(".btn", $spawnForm).removeAttr("disabled").removeClass("disabled").removeClass("busy");
      var errBody = err.hasOwnProperty("responseText") ? err.responseText.replace(/\n/g, "") : "<pre>Too many accessions </pre>";
	  
	 console.log(err);
      AS.openQuickModal(AS.renderTemplate("template_spawn_search_error_title"), JSON.stringify(errBody));
    }
  });
})