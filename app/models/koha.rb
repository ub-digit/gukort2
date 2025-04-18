class Koha
# All communication with Koha is gathered here

  def self.get_basic_data(personalnumber, userid = nil)
    basic_data = { personalnumber: personalnumber }
    config = get_koha_config
    params = { login_userid: config[:user], login_password: config[:password], personalnumber: personalnumber, patronuserid: userid }.to_query
    Rails.logger.debug ["KOHA-CHECK", params]
    url = "#{config[:base_url]}#{config[:svc_check]}?#{params}"
    Rails.logger.debug ["KOHA-CHECK", url]
    response = RestClient.get(url)
    #return basic_data

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
        expirationstr = xml.search("//response/expirationdate").text

        if expirationstr.present?
          # Do not crash with invalid data
          begin
            basic_data.merge!(expirationdate: Time.parse(expirationstr))
          rescue
          end
        end
      end

      if (xml.search("//response/categorycode").text.present?)
        basic_data.merge!(categorycode: xml.search("//response/categorycode").text)
      end

    end
    return basic_data
  end

  def self.block(borrowernumber)
    config = get_koha_config
    params = { login_userid: config[:user], login_password: config[:password], action: "cardinvalid", borrowernumber: borrowernumber }
    Rails.logger.debug ["KOHA-BLOCK", params]
    url = "#{config[:base_url]}#{config[:svc_update]}?#{params.to_query}"
    RestClient.get(url)
  end

  def self.update(params)
#    borrowernumber = borrowernumber, cardnumber, userid, expiration_date, pin_number)
    config = get_koha_config
    params.merge!({ login_userid: config[:user], login_password: config[:password], action: "update"})
    Rails.logger.debug ["KOHA-UPDATE", params]
    url = "#{config[:base_url]}#{config[:svc_update]}?#{params.to_query}"
    RestClient.get(url)
  end

  # Same as update, but only updates PIN
  def self.updatepin(params)
    config = get_koha_config
    params.merge!({ login_userid: config[:user], login_password: config[:password], action: "updatepin"})
    Rails.logger.debug ["KOHA-UPDATEPIN", params]
    url = "#{config[:base_url]}#{config[:svc_update]}?#{params.to_query}"
    RestClient.get(url)
  end

  def self.handle_syncuser(params)
    config = get_koha_config
    params.merge!({ login_userid: config[:user], login_password: config[:password], action: "handle-syncuser"})
    Rails.logger.debug ["KOHA-HANDLE-SYNCUSER", params, config]
    url = "#{config[:base_url]}#{config[:svc_syncuser]}?#{params.to_query}"
    RestClient.get(url)
  end

  def self.create(params)
    config = get_koha_config
    params.merge!({ login_userid: config[:user], login_password: config[:password]})
    Rails.logger.debug ["KOHA-CREATE", params]
    url = "#{config[:base_url]}#{config[:svc_create]}?#{params.to_query}"
    RestClient.get(url)
  end
end
