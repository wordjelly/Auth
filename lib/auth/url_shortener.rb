module UrlShortener
	## return[String] shortened url OR nil if exception is encountered.
	def self.url_shortener_endpoint
		"https://www.googleapis.com/urlshortener/v1/url"
	end

	## return[String] shortened url.
	## raises exception if no longurl provided.
	def self.shorten(longUrl=nil)
		raise Exception.new("long url not provided") if longUrl.nil?
		body = {:longUrl => longUrl}.to_json
		request = Typhoeus::Request.new(
		  url_shortener_endpoint,
		  method: :post,
		  params: 
		  { 
		  	key: Auth.configuration.third_party_api_keys[:google_url_shortener_api_key]	
		  },
		  body: body,
		  headers: { 
		  'Accept' => "application/json",
		  'Content-Type' => "application/json"
		  }
		)
		response = request.run
		JSON.parse(response.body)["id"] if response.success?	
		
	end
end