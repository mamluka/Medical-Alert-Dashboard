require 'rest-client'
require 'chronic'
require 'watir-webdriver'

current_past_week_confirmed_sales = 0
current_past_week_unconfirmed_sales = 0

current_this_week_confirmed_sales = 0
current_this_week_unconfirmed_sales = 0

#SCHEDULER.every '2h' do

  past_week_end_date = Chronic.parse 'last saturday'
  past_week_start_date = past_week_end_date - (24*3600*6)

  client = Watir::Browser.new :phantomjs

  client.goto 'https://www.administration123.com/manage/users/index.cfm'
  client.text_field(name: 'username').set 'Ellick Data Entry'
  client.text_field(name: 'password').set 'Ellick887711'

  client.button(name: 'authenticate').click

  html = client.html

  rows = html.scan /<tr.+?id="row.+?<\/tr>/m

  rows.shift

  cells = rows.map { |x| {date: Chronic.parse(x.scan(/<td.+?>(.+?)<\/td>/m)[9][0].strip), approved_sale: x.include?('tick.gif')} }

  past_week_range_cells = cells.select { |x| x[:date] >= past_week_start_date && x[:date]<=past_week_end_date }

  past_week_confirmed = past_week_range_cells.count { |x| x[:approved_sale] }
  past_week_unconfirmed = past_week_range_cells.count { |x| !x[:approved_sale] }

  send_event('confirmed-past-week-sales', {current: past_week_confirmed, last: current_past_week_confirmed_sales})
  current_past_week_confirmed_sales = past_week_confirmed

  send_event('unconfirmed-past-week-sales', {current: past_week_unconfirmed, last: current_past_week_unconfirmed_sales})
  current_past_week_unconfirmed_sales = past_week_unconfirmed

  this_week_start_date = Time.new.wday <= 2 ? Time.new : Chronic.parse('last monday')
  this_week_end_date = Time.new

  this_week_range_cells = cells.select { |x| x[:date] >= this_week_start_date && x[:date]<=this_week_end_date }

  this_week_confirmed = this_week_range_cells.count { |x| x[:approved_sale] }
  this_week_unconfirmed = this_week_range_cells.count { |x| !x[:approved_sale] }


  send_event('confirmed-this-week-sales', {current: this_week_confirmed, last: current_this_week_confirmed_sales})
  current_this_week_confirmed_sales = this_week_confirmed

  send_event('unconfirmed-this-week-sales', {current: this_week_unconfirmed, last: current_this_week_unconfirmed_sales})
  current_this_week_unconfirmed_sales = this_week_unconfirmed

end