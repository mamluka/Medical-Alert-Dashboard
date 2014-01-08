require 'rest-client'
require 'chronic'

require_relative '../lib/sales/vici-stats'


class Sales

  @current_total_sales = 0
  @current_inbound_sales = 0
  @current_outbound_sales = 0

  @current_inbound_calls = 0
  @current_outbound_calls = 0

  @current_post_date_sales = 0

  def get_sales
    current_date = Time.now.strftime('%Y-%m-%d')

    vici_stats = ViciStats.new

    in_post_hash = {
        query_date: current_date,
        end_date: current_date,
        shift: 'ALL',
        report_display_type: 'TEXT',
        SUBMIT: 'SUBMIT',
        DB: '',
        DID: '',
        EMAIL: ''
    }

    inbound = %w(MACLOSER MACUST MASALES).map { |group|
      vici_stats.get_data 'http://cpierre:cpierre@68.168.105.58/vicidial/AST_CLOSERstats.php', in_post_hash, group
    }

    inbound_sales = inbound.map { |x| x[:sales] }.inject(:+)
    inbound_calls =inbound.map { |x| x[:calls] }.inject(:+)
    inbound_post_date = inbound.map { |x| x[:post_date] }.inject(:+)


    out_post_hash = {
        include_rollover: 'NO',
        bottom_graph: 'NO',
        carrier_stats: 'NO',
        query_date: current_date,
        end_date: current_date,
        shift: 'ALL',
        report_display_type: 'TEXT',
        SUBMIT: 'SUBMIT',
    }

    outbound = %w(MEDALRT MEDCL MEDCU MEDLG).map { |group|
      vici_stats.get_data 'http://cpierre:cpierre@68.168.105.58/vicidial/AST_VDADstats.php', out_post_hash, group
    }

    outbound_sales = outbound.map { |x| x[:sales] }.inject(:+)
    outbound_calls =outbound.map { |x| x[:calls] }.inject(:+)
    outbound_post_date = outbound.map { |x| x[:post_date] }.inject(:+)


    this_week_start_date = Time.new.wday == 1 ? Time.new : Chronic.parse('last monday')
    this_week_end_date = Time.new

    dates_for_data_points = Array.new
    current_date = this_week_start_date
    while current_date <= this_week_end_date
      dates_for_data_points << current_date
      current_date = current_date + (24*3600)
    end
    dates_for_data_points << this_week_end_date

    week_sales_data_points = dates_for_data_points.map { |x|

      in_post_hash[:query_date] = x.strftime('%Y-%m-%d')
      in_post_hash[:end_date] = x.strftime('%Y-%m-%d')

      inbound= %w(MACLOSER MACUST MASALES).map { |group|
        vici_stats.get_data 'http://cpierre:cpierre@68.168.105.58/vicidial/AST_CLOSERstats.php', in_post_hash, group
      }

      inbound_sales = inbound.map { |x| x[:sales] }.inject(:+)
      inbound_post_date = inbound.map { |x| x[:post_date] }.inject(:+)


      out_post_hash[:query_date] = x.strftime('%Y-%m-%d')
      out_post_hash[:end_date] = x.strftime('%Y-%m-%d')

      outbound= %w(MEDALRT MEDCL MEDCU MEDLG).map { |group|
        vici_stats.get_data 'http://cpierre:cpierre@68.168.105.58/vicidial/AST_VDADstats.php', out_post_hash, group
      }

      outbound_sales = outbound.map { |x| x[:sales] }.inject(:+)
      outbound_post_date = outbound.map { |x| x[:post_date] }.inject(:+)

      {y: (inbound_sales + outbound_sales + inbound_post_date + outbound_post_date), x: x.wday}
    }

    send_event('total-inbound-sales', {current: inbound_sales, last: @current_inbound_sales})
    @current_inbound_sales = inbound_sales

    send_event('total-inbound-calls', {current: inbound_calls, last: @current_inbound_calls})
    @current_inbound_calls = inbound_calls


    send_event('total-outbound-sales', {current: outbound_sales, last: @current_outbound_sales})
    @current_outbound_sales = outbound_sales

    send_event('total-outbound-calls', {current: outbound_calls, last: @current_outbound_calls})
    @current_outbound_calls = outbound_calls

    send_event('total-sales', {current: inbound_sales + outbound_sales + outbound_post_date + inbound_post_date, last: @current_total_sales})
    @current_total_sales = outbound_sales + inbound_sales

    send_event('total-post-date-sales', {current: outbound_post_date + inbound_post_date, last: @current_post_date_sales})
    @current_post_date_sales = outbound_post_date + inbound_post_date

    send_event('sales-graph', {points: week_sales_data_points})

  end
end

sales = Sales.new

SCHEDULER.every '2m' do
  sales.get_sales
end