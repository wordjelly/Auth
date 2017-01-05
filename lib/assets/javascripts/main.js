/****
ARGUMENTS
{
	form_id:{

		field_id:{
					
			validation_events: {"jquery_event" : true/false}
			
			validate_with: {validator_name: arg,...more validators} / function  

			on_success: framework_name / function 

			on_failure: framework_name / function

			do_before_validating: [list of ids to check if valid] / function

			do_after_validating: [list of ids to enable if this one is valid] / function
						
		},
		...more field ids
	},
	....more form ids
}

---------------------------------------

acceptable validator names for "validate_with"
================================================

format: email

required:

min-length: length

remote-url: url

should_equal: id_of_other_element

----------------------------------------

****/
function WJ_Validator(args,css_framework,log){
	
	this.args = args;
	this.two_binding_fields = {};
	this.log = log !== null ? log : true;
	this.logger = {};
	this.css_framework = css_framework;
	/***
	key -> field_id(without prefixed hash)
	value -> form_id(without prefixed hash)
	***/
	this.field_locs = {};
	
	/***
	a results object that holds the results of validation of all the fields.
	***/
	this.validation_results = {};	

	/****
	defaults for field definitions.
	****/

	this.validation_events_defaults = {
		"focus" : true	
	};



	var resolve_fields = function(def,e){
		if("field_array" in def){
			var arr = _(def["field_array"]).clone();
			arr.push(e.target.id);
			return arr;
		}
		else{
			return [e.target.id];
		}
	}

	

	/***
	****/
	var hide_invalid_label = function(id){
		var input = $("#" + id);
		var label = input.parent().find("label");
		label.attr("data-error","");
	}

	var hide_invalid_warning_on_bound_fields = function(e){
		var form_id = $("#" + e.target.id).parents('form').get(0).id;
		if(form_id){
			for(f in args[form_id]){
				_.each(args[form_id][f]["validate_with"],function(v){
					if("field_array" in v){
						if(f == e.target.id){
							
							_.each(v["field_array"],function(b){
								hide_invalid_label(b);
							});
						}
						else if(_.contains(v["field_array"],e.target.id)){
							
							hide_invalid_label(f);
						}
					}
				});
			};
		}
	}


	/*****
	the framework on_success and on_failure functions are passed the same 
	*****/
	this.frameworks = {
		"materialize":{
			on_success: function(res){
				_.each(resolve_fields(res["def"],res["event"]),function(name){
					var val = $("#" + name).val();
					var type = $("#" + name).attr("type");
					var label = $('label[for="'+ name +'"]');
		      		var input = $('#' + name);
		      		input.attr("class","valid");
					
				});
					
			},
			on_failure: function(res){
				_.each(resolve_fields(res["def"],res["event"]),function(name){
					var val = $("#" + name).val();
					var type = $("#" + name).attr("type");
					var label = $('label[for="'+ name +'"]');
			      	var input = $('#' + name);
			      	input.attr("class","invalid");
					input.attr("aria-invalid",true);
			      	label.attr("data-error",res["failure_message"]);
		      	})
			},
			on_load: function(){
				$(document).on("focusout",":input",function(e){
					if($(this).hasClass("invalid")){
						var label = $(this).parent().find("label");
						label.attr("data-error","");
						hide_invalid_warning_on_bound_fields(e);
					}
				});
			}
		}
	}

	this.validate_with_defaults = {

	};

	/****
	default on success function.
	this function is called only when all the validators for a given field have passed.

	ARGUMENTS:
	---------
	e -> the event which triggered the validation
	
	RETURNS:
	--------
	null

	****/
	this.on_success_defaults = function(res){

		if(css_framework !== null && (css_framework in _this.frameworks)){
			_this.frameworks[css_framework]["on_success"](res);
		}
	};

	/***
	default on failure function.
	
	ARGUMENTS:
	---------
	def[Array] -> contains the validation defintion and failure messages, for each validator for the field.(includes failed and successfull validation results.)
	e -> the event which triggered the validation.
	
	RETURNs:
	-----------
	null.

	***/
	this.on_failure_defaults = function(res){
		if(css_framework !== null && (css_framework in _this.frameworks)){
			_this.frameworks[css_framework]["on_failure"](res);
		}
	};

	this.do_before_validating_defaults = {
		
	};

	this.do_after_validating_defaults = {

	};

	this.field_defaults = {
		"validation_events" : this.validation_events_defaults,
		"validate_with" : this.validate_with_defaults,
		"on_success": this.on_success_defaults,
		"on_failure": this.on_failure_defaults,
		"do_before_validating" : this.do_before_validating_defaults,
		"do_after_validating" : this.do_after_validating_defaults
	};
	/***
	defaults end
	***/

	var default_formats = {
			email: /^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
	}

	/****
	ARGUMENTS FOR ANY VALIDATOR ARE THE SAME
	def -> the validator defintion(should have a key->value(format -> email), and a key-value(failure_message -> message))
	e -> the event which triggered the validation.

	RETURN:
	return true,or false.
	*****/
	
	this.validators = {
		/***
		@param[Object] def:
			format => email/regex/function
			failure_message => "whatever you want."
			skip_empty => true/false, defaults to true.
			args => arguments hash to pass to your custom function in case you are using one for the format.
		@return[Deferred Object]
		***/
		format: function(def,e){
			var result = $.Deferred();
			var field_value = get_field_attrs(e)["value"];
			//HANDLE EMPTY FIELD.
			if(!def["skip_empty"] && field_value.length == 0){
				
			}
			else if(field_value.length == 0){
				result.resolve({"is_valid" : true});
			}
			
		
			if(def["format"] in default_formats){
				//its a regex
				//run it against the value of the field.
				result.resolve({"is_valid" : default_formats[def["format"]].test(field_value)});
			}
			else if($.isFunction(def["format"])){
				//its a function
				//pass the field value insside.
				result.resolve({"is_valid" : def["format"](def,e)});
			}
			else{
				//trying to test something thats not in the default formats, and not a function, so returns invalid.
				result.resolve({"is_valid" : false});
			}
			return result;
		},
		/***
		@param[Object]:def 
		"required" => true/function
		"failure_message" => whatever you want.
		"args" => custom arguments hash to pass to your required function if you decide to use it.
		@return[Deferred Object]
		***/
		required: function(def,e){
			var result = $.Deferred();
			var field_value = get_field_attrs(e)["value"];
			if($.isFunction(def["required"])){
				result.resolve({"is_valid" : def["required"](def,e)});
			}
			result.resolve({"is_valid" : field_value.length > 0});
			return result;
		},
		/****
		@param[Object] def:
		"remote" => true/function,
		"ajax_settings" => function, the function accepts the def and the event.
		"args" => custom arguments hash to pass to your "remote" function or to your ajax settings function.
		@return[Promise object] 
		****/
		remote: function(def,e){
			var result = $.Deferred();
			if($.isFunction(def["remote"])){
				return result.resolve({"is_valid" : def["remote"](def,e)});
			}
			var ajax_settings = def["ajax_settings"](def,e);
			return $.ajax(ajax_settings);
		},
		min_length: function(def,e){
			console.log("came to min length validator");
		},
		max_length: function(def,e){
			console.log("came to max length validator");
		},
		/***
		def ->
		-should_be_equal => true/function
		-field_array => [Array], array of field ids whose values should all be equal.
		-args => object of arguments to pass to the custom function,
		e -> 
		-the event.
		***/
		should_be_equal: function(def,e){
			
			var result = $.Deferred();
			
			if($.isFunction(def["remote"])){
				return result.resolve({"is_valid" : def["remote"](def,e)});
			}
			else{
				if("field_array" in def){
					var values_arr = _.map(def["field_array"],function(t){
						return $("#" + t).val();
					});
					values_arr.push($("#" + e.target.id).val());
					return result.resolve({"is_valid" : _.uniq(values_arr).length == 1});
				}
				else{
					return result.resolve({"is_valid" : false});
				}				
			}
		}	
	}
	


	/****
	Arguments:
	click_event -> the event that triggered the validation.
	Returns:
	@type: the type of the field "text,radio,checkbox,select"
	@value: the value of the field
	****/
	var get_field_attrs = function(e){
		jquery_el = $("#" + e.target.id);
		return {"type":jquery_el.attr('type'), "value" : jquery_el.val(), "name" : jquery_el.attr('name')};
	}

	this.is_valid = function(res){
		var valid = false;
		if(_.isArray(res)){
			_.each(res,function(o){
				if(_.isObject(o)){
					if("is_valid" in o){
						valid = o["is_valid"];
					}
				}
			});

		}
		else{
			valid = res["is_valid"];
		}
		
		return valid;
	}

	/***
	e -> form submit event.
	***/
	this.show_invalid_errors = function(deferred_arr,ret_val,e){
		
		deferred_arr = _.flatten(deferred_arr);
		var ret_val = true;
		$.when.apply($,deferred_arr).done(function(){
			var failed_ids = [];
			var failures = _.filter(arguments,function(res,index){
				if(!_this.is_valid(res)){
					if(!(_.contains(failed_ids,deferred_arr[index]["event"].target.id))){
						deferred_arr[index]["field_object"]["on_failure"](	deferred_arr[index]);
						failed_ids.push(deferred_arr[index]["event"].target.id);
					}
					return true;
				}
			});
			var success = _.each(arguments,function(res,index){
				if(_this.is_valid(res) && (!(_.contains(failed_ids,deferred_arr[index]["event"].target.id)))){
					deferred_arr[index]["field_object"]["on_success"](deferred_arr[index]);
				}
			});
			if(_.size(failures) > 0)
 			{
 				
			}
			else{
				if(e){
					console.log("triggering submit");
					$(e.target).trigger("submit",{});
				}
			}
		});
	}
	this.register_handlers();
	var _this = this;

}

