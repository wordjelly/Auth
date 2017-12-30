##DECIDED TO PLACE THE CONFIGURATION FILES IN THE DUMMY_APP IN THE CONFIG FOLDER, AND TELL THE USER THAT THEY SHOULD ALWAYS BE PLACED THERE.
##OTHERWISE WILL USE, DEFAULT CONFIG FILES PLACED IN THE ENGINES CONFIG FOLDER
##NEED TO ADD THE CODE TO DO THIS
##FOR THE MOMENT PROCEED WITH FILES PLACED IN THE ENGINE CONFIG FOLDER.
cnfg = nil

#if Auth.configuration.redis_config_file_location
#REDIS_CONFIG = YAML.load( File.open( Auth.configuration.redis_config_file_location ) ).symbolize_keys	
#else
REDIS_CONFIG = YAML.load( File.open( Rails.root.join("config/redis.yml") ) ).symbolize_keys
#end

dflt = REDIS_CONFIG[:default].symbolize_keys
cnfg = dflt.merge(REDIS_CONFIG[Rails.env.to_sym].symbolize_keys) if REDIS_CONFIG[Rails.env.to_sym]

$redis = Redis.new(cnfg)

# To clear out the db before each test
puts "FLUSHING REDIS DB SINCE ENV IS DEVELOPMENT."
$redis.flushdb if Rails.env = "development"

