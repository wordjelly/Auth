class Topic
  include Mongoid::Document
  include Mongoid::Elasticsearch
  elasticsearch!
  field :name, type: String
  field :place, type: String

  def self.mailgun
		
		##########

		# First, instantiate the Mailgun Client with your API key
		mg_client = Mailgun::Client.new 'key-6263360b078081b625182ff17d7a92fd'

		# Define your message parameters
		message_params =  { from: 'bob@sending_domain.com',
		                    to:   'bhargav.r.raut@gmail.com',
		                    subject: 'The Ruby SDK is awesome!',
		                    text:    'It is really easy to send a message!'
		                  }

		# Send your message through the client
		result = mg_client.send_message('sandboxc0248205473845c3a998e44941ee503e.mailgun.org', message_params).to_h!

		puts result.to_s

  end

  def self.delay
  	message = Auth.configuration.mailer_class.constantize.notification(nil,nil)
  	puts message.class.name
  	puts message.message.class.name
  	message.message_id = "here-is-my-test-message-id"
  	r = message.deliver
  	puts r.class.name
  	puts r.message_id
  end

end
