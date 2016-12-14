/***
the materialize css
'ready' callback -> after_open

the materialize css 
'complete' callback -> after_close

before_open -> fires before the modal even shows.

before_close -> fires before the close begins.
***/
(function($){

	var _stack = 0,
    _lastID = 0,
    _generateID = function() {
      _lastID++;
      return 'materialize-lean-overlay-' + _lastID;
    };

    $.fn.clear_modal_error_message = function(){
	   $(".modal").find(".error_notification").hide();
	   $(".modal").find(".error_message").html("");
	}

    $.fn.openModal = function(options){

    	
    	
    	var defaults = {
		        opacity: 0.5,
		        in_duration: 350,
		        out_duration: 250,
		        before_open: function(){return true},
		        after_open: function(){},
		        dismissible: true,
		        starting_top: '4%'
		      },
    	should_open = true;

    	// Override defaults
		options = $.extend(defaults, options);

    	if(options.before_open != null && typeof(options.before_open === "function")){
    		should_open = options["before_open"](options);
    	}
    	/****
    	main funciton --------------starts----------------------
    	*****/
    	if(should_open){
	    	$('body').css('overflow', 'hidden');

		      
		      var overlayID = _generateID(),
		      $modal = $(this),

		      $overlay = $('<div class="lean-overlay"></div>'),
		      lStack = (++_stack);


		      // Store a reference of the overlay
		      $overlay.attr('id', overlayID).css('z-index', 1000 + lStack * 2);
		      $modal.data('overlay-id', overlayID).css('z-index', 1000 + lStack * 2 + 1);

		      $("body").append($overlay);

		      

		      if (options.dismissible) {
		        $overlay.click(function() {
		          $modal.closeModal(options);
		        });
		        // Return on ESC
		        $(document).on('keyup.leanModal' + overlayID, function(e) {
		          if (e.keyCode === 27) {   // ESC key
		            $modal.closeModal(options);
		          }
		        });
		      }

		      $modal.find(".modal-close").on('click.close', function(e) {
		        $modal.closeModal(options);
		      });

		      $overlay.css({ display : "block", opacity : 0 });

		      $modal.css({
		        display : "block",
		        opacity: 0
		      });

		    
		      $overlay.velocity({opacity: options.opacity}, {duration: options.in_duration, queue: false, ease: "easeOutCubic"});

		     
		      $modal.data('associated-overlay', $overlay[0]);

		      // Define Bottom Sheet animation
		      if ($modal.hasClass('bottom-sheet')) {
		        $modal.velocity({bottom: "0", opacity: 1}, {
		          duration: options.in_duration,
		          queue: false,
		          ease: "easeOutCubic",
		          // Handle modal ready callback
		          complete : function(){
		          	if(options.after_open != null && typeof(options.after_open === "function")){
			    		options["after_open"](options);
			    	}
		          }
		        });
		        
		      }
		      else {
		      	
		        $.Velocity.hook($modal, "scaleX", 0.7);
		        $modal.css({ top: options.starting_top });
		        $modal.velocity({top: "10%", opacity: 1, scaleX: '1'}, {
		          duration: options.in_duration,
		          queue: false,
		          ease: "easeOutCubic",
		          // Handle modal ready callback
		          complete : function(){
		          	if(options.after_open != null && typeof(options.after_open === "function")){
			    		options["after_open"](options);
			    	}
		          }
		        });
		      }
	    }
    	
    };



    $.fn.closeModal = function(options){

    	  
	      var defaults = {
	        out_duration: 250,
	        complete: undefined,
	        before_close: function(){return true},
		    after_close: function(){},
	      },

	      $modal = $(this),
	      overlayID = $modal.data('overlay-id'),
	      $overlay = $('#' + overlayID);


	      

	      options = $.extend(defaults, options);

	      var should_close = true
	      if(options.before_close != null && typeof(options.before_close === "function")){
    		should_close = options["before_close"](options);
    	  }


    	  if(should_close){
	      // Disable scrolling
	      $('body').css('overflow', '');

	      $modal.find('.modal-close').off('click.close');
	      $(document).off('keyup.leanModal' + overlayID);

	      $overlay.velocity( { opacity: 0}, {duration: options.out_duration, queue: false, ease: "easeOutQuart"});


	      // Define Bottom Sheet animation
	      if ($modal.hasClass('bottom-sheet')) {
	        $modal.velocity({bottom: "-100%", opacity: 0}, {
	          duration: options.out_duration,
	          queue: false,
	          ease: "easeOutCubic",
	          // Handle modal ready callback

	          complete: function() {
	          	
	            $overlay.css({display:"none"});	           
	            $overlay.remove();
	            _stack--;
	          }
	        });
	      }
	      else {
	        $modal.velocity(
	          { top: options.starting_top, opacity: 0, scaleX: 0.7}, {
	          duration: options.out_duration,
	          complete: function() {
	              $(this).css('display', 'none');
	              // Call complete callback
	              if(options.after_close != null && typeof(options.after_close === "function")){
			    		options["after_close"](options);
			    		$modal.clear_modal_error_message();
			      }
	              $overlay.remove();
	              _stack--;
	            }
	          }
	        );
	      }
	    
	    }
    }	

    


    $.fn.leanModal = function(option){

      return this.each(function() {

        var defaults = {
          starting_top: '4%'
        },
        // Override defaults
        options = $.extend(defaults, option);
        $(this).click(function(e) {

       	  var modal_id = $(this).attr("href") || '#' + $(this).data('target');
       	  
          if(!$(e.target).hasClass("modal-close") && typeof modal_id !== 'undefined' && modal_id != "#undefined"){
	          options.starting_top = ($(this).offset().top - $(window).scrollTop()) /1.15;
	          options.opener_element = $(this);
	          options.opener_id = $(this).attr("id");
	          options.event = e;

	          $(modal_id).openModal(options);
	          e.preventDefault();
      	  }
        }); // done set on click
      }); // done return
    }
}(jQuery));

