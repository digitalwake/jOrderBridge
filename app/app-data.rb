#require 'rdbi-driver-sqlite3'
require 'rubygems'
require 'java'
require 'jdbc/sqlite3'
require 'app/db'

org.sqlite.JDBC

class AppData

	def initialize
	  @@current_directory = Dir.getwd
		Dir.mkdir('data') unless File.directory?('data')
		
		#Connect to local sqlite3 database for preferences and local processing
		@db_local = DB.new :db => 'sqlite'

		@db_local.update_qry("create table if not exists items_to_break (item text, desc text)")
		@db_local.update_qry("create table if not exists items_to_weight (item text, desc text)")
#		@db_local.update_qry("create table if not exists program_runs (run_id INTEGER PRIMARY KEY AUTOINCREMENT, created_at date)")
		@db_local.update_qry("create table if not exists log (log_id INTEGER PRIMARY KEY AUTOINCREMENT, log_type char, log_msg text, ord_type char, order_date date, customer text, ship_to text, order_num bigint, item text, item_dsc text, cust_item text, qty integer, created_at date)")
		
		@db_local.update_qry("create table if not exists authorizations (customer INTEGER PRIMARY KEY, created_at date)")
		@db_local.update_qry("create table if not exists restricted_items (item text, created_at date)")
		
		@itb = self.get_items_to_break
		@wtc = self.get_items_weight_to_qty
		@restricted = self.get_restricted_items
		@authorized = self.get_authorized_customers
	end
	
	def maintenance(parms = {})
		puts "Maintenace type is: #{parms[:type]}"
		puts "Adding or Deleting? (A/D):"
		flag = gets.chomp.upcase
		case parms[:type]
			when "broken" then
				table = "items_to_break"
			when "weight" then
				table = "authorizations"
			when "auth" then
				table = "authorizations"
			when "restrictions" then
				table = "restricted_items"
		end
		puts "Enter your items. Type X to quit:"
		input = gets.chomp.upcase
			while input != 'X'
				maintain(input,table,flag)
				puts "Enter your items. Type X to quit:"
				input = gets.chomp.upcase
			end
	end
	
	def maintain(tbl,flag,options={})
		case tbl
		  when "items_to_break" || "weight_to_cases"
		  	case flag
			    when "A" then add_to_pref_table(tbl,options)
			    when "D" then delete_from_pref_table(tbl,options)
		    end
		  when "restrictions"
		    case flag
			    when "A" then add_to_restriction_table(options)
			    when "D" then delete_from_restriction_table(options)
		    end
		  when "authorizations"
		    case flag
			    when "A" then add_to_authorization_table(options)
			    when "D" then delete_from_authorization_table(options)
		    end
		  end
		  
		@itb = self.get_items_to_break
		@wtc = self.get_items_weight_to_qty
		@restricted = self.get_restricted_items
		@authorized = self.get_authorized_customers
	end
	
#	def new_run_id
#	  #Get the last run id
#	  new_run = @db_local.qry("select run_id from program_runs order by run_id desc limit 1")
#	  if new_run.empty?
#	    @db_local.update_qry("insert into program_runs (created_at) values('#{Time.now}')")
#	    return 1
#	  end
#	  @db_local.update_qry("insert into program_runs (created_at) values('#{Time.now}')")
#	  return (new_run[0]['run_id']) + 1
#	end
	
