function navbar_search(query_string){
		$.get(
		{url : window.location.origin + "/search/authenticated_user_search",
		 data: { 
		    query: 
		    {query_string: query_string}
		 },
		 beforeSend: function(){
		 	clear_search_results();
		 },
		 success : function( data ) {},
		 dataType : "script"
		});
}


$(document).on('keyup', '#search',function(event){
	console.log("the length is:");
	console.log($(this).val().length);
	if( $(this).val().length === 0 ){
		clear_search_results()
	}
	else{
		navbar_search($(this).val());
	}
});

var clear_search_results = function(){
	$("#navbar_search_results").html("");;
}

/***
when search is empty, clear the search results.
when new search key is pressed, clear the older search results.
when focus is not on the search bar, then clear the search results.
****/