require 'rest-client'
require 'chronic'

require_relative '../lib/sales/vici-stats'
require_relative '../lib/sales/ph-sales'
require_relative '../lib/sales/us-sales'




ph_sales = PhSales.new
us_sales = UsSales.new

SCHEDULER.every '2m' do
  ph_sales.get_sales
  us_sales.get_sales
end