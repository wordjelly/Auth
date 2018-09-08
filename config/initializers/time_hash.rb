## intended way to use
## take your own date
## find its day id
## then slice the @date_with_weekday_to_epoch starting from that index.
## and check each of its keys for your desired pattern.

$time_hash_strftime_format = "%Y%m%d%w"
begin

	hashes_from_file = JSON.parse(IO.read("#{Rails.root}/app/assets/time_hashes.json")).deep_symbolize_keys
	
	$date_hash = hashes_from_file[date_hash]
	$day_id_hash = hashes_from_file[:day_id_hash]

	

rescue => e

	#puts "there was an error loading the file"
	#puts e.to_s

	$date_hash = {}

	$day_id_hash = {}

	

	nt = Time.now - 24.hours

	6000.times do |n|
		t = nt + n.days
		$day_id_hash[t.strftime($time_hash_strftime_format)] = n 
		$date_hash[t.strftime($time_hash_strftime_format)] = t.to_i
	end


	IO.write("#{Rails.root}/app/assets/time_hashes.json",JSON.generate({:day_id_hash => $day_id_hash, :date_hash => $date_hash}))

end


