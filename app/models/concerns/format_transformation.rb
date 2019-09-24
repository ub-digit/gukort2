module FormatTransformation
  def xml_to_json(xml)
    hash_data = xml_to_hash(xml)
    json_data = hash_data.to_json
  end

  def xml_to_hash(data)
    hash_data = Hash.from_xml data
  end

  def clean_xml_from_mq_metadata(mq_xml)
    start = mq_xml.index("<?xml")
    stop = mq_xml.length
    xml = mq_xml.slice(start..stop)
  end
end
