class LogoUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  permissions 0777

  def store_dir
    "images/members/"
  end

  # fallback URL if no logo stored
  def default_url(*args)
    "#{ENV['CDN_URL']}/images/members/default.png"
  end

  process resize_to_fit: [500, 200]

  def extension_whitelist
    %w(jpg jpeg png)
  end

  def content_type_whitelist
    %w(image/jpeg image/png)
  end

  def filename
    model.symbol.downcase + "." + file.extension if original_filename.present?
  end
end
