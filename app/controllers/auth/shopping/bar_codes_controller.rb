class Auth::Shopping::BarCodesController < Auth::Shopping::ShoppingController

	## for barcodes only SHOW and INDEX and NEW routes are defined.
	## only these actions need an authenticated user to be present for them to be executed.
    ## NEW CAN BE ACCESSED BY ANY USER ,NOT NECESSARILY AN AUTHENTICATED USER OR ANYTHING.
    CONDITIONS_FOR_TOKEN_AUTH = [:index,:show]
    TCONDITIONS = {:only => CONDITIONS_FOR_TOKEN_AUTH}
    ##this ensures api access to this controller.
    include Auth::Concerns::DeviseConcern
    include Auth::Concerns::TokenConcern
    before_filter :do_before_request , TCONDITIONS
    before_filter :is_admin_user, {:only => [:index]}

    def new

    end

    def index
        page_number = params[:page_number].nil? ? 1 : params[:page_number]
        page_size = params[:page_size].nil? ? 10 : params[:page_size]
        ## max page size.
        page_size = 50 if page_size > 50

        skips = page_size * (page_num - 1)

        @bar_codes = Auth::Shopping::BarCode.all.skip(skips).limit(page_size)


        respond_to do |format|

        end


    end

    ## then you pass in a parameter like that.
    ## if force_show is true, then it will 
    def show

        begin
    	   @bar_code = Auth::Shopping::BarCode.find(params[:id])
           @bar_code.assign_attributes(get_model_params)
    	rescue Mongoid::Errors::DocumentNotFound
           
            @bar_code = Auth::Shopping::BarCode.new
            @bar_code.errors.add(:_id,"not found")
        end
    	
    	@bar_code.set_assigned_object if (@bar_code.errors.full_messages.empty?)

    	respond_to do |format|
            format.js do 
              ## render a partial which will deal with all these eventualities.  
              render :partial => "show"
            end
    		format.html do 
                if get_model_params[:force_show]
    			    render 'auth/shopping/bar_codes/show'
                else
                    ## now let me first make a show view.
                    if @bar_code.errors.empty?
                        unless @bar_code.assigned_to_object.primary_link.blank?
                            
                            redirect_to @bar_code.assigned_to_object.primary_link
                        else
                            @bar_code.errors.add(:_id,"no primary link defined on the assigned object")
                            render 'auth/shopping/bar_codes/show'
                        end
                    else
                        render 'auth/shopping/bar_codes/show'
                    end
                end
    		end
    		format.json do 
               
                if get_model_params[:force_show]
                    
                    render :json => {bar_code: @bar_code}, status: 200
                else

                    if @bar_code.errors.empty?
                        if @bar_code.assigned_to_object
                			unless @bar_code.assigned_to_object.primary_link.blank?
                                ## it should have its primary link.
                                render :json => {redirect_to: @bar_code.assigned_to_object.primary_link}
                			else
                                @bar_code.errors.add(:_id,"no primary link defined on the assigned object")
                                render :json => {bar_code: @bar_code, errors: @bar_code.errors}, status: 422
                			end
                        else
                            render :json => {bar_code: @bar_code}, status: 200
                        end
                    else
                        render :json => {bar_code: @bar_code, errors: @bar_code.errors}, status: 422
                    end
                end
    		end
    	end
    end

    def permitted_params
    	params.permit({bar_code: [:bar_code_tag,:force_show,:go_to_next_step]}, :id, :page_number, :page_size)
    end

    def get_model_params
    	permitted_params.fetch(:bar_code,{})
    end

end