class MetadataValidator < ActiveModel::EachValidator

  include Bolognese::Utils
  include Bolognese::DoiUtils

  def validate_each(record, xml, value)
    metadata_file = Bolognese::Metadata.new(input: Base64.decode64(value), regenerate: true)
    unless  metadata_file.valid?
      record.errors[xml] << (metadata_file.errors || "Your XML is wrong mate!!")
    end
  end
end
