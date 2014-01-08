require 'rest-client'
require 'watir-webdriver'

require 'active_support/core_ext/date/calculations'

class UsBilling
  @current_past_week_confirmed_sales = 0
  @current_this_week_confirmed_sales = 0

  def initialize
    @client = Watir::Browser.new :phantomjs
  end

  def get_billing
    begin
      results = {}
      past_week_end_date = Date.current.prev_week(:monday)
      past_week_start_date = Date.current.prev_week(:monday).advance(days: 6)


      @client.goto "https://www.administration123.com/manage/users/index.cfm?activefilter=active&productSearchType=ANY&rd_product=1&rd_product_not=1&dtBillingStart=#{past_week_start_date.strftime('%m/%d/%Y')}&dtBillingEnd=#{past_week_end_date.strftime('%m/%d/%Y')}&holdSearchType=include&bAllPayments=0&reportId=681&pageSize=100"
      @client.text_field(name: 'username').set 'SSMMSC Master Login'
      @client.text_field(name: 'password').set 'SSMMSC881144'

      @client.button(name: 'authenticate').click

      text = @client.text
      past_week_confirmed = text.scan(/Total:\s(\d+?)\s/)[0][0]

      results[:confirmed_past_week_sales] = {
          current: past_week_confirmed,
          last: @current_past_week_confirmed_sales
      }

      @current_past_week_confirmed_sales = past_week_confirmed

      this_week_start_date = Date.current.beginning_of_week(:monday)
      this_week_end_date = Date.current.beginning_of_week(:monday).advance(days: 6)

      @client.goto "https://www.administration123.com/manage/users/index.cfm?activefilter=active&productSearchType=ANY&rd_product=1&rd_product_not=1&dtBillingStart=#{this_week_start_date.strftime('%m/%d/%Y')}&dtBillingEnd=#{this_week_end_date.strftime('%m/%d/%Y')}&holdSearchType=include&bAllPayments=0&reportId=681&pageSize=100"

      text = @client.text
      this_week_confirmed = text.scan(/Total:\s(\d+?)\s/)[0][0]

      results[:confirmed_this_week_sales] = {
          current: this_week_confirmed,
          last: @current_this_week_confirmed_sales
      }

      @current_this_week_confirmed_sales = this_week_confirmed
      @client.close

      results


    rescue Exception => ex
      $stdout.puts ex.message
      @client.close
    end
  end

end