class Auth::Image

  ## cloudinary link to show android app that signs request
  ## https://github.com/cloudinary/cloudinary_android/tree/master/sample-signed

  include Mongoid::Document
  include Auth::Concerns::OwnerConcern

  ## now what about transformations ?

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
    [{:image => [:_id,:parent_id,:parent_class,:active,:timestamp,:public_id,:custom_coordinates]},:id]
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
  field :active, type: Boolean, default: true  
  field :custom_coordinates, type: String
  attr_accessor :signed_request
  attr_accessor :timestamp
  attr_accessor :public_id
   


  ###########################################################
  ##
  ##
  ## VALIDATIONS
  ##
  ##
  ###########################################################
  validates :parent_id, presence: true
  validates :parent_class, presence: true
  validates :timestamp, numericality: { only_integer: true, greater_than_or_equal_to: Time.now.to_i - 30 }, if: Proc.new{|c| c.new_record?}
  validate :public_id_equals_id, if: Proc.new{|c| c.new_record?}


  ###########################################################
  ##
  ##
  ## CALLBACKS
  ##
  ##
  ###########################################################
  after_create do |document|
    document.signed_request = get_signed_request
  end

  ## this should destroy the image.
  before_destroy do |document|
    Cloudinary::Uploader.destroy(document.id.to_s)
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

  def public_id_equals_id
    self.errors.add(:public_id, "the public id and object id are not equal") if (self.id.to_s != self.public_id)
  end

  ############################################################
  ##
  ##
  ## OTHER CUSTOM DEFS.
  ##
  ##
  ############################################################
  def get_signed_request
    ## these should be merged only if they exist.
    params_to_sign = {:public_id => self.id.to_s,:timestamp=> self.timestamp, :callback => "http://widget.cloudinary.com/cloudinary_cors.html"}
    params_to_sign.merge!({:custom_coordinates => self.custom_coordinates}) unless self.custom_coordinates.blank?
    Cloudinary::Utils.sign_request(params_to_sign, :options=>{:api_key=>Cloudinary.config.api_key, :api_secret=>Cloudinary.config.api_secret})

  end

  ## rendered in create, in the authenticated_controller.
  def text_representation
    self.signed_request[:signature].to_s
  end

  def get_url
    if self.custom_coordinates
      Cloudinary::Utils.cloudinary_url self.id.to_s, gravity: "custom", crop: "crop"
    else
      Cloudinary::Utils.cloudinary_url self.id.to_s
    end
  end

end
