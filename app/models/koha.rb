class Koha
# All communication with Koha is gathered here

  def self.get_basic_data(personalnumber)
    basic_data = { personalnumber: personalnumber }
    config = get_koha_config
    params = { userid: config[:user], password: config[:password], personalnumber: personalnumber }.to_query
    url = "#{config[:base_url]}/members/check?#{params}"
    response = RestClient.get(url)

    if (response && response.code == 200)
      xml = Nokogiri::XML(response.body).remove_namespaces!
      puts xml
      if (xml.search("//response/borrowernumber").text.present?)
        basic_data.merge!(borrowernumber: xml.search("//response/borrowernumber").text)
      end
      if (xml.search("//response/uniq").text.present?)
        basic_data.merge!(uniq: xml.search("//response/uniq").text)
      end

      if (xml.search("//response/expirationdate").text.present?)
        basic_data.merge!(expirationdate: xml.search("//response/expirationdate").text)
      end

      if (xml.search("//response/categorycode").text.present?)
        basic_data.merge!(categorycode: xml.search("//response/categorycode").text)
      end

    end
    return basic_data
  end

  def self.block(borrowernumber)
    config = get_koha_config
    params = { userid: config[:user], password: config[:password], action: "cardinvalid", borrowernumber: borrowernumber }
    url = "#{config[:base_url]}/members/update?#{params.to_query}"
    RestClient.get(url)
  end

  def self.update(params)
#    borrowernumber = borrowernumber, cardnumber, userid, expiration_date, pin_number)
    config = get_koha_config
    params.merge!({ userid: config[:user], password: config[:password], action: "update"})
    url = "#{config[:base_url]}/members/update?#{params.to_query}"
    RestClient.get(url)
  end
end
