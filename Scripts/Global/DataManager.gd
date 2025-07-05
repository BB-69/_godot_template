extends Node

var log = Logger.new("Data")
var encryption_key = "super_secret_key_12345"

func save_data(data):
	var file = FileAccess.open_encrypted_with_pass(
		"user://user_data.json",
		FileAccess.WRITE,
		encryption_key
	)
	file.store_var(data)
	file.close()
	log.p("Saved Data: %s" % data)

func load_data():
	if FileAccess.file_exists("user://user_data.json"):
		var file = FileAccess.open_encrypted_with_pass(
			"user://user_data.json",
			FileAccess.READ,
			encryption_key
		)
		var data = file.get_var()
		file.close()
		log.p("Loaded data: %s" % data)
		return data
	else:
		log.p("No saved file yet...")
		return null
