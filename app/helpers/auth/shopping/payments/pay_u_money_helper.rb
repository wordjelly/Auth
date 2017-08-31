module Auth::Shopping::Payments::PayUMoneyHelper
	## used in the _gateway.html.erb, while generating the form to post to create payment.
	def payment_options(payment,resource)
		options = {}
		options[:hidden] = {}
		options[:visible] = {}
		#these three options are set in the before_save callback of the payumoney concern
		#options[:hidden][:txnid] = payment.id.to_s
		#options[:hidden][:surl] = success_url
		#options[:hidden][:furl] = failure_url
		options[:hidden][:payment_type] =  payment.payment_type
		options[:hidden][:cart_id] = payment.cart_id.to_s
		
		options[:visible][:productinfo] = payment.get_cart_name
		options[:visible][:firstname] =  resource.resource_first_name
		options[:visible][:email] = resource.email
		options[:visible][:phone] = resource.has_phone ? resource.additional_login_param : nil
		options[:visible][:amount] = payment.amount
		options
	end

	##converts the payment object to a form that can be submitted to the gateway.
	def payment_to_gateway_form(payment)
		result = []
		result << form_tag(PayuIndia.service_url, :method => :post)

        result << hidden_field_tag('key', payment.payment_gateway_key)

        payment.attributes.each do |field, value|

          result << hidden_field_tag(field == "hast" ? "hash" : field, value)
        end

        result << '<input type=submit value=" Pay with PayU ">'
        result << '</form>'
        result = result.join("\n")
        concat(result.respond_to?(:html_safe) ? result.html_safe : result)
        nil
	end

end