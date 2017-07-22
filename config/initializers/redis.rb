#config/initializers/redis.rb
#if no configuration file has been provided from the dummy app in the Auth.configuration, then we provide a default configuration wherein the port is 6379, and the host is 127.0.0.1
cnfg = nil
if Auth.redis_config_file_location
	REDIS_CONFIG = YAML.load( File.open( Auth.configuration.redis_config_file_location ) ).symbolize_keys
	dflt = REDIS_CONFIG[:default].symbolize_keys
	cnfg = dflt.merge(REDIS_CONFIG[Rails.env.to_sym].symbolize_keys) if REDIS_CONFIG[Rails.env.to_sym]
else
	cnfg = {:host => "127.0.0.1", :port => 6379}
end

$redis = Redis.new(cnfg)
#$redis_ns = Redis::Namespace.new(cnfg[:namespace], :redis => $redis) if cnfg[:namespace]

# To clear out the db before each test
$redis.flushdb if Rails.env = "test"

