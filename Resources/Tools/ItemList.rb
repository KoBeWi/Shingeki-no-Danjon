require 'json'

items = []

(Dir.entries("../Items") - [".", ".."]).each do |file|
	item = JSON.parse(File.readlines("../Items/#{file}").join("\n"))
	puts "#{file.chomp(".json")} -> #{item["name"]}"
end