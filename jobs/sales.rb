require 'rest-client'
require 'chronic'

class ViciStats
  def get_data(url, hash, group)
    result = RestClient.post url, hash.merge({'group[]' => group})

    sales_match = result.scan(/Sale Made.+?\|.+?\|(.+?)\|/)
    if sales_match.length > 0
      sales = sales_match[0][0].to_i
    else
      sales = 0
    end

    total_match = result.scan(/TOTAL:.+?\|(.+?)\|/)

    if total_match.length > 0
      total_calls = total_match[0][0].to_i
    end

    {
        calls: total_calls,
        sales: sales
    }
  end
end

current_total_sales = 0
current_inbound_sales = 0
current_outbound_sales = 0

current_inbound_calls = 0
current_outbound_calls = 0

SCHEDULER.every '5m' do

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
    vici_stats.get_data 'http://MEDUSA00100:MEDUSA00100@68.168.105.58/vicidial/AST_CLOSERstats.php', in_post_hash, group
  }

  inbound_sales = inbound.map { |x| x[:sales] }.inject(:+)
  inbound_calls =inbound.map { |x| x[:calls] }.inject(:+)

  send_event('total-inbound-sales', {current: inbound_sales, last: current_inbound_sales})
  current_inbound_sales = inbound_sales

  send_event('total-inbound-calls', {current: inbound_calls, last: current_inbound_calls})
  current_inbound_calls = inbound_calls

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

  outbound = %w(MEDALRT MEDCU).map { |group|
    vici_stats.get_data 'http://MEDUSA00100:MEDUSA00100@68.168.105.58/vicidial/AST_VDADstats.php', out_post_hash, group
  }

  outbound_sales = outbound.map { |x| x[:sales] }.inject(:+)
  outbound_calls =outbound.map { |x| x[:calls] }.inject(:+)

  send_event('total-outbound-sales', {current: outbound_sales, last: current_outbound_sales})
  current_outbound_sales = outbound_sales

  send_event('total-outbound-calls', {current: outbound_calls, last: current_outbound_calls})
  current_outbound_calls = outbound_calls

  send_event('total-sales', {current: inbound_sales + outbound_sales, last: current_total_sales})
  current_total_sales = outbound_sales + inbound_sales

  this_week_start_date = Time.new.wday == 2 ? Time.new : Chronic.parse('last monday')
  this_week_end_date = Time.new

  dates_for_data_points = Array.new
  current_date = this_week_start_date
  while current_date <= this_week_end_date
    dates_for_data_points << current_date
    current_date = current_date + (24*3600)
  end

  week_sales_data_points = dates_for_data_points.map { |x|

    in_post_hash[:query_date] = x.strftime('%Y-%m-%d')
    in_post_hash[:end_date] = x.strftime('%Y-%m-%d')

    inbound_sales= %w(MACLOSER MACUST MASALES).map { |group|
      vici_stats.get_data 'http://MEDUSA00100:MEDUSA00100@68.168.105.58/vicidial/AST_CLOSERstats.php', in_post_hash, group
    }.map { |x| x[:sales] }.inject(:+)

    out_post_hash[:query_date] = x.strftime('%Y-%m-%d')
    out_post_hash[:end_date] = x.strftime('%Y-%m-%d')

    outbound_sales = %w(MEDALRT MEDCU).map { |group|
      vici_stats.get_data 'http://MEDUSA00100:MEDUSA00100@68.168.105.58/vicidial/AST_VDADstats.php', out_post_hash, group
    }.map { |x| x[:sales] }.inject(:+)

    {y: (inbound_sales + outbound_sales), x: x.wday}
  }

  send_event('sales-graph', {points: week_sales_data_points})

end