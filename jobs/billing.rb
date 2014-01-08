require 'rest-client'
require 'chronic'
require 'watir-webdriver'

require_relative '../lib/billing/ph-billing'
require_relative '../lib/billing/us-billing'


ph_billing = PhBilling.new
us_billing = UsBilling.new

SCHEDULER.every '30m' do

  result = ph_billing.get_billing

  confirmed_past_week_sales = result[:confirmed_past_week_sales]
  confirmed_this_week_sales = result[:confirmed_this_week_sales]

  send_event('ph-confirmed-past-week-sales', {current: confirmed_past_week_sales[:current], last: confirmed_past_week_sales[:last]})
  send_event('ph-confirmed-this-week-sales', {current: confirmed_this_week_sales[:current], last: confirmed_this_week_sales[:last]})

  result = us_billing.get_billing

  confirmed_past_week_sales = result[:confirmed_past_week_sales]
  confirmed_this_week_sales = result[:confirmed_this_week_sales]

  send_event('us-confirmed-past-week-sales', {current: confirmed_past_week_sales[:current], last: confirmed_past_week_sales[:last]})
  send_event('us-confirmed-this-week-sales', {current: confirmed_this_week_sales[:current], last: confirmed_this_week_sales[:last]})

end