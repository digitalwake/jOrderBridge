#require 'rdbi'
#require 'rdbi-driver-odbc'
require 'rubygems'
require 'savon'
require 'nokogiri'
require 'db'
require 'java'
require './doe.rb'
require './order-writer.rb'
require './preferences.rb'
require './log-writer.rb'

class OrderProcessor

@@library_prefix="T37"

	def initialize
		@writer = OrderWriter.new
		@prefs = Preferences.new
		@log = LogWriter.new
		@orders_processed = 0
		@purchase_order = 0
		@delivery_date = 0
		@special_instructions = ""
		@cust_num = 0
		@ship_to = 0
		@spec_num = ""
		@qty= 0
		@drop_ship = false
		@item=""
		@item_dsc=""
		@item_weight=0.00
		return self
	end
	
	def login
		correct = 'N'
		while correct =='N'
			print "Please enter your DOE username:"
			@doe_user = gets.chomp
			print "Please enter your DOE password:"
			@doe_pass = gets.chomp

			print "Please enter your S2K username:"
			@s2k_user=gets.chomp
			print "Please enter your S2K password:"
			@s2k_pass = gets.chomp
			puts ""

			puts "Your S2k user information for this session are:"
			puts "User:#{@s2k_user}"
			puts "Pass:#{@s2k_pass}"
			puts ""

			puts "Your DOE user information for this session are:"
			puts "User:#{@doe_user}"
			puts "Pass:#{@doe_pass}"
			puts ""
			puts "Is this correct? (Y/N) or (X - to cancel)"
			correct = gets.chomp.upcase
		end
		if correct == 'X'
			puts "success is FALSE" 
			return false
		end
		
		puts "Success is TRUE"
		return true
	end
	
	def process_current_orders
		puts "*--------- Current Orders ----------*"
		print "            Enter Date [MM/DD/YYYY]:"
		parms = {:advanced => 'N', :date => gets.chomp}
		#print "   Enter Borough ['M'/'K1'/'A'(ll)]:"
		#parms[:boro] = gets.chomp.upcase
		print "LOCK customer Orders for this date?:"
		parms[:lock] = gets.chomp.upcase
		
		if parms[:lock] == 'Y'
			puts "Current Orders: LOCKED ORDERS for Date: #{parms[:date]} for Borough: #{parms[:boro]}"
			print "**This will LOCK ALL the orders for this date.** Continue? (Y/N):"
		else
			puts "Current Orders: UNLOCKED ORDERS for Date: #{parms[:date]} for Borough: #{parms[:boro]}"
			print "Continue? (Y/N):"
		end
		
		continue = gets.chomp.upcase
		if continue == "Y"
			puts "Preparing Connections and Downloading Orders..."
			self.prepare(parms)
			puts "Processing Orders..."
			self.process
			puts "Closing Connections"
			self.close
			puts "Processing Complete"
		else
			puts "We're outta here"
		end
	end
	
	def process_advanced_orders
		puts "*--------- Advanced Orders --------*"
		print "      Enter FROM Date [MM/DD/YYYY]:"
		parms = {:advanced => 'Y', :date => gets.chomp}
		print "        Enter TO Date [MM/DD/YYYY]:"
		parms[:end_date] = gets.chomp
		print "Enter Borough   ['M'/'K1'/'A'(ll)]:"
		parms[:boro] = gets.chomp.upcase
		puts "Advanced Orders: Processing From Date: #{parms[:date]} To Date: #{parms[:end_date]} for Borough: #{parms[:boro]}"
		print "Continue? (Y/N):"
		continue = gets.chomp.upcase
		
		if continue == "Y"
			puts "Preparing Connections and Downloading Orders..."
			self.prepare(parms)
			puts "Processing Orders..."
			self.process
			puts "Closing Connections"
			self.close
			puts "Processing Complete"
		else
			puts "We're outta here"
		end
		#puts "OrderProcessor::processAdvancedOrders called"
	end
	
	def maintain_items_to_break
		@prefs.maintenance :type => "broken"
	end
	
	def maintain_items_to_weight
		@prefs.maintenance :type => "weight"
	end
	
	def close
		#@cust_items.finish
		#@item_master.finish
		@database_handle.disconnect
		#@db_local.disconnect
		puts "#{@writer.orders} Orders Processed with a total of #{@writer.total_order_lines} order lines."
    #@log.close
	end
	
	protected
	def prepare(parms = {})
			
		doe_service = DoeOrders.new
		doe_service.pass = @doe_pass
		doe_service.vendor_id = @doe_user
		doe_service.date = parms[:date]
		
		if parms[:advanced]=='N'
			doe_service.locked_flag = parms[:lock] == 'Y' ? true : false
			@orders = doe_service.get_current_orders
		
			#Get Current XML orders from the Web Service File
			doc = Nokogiri::XML(open(doe_service.get_order_filename))		
		else
			doe_service.end_date = parms[:end_date]
			doe_service.boro = parms[:boro]
			
			@orders = doe_service.get_advanced_orders
		
			#Get Future XML orders from the Web Service File
			doc = Nokogiri::XML(open(doe_service.get_advanced_order_filename))
		end			

		#A NodeSet of the child elements - The DOE WebService names the elements "elements"
		@ns = doc.xpath("//elements")
		
		#Connect to S2K via ODBC and get a handle
		#@database_handle = RDBI.connect :ODBC, :db => "S2K"
		#@database_handle ||= java.sql.DriverManager.get_connection("jdbc:as400://S2K/",'NICKRS2K','ti4u0vlj')
		@database_handle ||= DB.new 'NICKRS2K', 'ti4u0vlj'
		#@s2k_stmt = @database_handle.createStatement
		#if @database_handle.connected
			#puts "We're connected to S2K"
		#else
			#puts "We're not connected to S2K"
		#end
				
		#Get item info
		@item_master = @database_handle.qry("SELECT DISTINCT #{@@library_prefix}MODSDTA.VCOITEM.ONITEM, #{@@library_prefix}MODSDTA.VCOITEM.ONCITM,
																						#{@@library_prefix}FILES.FINITEM.FICDONATED, #{@@library_prefix}FILES.FINITEM.FICBRAND, #{@@library_prefix}FILES.VINITEM.ICDSC1, 
																						#{@@library_prefix}FILES.VINITEM.ICWGHT,
																						#{@@library_prefix}FILES.VINITEM.ICDEL, #{@@library_prefix}MODSDTA.VCOITEM.ONCUST, #{@@library_prefix}FILES.VINITMB.IFDROP 
																						FROM (#{@@library_prefix}FILES.VINITEM INNER JOIN #{@@library_prefix}MODSDTA.VCOITEM ON 
																						(#{@@library_prefix}FILES.VINITEM.ICITEM = #{@@library_prefix}MODSDTA.VCOITEM.ONITEM)) INNER JOIN #{@@library_prefix}FILES.FINITEM ON 
																						#{@@library_prefix}MODSDTA.VCOITEM.ONITEM = #{@@library_prefix}FILES.FINITEM.FICITEM INNER JOIN #{@@library_prefix}FILES.VINITMB ON 
																						#{@@library_prefix}FILES.VINITMB.IFITEM=#{@@library_prefix}FILES.FINITEM.FICITEM WHERE 
																						(((#{@@library_prefix}MODSDTA.VCOITEM.ONCUST)='100000 ')) AND ICDEL <> 'I'")#.fetch(:all,:Struct)
		#@item_master = @database_handle.rs_to_hash(rs)													
																						
		#Clear EDI tables
		@database_handle.clear_edi(@@library_prefix)
				
	end
	
	def get_date(str)
		new_str = "#{str.slice!(6..9)}#{str.slice!(0..1)}#{str.slice!(3..4)}"
		if new_str.include? "/"
			new_str = 0
		end
		return new_str
	end
	
	def set_s2k_item_and_weight
		rs = []
		item_found = false
		donated_count = 0
		purchased_count = 0
		@item_master.each do |row|
			#if row.ONCITM.strip == @spec_num.strip
			if row[:ONCITM].strip == @spec_num.strip
				#if row.FICDONATED == 'Y' #and row.ICDEL != 'I'
				if row[:FICDONATED] == 'Y' #and row.ICDEL != 'I'
					donated_count += 1
				else
					purchased_count += 1 #unless row.ICDEL = 'I'
				end
				#rs << {:item => row.ONITEM.to_s, :weight => row.ICWGHT, :donated => row.FICDONATED}	#unless row.ICDEL = 'I'
				rs << {:item => row[:ONITEM].to_s, :weight => row[:ICWGHT], :donated => row[:FICDONATED]}
				#if row.ICDEL = 'I'
					#@log.inactive :spec => cust_item, :item => row.ONITEM, :order => order, :qty => qty
				#end
			end
		end
		
		#If we have no results exit with a failure
		if rs.empty?
			@log.error :cust => @cust_num,
								 :ship => @ship_to,
								 :order => @purchase_order,
								 :item => @spec_num,
                 :item_dsc => @item_dsc,
								 :qty  => @qty,
								 :date => @delivery_date,
								 :msg => "No Active Item Found"
								 
			return false
		else
			if donated_count > 1
				@log.warning rs, :cust => @cust_num,
								 		 :ship => @ship_to,
								 		 :order => @purchase_order,
								 		 :date => @delivery_date,
								 		 :qty  => @qty,
								 		 :item => @spec_num,
                     :item_dsc => @item_dsc,
								 		 :msg => "Too many Donated Matches"
			end
			
			if purchased_count > 1
				@log.warning rs, :cust => @cust_num,
								 		 :ship => @ship_to,
								 		 :order => @purchase_order,
								 		 :date => @delivery_date,
								 		 :qty  => @qty,
								 		 :item => @spec_num,
                     :item_dsc => @item_dsc,
								 		 :msg => "Too many Purchased Matches"
			end
				 	
			rs.each do |hsh|
				break if item_found == true
				@item = hsh[:item]
				@item_weight = hsh[:weight]
				if hsh[:donated] == 'Y'
					item_found = true
				end
			end
		end
		return true
		#puts "#{@item} #{@item_weight}"
	end
	
	def drop_ship?(item)
		@item_master.each do |row|
			#if row.IFDROP == 'Y'
			if row[:IFDROP] == 'Y'
				@drop_ship_item = true
			else
				@drop_ship_item = false
			end
		end
		return @drop_ship_item
	end
	
	def weight_to_case?(item)
		@item_master.each do |row|
			#if row.IFDROP == 'Y'
			if row[:IFDROP] == 'Y'
				@drop_ship_item = true
			else
				@drop_ship_item = false
			end
		end
		return @drop_ship_item
	end
	
  def process
		#Iterate through the orders (elements marked "elements")
		puts "Process called."
		i=0
		@ns.each do |node| 
			@purchase_order = node.at_xpath("order_id").content
			@delivery_date = self.get_date(node.at_xpath("delivery_date").content)
			if @delivery_date == 0
				puts "Invalid Delivery Date in Webservice"
				return false
			end
			@ship_to = node.at_xpath("school_id").content.to_i
			@cust_num = ((@ship_to/1000)*1000)+999
			@special_instructions = node.at_xpath("special_instruction").content
			
			i += 1
			puts "Orders: #{i}" #indexing starts at zero
				
			#Iterate through the element details while looking for drop shipments
			orderline = 0
			drop_ship_orderline = 0
			node.xpath('details').each do |child|
				@spec_num = child['item_key']
				@qty = child['ordered_quantity'].to_i
				@item_dsc = child['item_name']
				
				#Iterate while looking for Drop Shipments
				@item = "0" unless self.set_s2k_item_and_weight
				unit =  @prefs.item_to_break(@item)
				#puts "uom = #{unit}"
				if unit == 'EA'
					unless @item.include? "-BC"	
						@item.strip!
						@item += "-BC"
					end
				end
				@qty = @prefs.item_weight_to_qty(@item, @qty, @item_weight)
				if drop_ship?(@item)
					drop_ship_orderline += 1
					@drop_ship = true
					@writer.write_order_detail_drop_ship(@database_handle, @cust_num, @purchase_order,
																								drop_ship_orderline, @item, @spec_num, unit, @ship_to, @qty)
				else
					orderline += 1
					@writer.write_order_detail(@database_handle, @cust_num, @purchase_order, orderline, @item, @spec_num, unit, @ship_to, @qty)
				end
			end #of details block
			
			if @drop_ship == true
				@writer.write_order_header_drop_ship(@database_handle, @purchase_order, @cust_num, @ship_to, @delivery_date, @special_instructions)
				#set drop ship to no for the next run since the drop ships have been processed
				@drop_ship = false				
			end
			
			if orderline > 0
				@writer.write_order_header(@database_handle, @purchase_order, @cust_num, @ship_to, @delivery_date, @special_instructions)
			end
		end
  end
	#private_class_method :prepare, :process_order_header, :process_order_detail
end
