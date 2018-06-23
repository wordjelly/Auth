class Auth::SendMail < ActionMailer::Base
	default from: "bhargav.r.raut@gmail.com"
	def send_email(opts)
		@options = opts || {}
		raise "no recipient address" unless @options[:to]
		raise "no subject" unless @options[:to]
		mail(to: @options[:to], subject: @options[:subject]) do |format|
			format.html { render @options[:template] || "send"  }
		end	
	end
	## okay so for this, we will pass it to otp job only.
	## with some arguments.
	## why not use whatever emailer i was using before ?
	## okay so the next step is to send this whole notification into a delayed job.
end