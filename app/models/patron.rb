class Patron < ApplicationRecord
  #    {
  #      name: @name,
  #      address1: @addr1,
  #      address2: @addr2,
  #      contact: @contact,
  #      extra: @extra
  #    }

  def self.get_basic_data(personalnumber)
    basic_data = { personalnumber: personalnumber }
    config = get_config
    params = { userid: config[:user], password: config[:password], personalnumber: personalnumber }.to_query
    url = "#{config[:base_url]}/members/check?#{params}"
    response = RestClient.get(url)

    if (response && response.code == 200)
      xml = Nokogiri::XML(response.body).remove_namespaces!

      if (xml.search("//response/borrowernumber").text.present?)
        basic_data.merge!(borrowernumber: xml.search("//response/borrowernumber").text)
      end
      if (xml.search("//response/uniq").text.present?)
        basic_data.merge!(uniq: xml.search("//response/uniq").text)
      end
    end
    return basic_data
  end

  def self.block(borrowernumber)
    config = get_config
    params = { userid: config[:user], password: config[:password], action: "cardinvalid", borrowernumber: borrowernumber }.to_query
    url = "#{config[:base_url]}/members/update?#{params}"
    response = RestClient.get(url)
    return response
  end

  def self.store_student(data)
    source_pnr = data[:extra][:pnr]
    pnr12 = get_pnr12(source_pnr)

    record = get_record(pnr12)
    record.update_attributes(from_student_data(pnr12, data))
  end

  def self.store_student_participation(data)
    source_pnr = data[:person][:extra][:pnr]
    pnr12 = get_pnr12(source_pnr)

    record = get_record(pnr12)
    student_data = from_student_data(pnr12, data[:person])
    participation_data = from_participation_data(data[:course])
    merged_data = student_data.merge(participation_data)
    record.update_attributes(merged_data)
  end

  # Rewrite participation data part of student participation message,
  # for merge with existing record.
  def self.from_participation_data(data)
    {
      categorycode: map_categorycode(data),
    }.compact
  end

  # Rewrite student_data in patron form to merge with existing record.
  # Therefor the hash is compacted first to get rid of nils
  def self.from_student_data(pnr12, data)
    output = {
      pnr12: pnr12,
      pnr: get_pnr10(pnr12),
    }
    if data[:name]
      output.merge!({
        firstname: data[:name][:firstname],
        surname: data[:name][:surname],
      })
    end
    if data[:address1]
      output.merge!({
        care_of: data[:address1][:care_of],
        street: data[:address1][:street],
        zip: data[:address1][:zip],
        city: data[:address1][:city],
        country: data[:address1][:country],
      })
    end
    if data[:address2]
      output.merge!({
        b_care_of: data[:address2][:care_of],
        b_street: data[:address2][:street],
        b_zip: data[:address2][:zip],
        b_city: data[:address2][:city],
        b_country: data[:address2][:country],
      })
    end
    if data[:contact]
      output.merge!({
        phone: data[:contact][:phone],
        email: data[:contact][:email],
      })
    end
    if data[:extra]
      output.merge!({
        account: data[:extra][:account],
      })
    end
    output.compact
  end

  # If there is a patron record already, fetch it and add to it,
  # otherwise return a new record
  def self.get_record(pnr12)
    Patron.where(pnr12: pnr12).first || Patron.new
  end

  # TODO: Actual parsing
  def self.map_categorycode(course_data)
    "SH"
  end

  # Return a 12 digit number from:
  # already 12, return it
  # length of 10, add 19 or 20 depending on first character to make it 12
  # otherwise return nil
  def self.get_pnr12(pnr)
    return nil if pnr.blank?
    return pnr if pnr.length.eql?(12)
    return "20" + pnr if pnr.length.eql?(10) && /^[0]/.match(pnr)
    return "19" + pnr if pnr.length.eql?(10) && /^[^0]/.match(pnr)
    return nil
  end

  # Since we call this with a pnr12, it will always be either
  # 12 digits long or nil
  def self.get_pnr10(pnr12)
    return nil if pnr12.blank?
    pnr12[2...12]
  end

  # Reference:
  #  t.text :firstname
  #  t.text :surname
  #  t.text :care_of
  #  t.text :street
  #  t.text :zip
  #  t.text :city
  #  t.text :country
  #  t.text :phone
  #  t.text :email
  #  t.text :b_care_of
  #  t.text :b_street
  #  t.text :b_zip
  #  t.text :b_city
  #  t.text :b_country
  #  t.text :categorycode
  #  t.text :account
  #  t.text :pnr
  #  t.text :pnr12

end
