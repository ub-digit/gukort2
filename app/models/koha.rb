class Koha
# All communication with Koha is gathered here

  def self.get_basic_data(personalnumber)
    basic_data = { personalnumber: personalnumber }
    config = get_config
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
        basic_data.merge!(uniq: xml.search("//response/expirationdate").text)
      end

       if (xml.search("//response/categorycode").text.present?)
        basic_data.merge!(uniq: xml.search("//response/categorycode").text)
      end

    end
    return basic_data
  end

  def self.block(borrowernumber)
    config = get_config
    params = { userid: config[:user], password: config[:password], action: "cardinvalid", borrowernumber: borrowernumber }.to_query
    url = "#{config[:base_url]}/members/update?#{params}"
    RestClient.get(url)
  end

  def self.update(borrowernumber, cardnumber, userid, expiration_date, pin_number)
    config = get_config
    params = { userid: config[:user], password: config[:password], action: "update", borrowernumber: borrowernumber, cardnumber: cardnumber, patronuserid: userid, dateexpiry: expiration_date, pin: pin_number}.to_query
    url = "#{config[:base_url]}/members/update?#{params}"
    response = RestClient.get(url)
    return response
  end
end