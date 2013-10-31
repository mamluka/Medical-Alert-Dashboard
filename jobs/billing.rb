require 'rest-client'
require 'chronic'
require 'watir-webdriver'

current_past_week_confirmed_sales = 0
current_past_week_declined_sales = 0

current_this_week_confirmed_sales = 0
current_this_week_declined_sales = 0

SCHEDULER.every '10m' do

  past_week_end_date = Chronic.parse('last saturday')
  past_week_start_date = past_week_end_date - (24*3600*6)

  client = Watir::Browser.new :phantomjs

  client.goto "https://www.administration123.com/manage/users/index.cfm?activefilter=active&productSearchType=ANY&rd_product=1&rd_product_not=1&dtBillingStart=#{past_week_start_date.strftime('%m/%d/%Y')}&dtBillingEnd=#{past_week_end_date.strftime('%m/%d/%Y')}&holdSearchType=include&bAllPayments=0&reportId=681&pageSize=100"
  client.text_field(name: 'username').set 'Ellick Data Entry'
  client.text_field(name: 'password').set 'Ellick887711'

  client.button(name: 'authenticate').click

  text = client.text
  past_week_confirmed = text.scan(/Total::\s(\d+?)\s/)[0][0]

  send_event('confirmed-past-week-sales', {current: past_week_confirmed, last: current_past_week_confirmed_sales})
  current_past_week_confirmed_sales = past_week_confirmed

  this_week_start_date = Time.new.wday == 1 ? Time.new : Chronic.parse('last monday')
  this_week_end_date = Time.new

  client.goto "https://www.administration123.com/manage/users/index.cfm?activefilter=active&productSearchType=ANY&rd_product=1&rd_product_not=1&dtBillingStart=#{this_week_start_date.strftime('%m/%d/%Y')}&dtBillingEnd=#{this_week_end_date.strftime('%m/%d/%Y')}&holdSearchType=include&bAllPayments=0&reportId=681&pageSize=100"

  text = client.text
  this_week_confirmed = text.scan(/Total::\s(\d+?)\s/)[0][0]

  send_event('confirmed-this-week-sales', {current: this_week_confirmed, last: current_this_week_confirmed_sales})
  current_this_week_confirmed_sales = this_week_confirmed

  client.close

end