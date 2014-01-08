require 'rest-client'
require 'chronic'
require 'watir-webdriver'

require_relative '../lib/billing/billing'


billing = Billing.new

SCHEDULER.every '30m' do
  result = billing.get_billing

  confirmed_past_week_sales = result[:confirmed_past_week_sales]
  confirmed_this_week_sales = result[:confirmed_this_week_sales]

  send_event('confirmed-past-week-sales', {current: confirmed_past_week_sales[:current], last: confirmed_past_week_sales[:last]})
  send_event('confirmed-this-week-sales', {current: confirmed_this_week_sales[:current], last: confirmed_this_week_sales[:last]})

end