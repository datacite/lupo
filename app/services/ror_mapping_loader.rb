# frozen_string_literal: true

class RorMappingLoader
  FUNDERS_PATH   = Rails.root.join("app/resources/funder_to_ror.json")
  HIERARCHY_PATH = Rails.root.join("app/resources/ror_hierarchy.json")

  S3_FUNDER_KEY = "ror_funder_mapping/funder_to_ror.json"
  S3_HIERARCHY_KEY = "ror_funder_mapping/ror_hierarchy.json"

  def self.load!
    ensure_files_exist!
    load_into_memory!
  end

  def self.ensure_files_exist!
    return if FUNDERS_PATH.exist? && HIERARCHY_PATH.exist?

    Rails.logger.info("[ROR] Local mappings missing, downloading from S3")

    s3 = Aws::S3::Client.new(region: ENV.fetch("AWS_REGION"))

    atomic_download(s3, S3_FUNDER_KEY, FUNDERS_PATH)
    atomic_download(s3, S3_HIERARCHY_KEY, HIERARCHY_PATH)
  end

  def self.atomic_download(s3, key, path)
    FileUtils.mkdir_p(path.dirname)

    tmp = "#{path}.tmp"

    resp = s3.get_object(
      bucket: ENV.fetch("ROR_ANALYSIS_S3_BUCKET"),
      key: key
    )

    File.open(tmp, "wb") { |f| f.write(resp.body.read) }
    FileUtils.mv(tmp, path)
  rescue Aws::S3::Errors::ServiceError => e
    raise "[ROR] Failed to download #{key} from S3: #{e.message}"
  end

  def self.load_into_memory!
    funders   = JSON.parse(File.read(FUNDERS_PATH))
    hierarchy = JSON.parse(File.read(HIERARCHY_PATH))

    Object.send(:remove_const, :FUNDER_TO_ROR) if defined?(FUNDER_TO_ROR)
    Object.send(:remove_const, :ROR_HIERARCHY) if defined?(ROR_HIERARCHY)

    Object.const_set(:FUNDER_TO_ROR, funders.freeze)
    Object.const_set(:ROR_HIERARCHY, hierarchy.freeze)

    Rails.logger.info(
      "[ROR] Loaded mappings: funder_to_ror=#{FUNDER_TO_ROR.size}, " \
      "ror_hierarchy=#{ROR_HIERARCHY.size}"
    )
  rescue JSON::ParserError => e
    raise "[ROR] Invalid JSON in ROR mapping files: #{e.message}"
  end
end
