class LogWriter

@@warning_file = "logs/warnings_#{Time.now.strftime("%Y%m%d.txt")}"
@@error_file = "logs/errors_#{Time.now.strftime("%Y%m%d.txt")}"
@@inactive_item_file = "logs/inactive_items_#{Time.now.strftime("%Y%m%d.txt")}"

	def initialize
		Dir.mkdir('logs') unless File.directory?('logs')
		#File.new(@@warning_file)
		#File.new(@@error_file)
		@wfh = File.open(@@warning_file, "w")
		@wfh.puts "OrderBridge 2.0 WARNING Report (run at: #{Time.now})"
		@efh = File.open(@@error_file, "w")
		@efh.puts "OrderBridge 2.0 ERROR Report (run at: #{Time.now})"
		#@ifh = File.open(@@inactive_item_file, "w")
		#@ifh.puts "OrderBridge 2.0 INACTIVE ITEM Report (run at: #{Time.now})"
	end
	
	def error(parms = {})
		@efh.puts "#{parms[:msg]} **********"
		@efh.print "Date: #{format("%10s", parms[:date])}  Customer: #{format("%8s", parms[:cust])}  Ship-to: #{format("%8s", parms[:ship])}"
		@efh.puts "  Order: #{format("%10s", parms[:order])} Item: #{format("%10s", parms[:item])}-#{format("%10s", parms[:item_dsc])}
							 Qty: #{format("%6s", parms[:qty])}"		
	end
	
	def warning(rs, parms = {})
		@wfh.puts "#{parms[:msg]} **********"
		@wfh.print "Date: #{format("%10s", parms[:date])}  Customer: #{format("%8s", parms[:cust])}  Ship-to: #{format("%8s", parms[:ship])}"
		@wfh.puts "  Order: #{format("%10s", parms[:order])}  Item: #{format("%10s", parms[:item])}-#{format("%10s", parms[:item_dsc])}
							 Qty: #{format("%6s", parms[:qty])}"
		rs.each do |x|
			@wfh.puts "item: #{x[:item]}"
		end
		@wfh.puts "---------------------------------------------------------------------------"
	end
	
	def inactive(parms = {})
		@ifh.puts "Order: #{format("%10s", parms[:order])} Customer Item: #{format("%20s", parms[:spec])} Qty: #{format("%10s", parms[:qty])}"
	end
	
	def close
		#day = Time.now.day
		#month = Time.now.month
		#year = Time.now.year
		#filename = "#{year}#{month}#{day}.txt"
		#File.rename(@@warning_file, @@warning_file.sub(/(\.[a-z]*)/,'') + filename)
		#File.rename(@@error_file, @@error_file.sub(/(\.[a-z]*)/,'') + filename)
		#File.rename(@@inactive_item_file, "logs/inactive_items" + filename)
		#File.close(@@warning_file)
		#File.close(@@error_file)
		#File.close(@@inactive_item_file)
	end
	
end
