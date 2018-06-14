module Auth::Concerns::Shopping::ProductControllerConcern

  extend ActiveSupport::Concern

  included do
    
    include Auth::Shopping::Products::ProductsHelper

  end

  def initialize_vars
    puts "came to initialize vars"
  	instantiate_shopping_classes
    @auth_shopping_product_params = permitted_params.fetch(:product,{})
    puts "current signed in resource: #{current_signed_in_resource}"
    @auth_shopping_product = params[:id] ? @auth_shopping_product_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_product_class.new(@auth_shopping_product_params)
  end

  

  def create
    check_for_create(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product,{:owner_is_current_resource => true})
    #puts "this is the auth shopping product"
    puts @auth_shopping_product.embedded_document
    puts @auth_shopping_product.embedded_document_path
  	@auth_shopping_product.send("#{@auth_shopping_product.embedded_document_path}=",@auth_shopping_product.embedded_document) if (@auth_shopping_product.embedded_document && @auth_shopping_product.embedded_document_path)
    @auth_shopping_product.save
    respond_with @auth_shopping_product
    
  end

  def update
    check_for_update(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product,{:owner_is_current_resource => true})
    @auth_shopping_product.assign_attributes(@auth_shopping_product_params)

    ## assigns the embedded document to the provided path. 
    if @auth_shopping_product.embedded_document_path
      curr_element = nil
      total_els = @auth_shopping_product.embedded_document_path.split(".").size
      @auth_shopping_product.embedded_document_path.split(".").each_with_index {|path,key|
        if key == (total_els - 1)
          if curr_element.nil?
            @auth_shopping_product.send(path + "=",@auth_shopping_product.embedded_document)
          else
            curr_element.send(path + "=",@auth_shopping_product.embedded_document) if (path =~ /[a-z]+/)
            curr_element.send(:[]=,path.to_i,@auth_shopping_product.embedded_document) if (path =~ /\d+/)
          end
        else  
          if curr_element.nil?
            curr_element = @auth_shopping_product.send(path)
          else
            curr_element = curr_element.send(path) if (path =~ /[a-z]+/)
            curr_element = curr_element[path.to_i] if path=~/\d+/
          end
        end
      }
    end
    
    ## prune nil elements.
    ## at all levels.

    @auth_shopping_product.save
    respond_with @auth_shopping_product
    
  end

  def index
    instantiate_shopping_classes
    @auth_shopping_products = @auth_shopping_product_class.all
  end

  def show
    instantiate_shopping_classes
    @auth_shopping_product = @auth_shopping_product_class.find(params[:id])
    ## will render show.json.erb if its a json request.
  end

  def destroy
    check_for_destroy(@auth_shopping_product)
    @auth_shopping_product.delete
    respond_with @auth_shopping_product
  end

  def new
    
  end

  def edit

  end

  ## so now two additional keys get added
  ## one -> embedded_document_path
  ## two -> embedded_document.
  def permitted_params
    ## we just keep the embedded_document_path
  	pr = params.permit({:product => [:name,:price]})
    pr = pr.deep_merge({:product => { :embedded_document_path => params[:product][:embedded_document_path], :embedded_document => params[:product][:embedded_document]}})
    pr
  end

end

