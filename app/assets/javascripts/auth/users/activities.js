/****
makes ajax call for activities collection.
@param params[Object]: Should be a hash with the following keys =======>

@param from[Integer]: timestamp from when to get_activities
@param to[Integer]: timestamp upto where to get_activities, optionally can be left blank in which case defaults server side to current time.
@param attributes[Array]: the activity attributes desired.
@param user_id[String]: the id of the user for which we need activities
****/
var get_activities = function(params){
	$.get( "activities/get_activities",params).done(function(){
			console.log("activity data returned:");
			console.log(data);
	});
}
