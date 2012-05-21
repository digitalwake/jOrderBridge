#require 'rdbi-driver-sqlite3'
require 'rubygems'
require 'jdbc/sqlite3'
require 'java'
require 'db'

org.sqlite.JDBC

class Preferences

	def initialize
		Dir.mkdir('./data') unless File.directory?('./data')
		#Database.new('./data/orderbridge.sqlite3') unless File.exists?('./data/orderbridge.sqlite3')
		
		#Connect to local sqlite3 database for preferences and local processing
		#@db_local = RDBI.connect(RDBI::Driver::SQLite3, :database => './data/orderbridge.sqlite3')
		@db_local = DB.new :db => 'sqlite'

		#@stmt = @db_local.createStatement
		@db_local.update_qry("create table if not exists items_to_break (item text)")
		@db_local.update_qry("create table if not exists items_to_weight (item text)")
	end
	
	def maintenance(parms = {})
		puts "Maintenace type is: #{parms[:type]}"
		puts "Adding or Deleting? (A/D):"
		flag = gets.chomp.upcase
		case parms[:type]
			when "broken" then
				table = "items_to_break"
			when "weight" then
				table = "items_to_weight"
		end
		puts "Enter your items. Type X to quit:"
		input = gets.chomp.upcase
			while input != 'X'
				maintain(input,table,flag)
				puts "Enter your items. Type X to quit:"
				input = gets.chomp.upcase
			end
	end
	
	def maintain(input,tbl,flag)
		case flag
			when "A" then add_to_pref_table(input,tbl)
			when "D" then delete_from_pref_table(input,tbl)
		end
	end
	
	def get_items_to_break
		#rs = @db_local.execute("select * from items_to_break").fetch(:all,:Struct)
		#return rs
		ary = @db_local.qry("select * from items_to_break")
		return ary
	end
	
	def get_items_weight_to_qty
		#rs = @db_local.execute("select * from items_to_weight").fetch(:all,:Struct)
		#return rs
		#return rs
		ary = @db_local.qry("select * from items_to_weight")
		return ary
	end
	
	def item_to_break(candidate)
		rs = self.get_items_to_break
		#uom = ''
		unless rs.empty? 
			rs.each do |x|
				#if candidate.strip == x.item.to_s
				if candidate.strip == x['item']
					return 'EA'
				end
			end
		end
		return 'CS'		
	end
	
	def item_weight_to_qty(candidate, qty, weight)
		rs = self.get_items_weight_to_qty
		unless rs.empty?
			rs.each do |x|
				#if candidate.strip == x.item.to_s
				if candidate.strip == x['item']
					#new_qty = qty/(weight*100)
					new_qty = qty/(weight)
					puts "candidate = #{candidate}, qty = #{qty}, weight = #{weight}, new_qty = #{new_qty}"
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
	
	protected
	def delete_from_pref_table(input,tbl)
		@db_local.update_qry("delete from #{tbl} where item = #{input.to_s}")
	end
	
	def add_to_pref_table(input,tbl)
		@db_local.update_qry("insert into #{tbl} (item) values(#{input.to_s})")
	end
	
end