WJ_Validator.prototype = {
	constructor: WJ_Validator,
	default_failure_message: function(){
		return "This field is invalid";
	},
	validation_could_not_be_done_message: function(){
		return "server error";
	},
	register_handlers: function(){
		/***
		jquery_event => array_of_field_ids_to_watch_for_that_event
		***/
		var event_handlers = {};
		/***
		structure like:
		field_id => [[array_of_two_way_fields],validation_events_hash]
		***/
		var _this = this;

		_.each(Object.keys(_this.args),function(fo){
			
			/***
			the form hash.
			***/
			var form_obj = _this.args[fo];

			_.each(Object.keys(_this.args[fo]),function(f){
				

				var field_id = "#" + f;
				/***
				correlate the field id with the form id 
				key -> field id
				value -> form id
				***/	
				_this.field_locs[f] = fo;
				

				/***
				merge the defaults with the incoming field definition.
				use jquery extend.
				***/			
				var field_obj = $.extend(true,{},_this.field_defaults,form_obj[f]);


				//reassign the extended field object.
				_this.args[fo][f] = field_obj;


				for(jEvent in field_obj["validation_events"]){
					if(jEvent in event_handlers){
						event_handlers[jEvent].push(field_id);
					}
					else{
						event_handlers[jEvent] = [field_id];
					}
				}

				
				_.each(field_obj["validate_with"],function(r,i){
					if("field_array" in r){
						_this.two_binding_fields[f] = [field_obj["validate_with"][i]["field_array"],field_obj["validation_events"]];
					}
				});


			});
		});
		
		this.field_locs = _this.field_locs;
		this.args = _this.args;
		this.two_binding_fields = _this.two_binding_fields;
		
		/***
		the custom event is added here because we simulate custom event click in two way binding.
		***/
		if(event_handlers != ""){
			for(event in event_handlers){
				$(document).on(event + " custom",event_handlers[event].join(","),function(e,ret){
						if(ret){
							ret[e.target.id] =  _this.main(e);
						}
						else{
							_this.show_invalid_errors(_this.main(e),null,null);
						}
				});
			}
		}	


		
		/***
		what event should be used for two-way-binding-fields.
		whatever is the event for the root field.
		pick those key-value pairs from the validation event which are true, and then take only those keys and join by space
		***/
		for(ff in _this.two_binding_fields){
			$(document).on(Object.keys(_.pick(_this.two_binding_fields[ff][1],function(value,key,object){
				return value == true
			})).join(" "),_.map(_this.two_binding_fields[ff][0],function(n){return "#" + n;}).join(","),function(e){
				$("#"+ff).trigger("custom");
			});
		}

		/****
		form triggers
		****/

		/***
		on submitting the form, trigger the custom event on each field of the form object.
		***/
		_.each(Object.keys(_this.args),function(fo){
			
			//if the form has remote true, then bind only ajax:before
			//otherwise bind only submit.
			var event_name = "submit";
			if($("#" + fo).attr("data-remote")){
				event_name = "ajax:before";
			}
			$(document).on(event_name,"#" + fo,function(e,ret){
				var defs = [];
				var results = {};
				$(_.map(Object.keys(_this.args[fo]),function(k){
					return "#" + k;
				}).join(",")).trigger("custom",results);
				for(key in results){
					defs.push(results[key]);
				}
				if(!ret){
					e.preventDefault();
					e.stopPropagation();
					_this.show_invalid_errors(defs,true,e);
					return false;	
				}
			});
		});


		//if the frameworks have any specific things to be done on load, then do it here.
		this.frameworks[this.css_framework]["on_load"]();
		
	},
	/****
	given the field_id get its definition from the form definition.
	****/
	get_field_object: function(field_id){
		return this.args[this.field_locs[field_id]][field_id];
	},
	/***
	passes in click event.
	returns array of deferred objects.
	***/
	main: function(e){
		try{
			var field_object = this.get_field_object(e.target.id);
			//clear validation results.
			this.validation_results[e.target.id] = {};
			return this.validate_with(field_object,e);
		}
		catch(err){
			return null;
		}
	},
	/****	
	basically calls each validator specified and returns true or false
	finally returns true if all are true, otherwise false.
	****/
	validate_with: function(field_object,e){
		var deferred_results = [];
		var _this = this;	
		_.each(field_object["validate_with"],function(def){
			var validation_kv = _.pick(def, function(value, key, object) {
			  	return key in _this.validators;
			});
			if(_.isEmpty(validation_kv)){
				validation_kv = _.pick(def, function(value, key, object) {
				  	return $.isFunction(value);
				});
			}
			_.each(Object.keys(validation_kv),function(v){
				var is_valid = null;			
				if(v in _this.validators){
					is_valid = _this.validators[v](def,e);
				}
				else if($.isFunction(def[v])){
					is_valid = def[v](def,e);	
				}	
				if(is_valid!== null){
					var failure_message = def["failure_message"] ? def["failure_message"] : _this.default_failure_message;
					is_valid.fail(function(d){
						failure_message = _this.validation_could_not_be_done_message;
					});
					var g = $.extend({},is_valid,{"failure_message" : failure_message, "field_object" : field_object, "event": e, "def" : def});
					deferred_results.push(g);
				}
			});
		});
		return deferred_results;
	}
	
}