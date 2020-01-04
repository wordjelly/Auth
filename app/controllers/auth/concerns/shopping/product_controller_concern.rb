module Auth::Concerns::Shopping::ProductControllerConcern

  extend ActiveSupport::Concern

  included do
    
    include Auth::Shopping::Products::ProductsHelper

  end

  def initialize_vars
    #puts "came to initialize vars"
  	instantiate_shopping_classes
    @auth_shopping_product_params = permitted_params.fetch(:product,{})
    #puts "product params:"
    #puts @auth_shopping_product_params.to_s
    #puts "current signed in resource: #{current_signed_in_resource}"
    @auth_shopping_product = params[:id] ? @auth_shopping_product_class.find_self(params[:id],current_signed_in_resource) : @auth_shopping_product_class.new(@auth_shopping_product_params)
  end
  

  def create
    check_for_create(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product,{:owner_is_current_resource => true})
    @auth_shopping_product.save
    respond_with @auth_shopping_product
  end

  def update
    check_for_update(@auth_shopping_product)
    @auth_shopping_product = add_owner_and_signed_in_resource(@auth_shopping_product,{:owner_is_current_resource => true})
    @auth_shopping_product.assign_attributes(@auth_shopping_product_params)
    @auth_shopping_product.save
    puts @auth_shopping_product.errors.full_messages
    respond_with @auth_shopping_product
    
  end

  ## index can accept product bundle as a parameter.
  ## like only show the bundles.
  ## if we want to show that then?
  ## okay so let us add that bundle parameter.
  def index
    instantiate_shopping_classes
    if params[:query_string]
      if params[:autocomplete_bundle_name]
        ## in this case, the autocomplete query has to be done.
        args = {:query_string => params[:query_string]}
        query = Auth::Search::Main.es_six_finalize_search_query_clause(args)
        Auth.configuration.product_class.constantize.bundle_autocomplete_aggregation(query)
        @auth_shopping_results = Auth.configuration.product_class.constantize.es.search(query,{:wrapper => :load}).results
      end
    elsif params[:group_by_bundles]
      results = Auth.configuration.product_class.constantize.collection.aggregate([
        {
          "$match" => {
            "bundle_name" => {
              "$exists" => true
            }
          }
        },
        {
          "$group" => {
            "_id" => "$bundle_name",
            "products" => {
              "$push" => "$$ROOT"
            }
          }
        }
      ])
      ## we need them keyed by the bundle name.
      @products_grouped_by_bundle = {}
      @auth_shopping_products = []
      results.each do |result|
        bundle_name = result["_id"]
        products = result["products"].map{|c| c = Auth.configuration.product_class.constantize.new(c)}
        @products_grouped_by_bundle[bundle_name] = products
      end
    else
      @auth_shopping_products = @auth_shopping_product_class.all
    end
        
    

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


  def permitted_params 
    bar_code_params = [:name,:price,:bundle_name,:create_from_product_id] + Auth::Shopping::BarCode.allow_params
  	params.permit({:product => bar_code_params},:id)
  end

  ## so give a button called create product from this product
  ## it should be a partial with a form.

end

