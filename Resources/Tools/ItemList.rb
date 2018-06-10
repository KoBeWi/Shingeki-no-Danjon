require 'json'

items = []

(Dir.entries("../Items") - [".", ".."]).sort{|entry1, entry2| entry1.rjust(8, "0") <=> entry2.rjust(8, "0")}.each do |file|
	item = JSON.parse(File.readlines("../Items/#{file}").join("\n"))
	puts "#{file.chomp(".json").rjust(3, " ")} -> #{item["name"]} (#{item["type"]})"
end

gets