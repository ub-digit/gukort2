class ApplicationController < ActionController::API
  def reencode(data, source_encoding)
    if source_encoding == "ISO-8859-1"
      data.force_encoding("ISO-8859-1").encode("UTF-8")
    else
      data.force_encoding("UTF-8")
    end

    return data
  end

  def store_xml(data, file_prefix)
    File.open("output/#{file_prefix}-#{Time.now.utc.strftime("%F_%H%M%S_%9N")}.xml", "w") do |file|
      file << data
    end
  end
end
