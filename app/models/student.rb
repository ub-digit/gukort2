require "pp"

class Student
  include StudentParsingComponents
  include FormatTransformation

  attr_reader :extra,:addr1,:addr2

  def initialize(data, msg)
    @raw = data
    @msg = msg
    if !data["personRecord"]
      raise StandardError, "Student message does not contain key: personRecord"
    end
    parse(data["personRecord"]["person"])
    Rails.logger.debug self.extra
  end

  def process_student
    handle_student
  end

  def handle_student
    begin
      basic_data = Koha.get_basic_data(@pnr)
    rescue => e
      @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
      return
    end
    #Does user exist in Koha?
    if basic_data[:borrowernumber]
      # Is user a student according to Koha
      if is_student?(basic_data[:categorycode])
        handle_pnr(basic_data)
        begin
          Koha.update({
            borrowernumber: basic_data[:borrowernumber],
            patronuserid: @extra[:account],
            new_pnr: @new_pnr,
            # TODO: addresses
            firstname: @name[:firstname],
            surname: @name[:surname],
            phone: @contact[:phone],
            email: @contact[:email]
          })
        rescue => e
          @msg.append_response([__FILE__, __method__, __LINE__, e.message].inspect)
        end
      end
    end
  end

  def handle_pnr(basic_data)
    @new_pnr = nil
    # Is there a new pnr and person is not employed at GU
    if @extra[:pnr_new] && !basic_data[:expirationdate]
      @new_pnr = @extra[:pnr_new]

      issued_state = IssuedState.where(pnr: @pnr).first
      issued_state_new_pnr = IssuedState.where(pnr: @new_pnr).first

      if !issued_state && !issued_state_new_pnr
        return
      end

      # There are possibly two lines, one for each pnr. Take the
      # latest date and use that in the new line, remove both the
      # original ones.
      expiration_dates = []
      if issued_state
        expiration_dates << issued_state[:expiration_date]
        issued_state.destroy
      end

      if issued_state_new_pnr
        expiration_dates << issued_state_new_pnr[:expiration_date]
        issued_state_new_pnr.destroy
      end

      max_date = expiration_dates.sort.first
      IssuedState.create(pnr: @new_pnr, expiration_date: max_date)
    end
  end
  
  def as_json(opt = {})
    {
      name: @name,
      address1: @addr1,
      address2: @addr2,
      contact: @contact,
      extra: @extra,
      pnr: @pnr
    }
  end

  def parse(data)
    @name = parse_name(data["name"])
    @addr1 = parse_address(data["address"], "POSTADRESS")
    @addr2 = parse_address(data["address"], "FOLKBOKFORINGSADRESS")
    @contact = parse_contact(data["contactinfo"])
    @extra = parse_extension(data["extension"])
    # For consistency with other queue data parsers
    @pnr = @extra[:pnr]
  end

  def parse_extension(extensiondata)
    pnr = get_extension(extensiondata, "PersonIdentityNumber")
    pnr_old = get_extension(extensiondata, "PersonIdentityNumberOld")
    if pnr_old
      pnr_new = pnr
      pnr = pnr_old
    end
    
    account = get_extension(extensiondata, "StudentAccountName")
    account_email = get_extension(extensiondata, "StudentAccountEmail")

    # Doktorand
    account2 = get_extension(extensiondata, "DocAccountName")
    account_email2 = get_extension(extensiondata, "DocAccountEmail")
    # Also DeceasedFlag and ProtectedIdentifyFlag which will be ignored
    {
      pnr: pnr,
      pnr_new: pnr_new,
      account: account,
      account_email: account_email,
      account2: account2,
      account_email2: account_email2,
    }
  end

  def parse_contact(contactdata)
    phone = get_contact(contactdata, "TelephonePrimary")
    email = get_contact(contactdata, "EmailPrimary")
    {
      phone: phone,
      email: email,
    }
  end

  def parse_address(addressdata, addr_type)
    care_of = get_address(addressdata, addr_type, "CareOf")
    street = get_address(addressdata, addr_type, "NonfieldedStreetAddress1")
    zip = get_address(addressdata, addr_type, "Postcode")
    city = get_address(addressdata, addr_type, "City")
    country = get_address(addressdata, addr_type, "Country")
    {
      care_of: care_of,
      street: street,
      zip: zip,
      city: city,
      country: country,
    }
  end

  def parse_name(namedata)
    firstname = get_name(namedata, "FullName", "First")
    surname = get_name(namedata, "FullName", "Surname")
    {
      firstname: firstname,
      surname: surname,
    }
  end

  def get_name(namedata, instance_type, instance_name)
    # Need to put namedata in array to reuse get_instance_of_type()
    get_instance_of_type([namedata], "nameType", "partName", instance_type, instance_name)
  end

  def get_address(addressdata, instance_type, instance_name)
    get_instance_of_type(addressdata, "addressType", "addressPart", instance_type, instance_name)
  end

  def get_contact(contactdata, instance_type)
    get_value_of_type(contactdata, "contactinfoType", "contactinfoValue", instance_type)
  end

  def get_extension(extensiondata, field_name)
    get_field(extensiondata["extensionField"], field_name)
  end
end
