$(function() {
  console.log("Silence");
  var $spawnForm = $("#batch_spawn");
  console.log($spawnForm);
  var $results = $("#results");
  
  
  var renderResults = function(json) {
	  
    decorateResults(json);
	console.log(json);
	console.log("EHER");
	$results.empty();
    $results.append(AS.renderTemplate("template_batch_spawn_result_summary", json));
    $.each(json.records, function(i, record) {
      var $result = $(AS.renderTemplate("template_lcnaf_result", {record: record, selected: selected_lccns}));
      if (selected_lccns[record.lccn]) {
        $(".alert-success", $result).removeClass("hide");
      } else {
        $("button", $result).removeClass("hide");
      }
      $results.append($result);

    });
    $results.append(AS.renderTemplate("template_lcnaf_pagination", json));
    $('pre code', $results).each(function(i, e) {hljs.highlightBlock(e)});
  }
  
  
  var decorateResults = function(resultsJson) {
    //stringify the query here so templates don't need
    //to worry about SRU vs OpenSearch
    if (typeof(resultsJson.query) === 'string') {
      // just use sru's family_name as the 
      // sole openSearch field
      resultsJson.queryString = '?family_name=' + resultsJson.query + '&lcnaf_service=' + $("input[name='lcnaf_service']:checked").val();
    } else {
       if ( resultsJson.query.query['local.GivenName'] === undefined ) {
        resultsJson.query.query['local.GivenName'] = "";  
      }
      resultsJson.queryString = '?family_name=' + resultsJson.query.query['local.FamilyName'] + '&given_name=' + resultsJson.query.query['local.GivenName'] + '&lcnaf_service=' + $("input[name='lcnaf_service']:checked").val();
    }
  }
  
  $spawnForm.ajaxSubmit({
    dataType: "json",
    type: "POST",
    beforeSubmit: function() {
      if (!$("#family-name-search-query", $spawnForm).val()) {
          return false;
      }

	console.log("EHERsdfsdf");
      $(".btn", $spawnForm).attr("disabled", "disabled").addClass("disabled").addClass("busy");
    },
    success: function(json) {
	console.log("SHOW NW");
      renderResults(json);
    },
    error: function(err) {
	console.log("EHasER");
      $(".btn", $spawnForm).removeAttr("disabled").removeClass("disabled").removeClass("busy");
      var errBody = err.hasOwnProperty("responseText") ? err.responseText.replace(/\n/g, "") : "<pre>" + JSON.stringify(err) + "</pre>";
      AS.openQuickModal(AS.renderTemplate("template_lcnaf_search_error_title"), JSON.stringify(errBody));
    }
  });
  
  
  
})