class ViciStats
  def get_data(url, hash, group)
    result = RestClient.post url, hash.merge({'group[]' => group})

    sales_match = result.scan(/Sale Made.+?\|.+?\|(.+?)\|/)
    if sales_match.length > 0
      sales = sales_match[0][0].to_i
    else
      sales = 0
    end

    sales_match = result.scan(/ACH.+?\|.+?\|.+?\|(.+?)\|/)
    if sales_match.length > 0
      sales = sales + sales_match[0][0].to_i
    end

    sales_match = result.scan(/CCT.+?\|.+?\|.+?\|(.+?)\|/)
    if sales_match.length > 0
      sales = sales + sales_match[0][0].to_i
    end

    total_match = result.scan(/TOTAL:.+?\|(.+?)\|/)

    if total_match.length > 0
      total_calls = total_match[0][0].to_i
    else
      total_calls = 0
    end

    post_date_match = result.scan(/PD\s.+?\|.+?\|.+?\|(.+?)\|/)
    if post_date_match.length > 0
      post_date = post_date_match[0][0].to_i
    else
      post_date= 0
    end

    post_date_match = result.scan(/PDS.+?\|.+?\|.+?\|(.+?)\|/)
    if post_date_match.length > 0
      post_date = post_date + post_date_match[0][0].to_i
    end

    {
        post_date: post_date,
        calls: total_calls,
        sales: sales
    }
  end
end