#	def run_id?
#	  id=@db_local.qry("select run_id from program_runs order by run_id desc limit 1")
#	  return id[0]['run_id']
#	end
	
	def get_items_to_break
		hsh = @db_local.qry("select * from items_to_break group by item")
		return hsh
	end
	
	def get_items_weight_to_qty
		hsh = @db_local.qry("select * from weight_to_cases group by item")
		return hsh
	end
	
	def get_restricted_items
		hsh = @db_local.qry("select * from restricted_items group by item")
		return hsh
	end
	
	def get_authorized_customers
		hsh = @db_local.qry("select * from authorizations group by customer")
		return hsh
	end
	
	def get_warnings(params = {})
	  puts "WARNINGS: select distinct cust_item, order_date as Date, log_msg as Warning from log where log_type = 'W' and (order_date >= #{params[:from_date]} and order_date <= #{params[:to_date]}) and ord_type = '#{params[:ord_type]}' and DATE(created_at) = '#{params[:run_date]}' group by cust_item"
		ary = @db_local.qry("select distinct cust_item, order_date as Date, log_msg as Warning from log where log_type = 'W' and (order_date >= #{params[:from_date]} and order_date <= #{params[:to_date]}) and ord_type = '#{params[:ord_type]}' and DATE(created_at) = '#{params[:run_date]}' group by cust_item")
		return ary
	end
	
	def get_errors(params = {})
	  puts "ERRORS: select distinct cust_item, item_dsc, count(cust_item) as Occurrences, order_date as Date, log_msg as Error from log where log_type = 'E' and (order_date >= #{params[:from_date]} and order_date <= #{params[:to_date]}) and ord_type = '#{params[:ord_type]}' and DATE(created_at) = '#{params[:run_date]}' group by cust_item"
		ary = @db_local.qry("select distinct cust_item, item_dsc, count(cust_item) as Occurrences, order_date as Date, log_msg as Error from log where log_type = 'E' and (order_date >= #{params[:from_date]} and order_date <= #{params[:to_date]}) and ord_type = '#{params[:ord_type]}' and DATE(created_at) = '#{params[:run_date]}' group by cust_item")
		return ary
	end
	
	def get_warning_orders_for_item(params = {})
	  #puts "select order_date, order_num, customer, ship_to, cust_item, item_dsc, item_code as ItemUsed, qty from log where log_type = 'W' and order_date = #{params[:date]} and cust_item = '#{params[:item].to_s}' and ord_type = #{params[:ord_type]} order by order_num"
		ary = @db_local.qry("select order_date, order_num, customer, ship_to, cust_item, item_dsc, item as ItemUsed, qty from log where log_type = 'W' and order_date = #{params[:date]} and cust_item = '#{params[:item].to_s}' and ord_type = '#{params[:ord_type]}' and DATE(created_at) = '#{params[:run_date]}' order by order_num")
		return ary
	end
	
	def get_error_orders_for_item(params = {})
	 #puts "select order_date, order_num, customer, ship_to, cust_item, item_dsc, qty from log where log_type = 'E' and order_date = #{params[:date]} and cust_item = '#{params[:item]}' and ord_type = #{params[:ord_type]} order by order_num"
		ary = @db_local.qry("select order_date, order_num, customer, ship_to, cust_item, item_dsc, qty from log where log_type = 'E' and order_date = #{params[:date]} and cust_item = '#{params[:item]}' and ord_type = '#{params[:ord_type]}' and DATE(created_at) = '#{params[:run_date]}' order by order_num")
		return ary
	end
	
	def item_to_break(candidate)
		#rs = self.get_items_to_break
		#uom = ''
		#puts "items_to_break called: candidate = #{candidate.strip}"
		if  candidate.include? "-BC"
		  return 'EA'
		end
		unless @itb.empty? 
			@itb.each do |x|
				#if candidate.strip == x.item.to_s
				if candidate.strip == x['item']
				  #puts "candidate = #{candidate}, item = #{x['item']}, unit = 'EA'"
					return 'EA'
				end
			end
		end
		return 'CS'		
	end
	
	def item_weight_to_qty(candidate, qty, weight)
		#rs = self.get_items_weight_to_qty
		unless @wtc.empty?
			@wtc.each do |x|
				#if candidate.strip == x.item.to_s
				if candidate.strip == x['item']
					#new_qty = qty/(weight*100)
					new_qty = qty/(weight)
					#puts "candidate = #{candidate}, qty = #{qty}, weight = #{weight}, new_qty = #{new_qty}"
					#if qty % (weight*100) > 0
					if qty % (weight) > 0
						new_qty += 1
					end
					qty = new_qty
				end
			end
		end			
		return qty
	end
	
	def restricted?(item)
		unless @restriced.nil? 
			@restricted.each do |x|
				#if candidate.strip == x.item.to_s
				if item.strip == x['item']
				  #puts "candidate = #{candidate}, item = #{x['item']}, unit = 'EA'"
					return true
				end
			end
		end
		return false		
	end
	
	def authorized?(item,cust)
		if restricted?(item)
		  unless @authorizations.nil? 
			  @authorizations.each do |x|
				  if cust == x['customer']
					  return true
				  end
			  end
			end #unless
			return false
	  end #if restricted
	  return true #item is not restricted	
	end
	
	def log(parms = {})
	  desc = self.escape_single_quotes(parms[:item_dsc])
	  values= "'#{parms[:type]}', #{parms[:date]}, '#{parms[:order]}', '#{parms[:cust]}', '#{parms[:ship]}', '#{parms[:cust_item].strip}', '#{desc}', #{parms[:qty]}, '#{parms[:item]}', '#{parms[:msg]}', '#{parms[:ord_type]}', '#{Time.now.strftime("%F %T")}'"
		
		self.add_to_log_table(values)
	end
	
	def close
	  @db_local.disconnect
	end
	
	protected
	def delete_from_pref_table(tbl,options={})
		@db_local.update_qry("delete from #{tbl} where item = #{options[:item]}")
	end
	
	def delete_from_authorization_table(options={})
		@db_local.update_qry("delete from authorizations where customer = #{options[:customer]}")
	end
	
	def delete_from_restriction_table(options={})
		@db_local.update_qry("delete from restricted_items where item = #{options[:item]}")
	end
	
	def escape_single_quotes(str)
	  str.gsub("'","''")
	end
	
	def add_to_pref_table(tbl,options={})
	  #puts "insert into #{tbl} (item,desc) values(#{options[:item]},'#{options[:desc]}')"
	  if @db_local.qry("select item from #{tbl} where item = #{options[:item]}").empty?
		  @db_local.update_qry("insert into #{tbl} (item,desc) values(#{options[:item]},'#{options[:desc]}')")
		else
		  puts "Item #{options[:item]} already exists in the database."
		end		  
	end
	
	def add_to_authorization_table(options={})
	  #puts "insert into #{tbl} (item,desc) values(#{options[:item]},'#{options[:desc]}')"
	  if @db_local.qry("select customer from authorizations where customer = #{options[:customer]}").empty?
		  @db_local.update_qry("insert into authorizations (customer) values(#{options[:customer]})")
		else
		  puts "Customer #{options[:item]} authorization already exists in the database."
		end		  
	end
	
	def add_to_restriction_table(options={})
	  #puts "insert into #{tbl} (item,desc) values(#{options[:item]},'#{options[:desc]}')"
	  if @db_local.qry("select item from restricted_items where item = #{options[:item]}").empty?
		  @db_local.update_qry("insert into restricted_items (item) values(#{options[:item]})")
		else
		  puts "Item #{options[:item]} restriction already exists in the database."
		end		  
	end
	
	def add_to_log_table(input)
	  puts "insert into log (log_type, order_date, order_num, customer, ship_to, cust_item, item_dsc, qty, item, log_msg, ord_type, created_at) values(#{input})"
		@db_local.update_qry("insert into log (log_type, order_date, order_num, customer, ship_to, cust_item, item_dsc, qty, item, log_msg, ord_type, created_at) values(#{input})")
	end
	
	#def clear_log
	#  @db_local.update_qry("UPDATE table log_history set log_id = , log_type=, log_msg=, ord_type=, order_date=, customer=, ship_to=, order_num=, item=, item_dsc=, cust_item=, qty=, created_at="
	#end
	
end
