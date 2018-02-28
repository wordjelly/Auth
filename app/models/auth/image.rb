class Auth::Image

  include Mongoid::Document
  include Auth::Concerns::OwnerConcern


  ###########################################################
  ##
  ##
  ##
  ## CLASS METHODS
  ##
  ##
  ## 
  ###########################################################
  ## the parent id is the id of the object in which the image is uploaded.
  ## it need not exist. but has to be a valid bson object id.
  def self.permitted_params
    puts "permitted params are:"
    puts "tehse."
    [{:image => [:parent_id,:parent_class]},:id]
  end



  ###########################################################
  ##
  ##
  ##
  ## ATTRIBUTES
  ##
  ##
  ##
  ###########################################################  
  field :parent_id, type: String
  field :parent_class, type: String
  attr_accessor :signed_request
   


  ###########################################################
  ##
  ##
  ## VALIDATIONS
  ##
  ##
  ###########################################################
  validates :parent_id, presence: true
  validates :parent_class, presence: true
  validate :parent_id_is_valid_bson


  ###########################################################
  ##
  ##
  ## CALLBACKS
  ##
  ##
  ###########################################################
  before_save do |document|
    document.signed_request = get_signed_request
  end


  ###########################################################
  ##
  ##
  ## CUSTOM VALIDATION DEFS.
  ##
  ##
  ###########################################################
  def parent_id_is_valid_bson
  	begin
  		BSON::ObjectId.from_string(self.parent_id)
  	rescue
  		self.errors.add(:parent_id, "the parent id is not valid")
  	end	
  end

  ############################################################
  ##
  ##
  ## OTHER CUSTOM DEFS.
  ##
  ##
  ############################################################
  def get_signed_request

    Cloudinary::Utils.sign_request({:public_id => self.id.to_s,:timestamp=>Time.now.to_i, :callback => "http://widget.cloudinary.com/cloudinary_cors.html"}, :options=>{:api_key=>Cloudinary.config.api_key, :api_secret=>Cloudinary.config.api_secret})

  end

  def verify_signature_from_webhook

  end

end
