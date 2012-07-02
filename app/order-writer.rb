class OrderWriter

@@library="r37files"
	
	def initialize
		@orders = 0
		@total_order_lines = 0
		return self
	end
	
	def write_order_header_drop_ship(dbh,po,cust,ship_to,date,notes)
		@orders += 1
		puts "OrderWriter.write_order_header_drop_ship called."
		dbh.update_qry("Insert into #{@@library}.vedxpohw(EHCMP,EHTYPE,EHCUST,EHPONO,EHSHIP,EHDDT8) 
								Values (1,'D ', '#{cust}', '#{po}', '#{ship_to}', #{date})")
	end
	
	def write_order_detail_drop_ship(dbh,cust,po,line,item,cust_item,uom,ship_to,qty)
		@total_order_lines += 1
		puts "OrderWriter.write_order_detail_drop_ship called."
		dbh.update_qry("Insert into #{@@library}.vedxpodh(EWCMP,EWTYPE,EWPONO,EWLINE, EWITEM, EWSHTO, EWOQTY, EWSTYL, EWUM, EWCUST) 
								Values (1,'D ', '#{po}', #{line}, '#{item}', '#{ship_to}', #{qty},'#{cust_item}','#{uom}','#{cust}')")
	end
	
	def write_order_header(dbh,po,cust,ship_to,date,notes)
		@orders += 1
		#puts "OrderWriter.write_order_header called."
		dbh.update_qry("Insert into #{@@library}.vedxpohw(EHCMP,EHCUST,EHPONO,EHSHIP,EHDDT8) 
								Values (1, '#{cust}', '#{po}', '#{ship_to}', #{date})")
	end
	
	def write_order_detail(dbh,cust,po,line,item,cust_item,uom,ship_to,qty)
		@total_order_lines += 1
		#puts "OrderWriter.write_order_detail called."
		#puts "Values (1, '#{po}', #{line}, '#{item}', '#{ship_to}', #{qty}, '#{cust_item}', '#{uom}', '#{cust}')"
		dbh.update_qry("Insert into #{@@library}.vedxpodh(EWCMP,EWPONO,EWLINE,EWITEM,EWSHTO,EWOQTY,EWSTYL,EWUM,EWCUST) 
											Values (1, '#{po}', #{line}, '#{item}', '#{ship_to}', #{qty}, '#{cust_item}', '#{uom}', '#{cust}')")
	end
	
	attr_reader :orders, :total_order_lines
	
end
