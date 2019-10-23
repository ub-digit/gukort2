module ColorLog
	def log(msg)
		#colorizes the output
	  puts "\033[32m\033[1m-> #{msg}\e[0m"
	end
end
