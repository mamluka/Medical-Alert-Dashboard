require 'rest-client'

class ViciStats
  def get_sales(url, hash, group)
    result = RestClient.post url, hash.merge({'group[]' => group})

    sales_match = result.scan(/Sale Made.+?\|.+?\|(.+?)\|/)
    if sales_match.length > 0
      sales = sales_match[0][0].to_i
    else
      sales = 0
    end

    sales
  end
end

current_total_sales = 0
current_inbound_sales = 0
current_outbound_sales = 0

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

  inbound_sales = %w(MACLOSER MACUST MASALES).map { |group|
    vici_stats.get_sales 'http://MEDUSA00100:MEDUSA00100@68.168.105.58/vicidial/AST_CLOSERstats.php', in_post_hash, group
  }.inject(:+)

  send_event('total-inbound-sales', {current: inbound_sales, last: current_inbound_sales})
  current_inbound_sales = inbound_sales

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

  outbound_sales = %w(MEDALRT MEDCU).map { |group|
    vici_stats.get_sales 'http://MEDUSA00100:MEDUSA00100@68.168.105.58/vicidial/AST_VDADstats.php', out_post_hash, group
  }.inject(:+)

  send_event('total-outbound-sales', {current: outbound_sales, last: current_outbound_sales})
  current_outbound_sales = outbound_sales

  send_event('total-sales', {current: inbound_sales + outbound_sales, last: current_total_sales})
  current_total_sales = outbound_sales + inbound_sales

end