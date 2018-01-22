function navbar_search(query_string){
		$.get(
		{url : window.location.origin + "/search/authenticated_user_search",
		 data: { 
		    query: 
		    {query_string: query_string}
		 },
		 success : function( data ) {},
		 dataType : "script"
		});
}


$(document).on('keyup', '#search',function(event){
	console.log("keyup detected");
	navbar_search("cobas");
});