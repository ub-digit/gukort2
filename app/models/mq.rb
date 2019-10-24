class MQ
  def self.generate_cardnumber(pnr)
    config = get_mq_config

    params = { api_key: config["rest_api_key"] }
    url = "#{config[:base_url]}/cardnumber/#{pnr}?#{params.to_query}"
    RestClient.get(url)
  end
end
