class JobExceptionHandler
	def log_exception(exception)
		$redis.zadd("errors",Time.now.to_i,exception.to_s)
	end
end