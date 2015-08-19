class BouncedEmailInterceptor

	def self.delivering_email(message)
		bounce = 0
		complaint = 1
		ooto = 2
		if (EmailResponse.exists?(email: message.to, response_type: bounce) or EmailResponse.exists?(email: message.to, response_type: complaint))
			message.perform_deliveries = false
			puts "Bounce should have happened"
		end
	end
end

ActionMailer::Base.register_interceptor(BouncedEmailInterceptor)