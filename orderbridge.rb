require './order-processor.rb'
	
session = OrderProcessor.new

if session.login
	print "Continue? (Y/N):"
	continue = gets.chomp.upcase
			
	if continue == "Y"
		puts "Please select from the following Menu options:"
		puts "1. Process Advanced Orders for a Date Range"
		puts "2. Process and 'Lock' Orders for a Specific Date"
		puts "3. Maintain Items to Break"
		puts "4. Maintain Items to Convert to Pounds"
		print "Enter option:"
		@function = gets.chomp
			case @function
			when "1" then session.process_advanced_orders
			when "2" then session.process_current_orders
			when "3" then session.maintain_items_to_break
			when "4" then session.maintain_items_to_weight
			end
	else
		puts "We're outta here"
	end
	
else
	puts "Login Failed - Quitting now."
end

