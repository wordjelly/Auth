function navbar_search(query_string){
		$.get(
		{url : window.location.origin + "/search/authenticated_user_search",
		 data: { 
		    query: 
		    {query_string: query_string}
		 },
		 beforeSend: function(){
		 	//clear_search_results();
		 },
		 success : function( data ) {},
		 dataType : "script"
		});
}


$(document).on('keyup', '#search',function(event){
	navbar_search($(this).val());
});

/* Clear the search result if focus out from the title. */
$(document).on('click','body',function(event){
	if(event.target.id === 'search'){
		
	}
	else if(event.target.id === 'search_title'){
		
	}
	else{
		$(".search_result").remove();
	}
});

/* Highlight Autocomplete Matching Text */
var highlight = function() {
	
	var strings = $("#search").val().split(/\s+/);
	$(".search_result").mark(strings);

	/**
	$.each(strings,function(index,string){
		
		$(".search_result").each(function () {
		
		// this is not going to be easy.
		var matchStart = $(this).html().toLowerCase().indexOf("" + string.toLowerCase() + "");
		
		var matchEnd = matchStart + string.length - 1;
		
		var beforeMatch = $(this).html().slice(0, matchStart);
		var matchText = $(this).html().slice(matchStart, matchEnd + 1);
		var afterMatch = $(this).html().slice(matchEnd + 1);
		$(this).html(beforeMatch + "<span class='yellow'>" + matchText + "</span>" + afterMatch);
		});
	});
	**/	
}
