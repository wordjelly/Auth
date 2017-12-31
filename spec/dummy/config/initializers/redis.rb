#redis.rb
cnfg = nil
REDIS_CONFIG = YAML.load( File.open( Rails.root.join("config/redis.yml") ) ).symbolize_keys
dflt = REDIS_CONFIG[:default].symbolize_keys
cnfg = dflt.merge(REDIS_CONFIG[Rails.env.to_sym].symbolize_keys) if REDIS_CONFIG[Rails.env.to_sym]
$redis = Redis.new(cnfg)
# To clear out the db before each test
puts "FLUSHING REDIS DB SINCE ENV IS DEVELOPMENT."
$redis.flushdb if Rails.env = "development"