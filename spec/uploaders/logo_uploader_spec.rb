require "rails_helper"

describe LogoUploader, type: :uploader do
  let(:provider) { create(:provider) }
  let(:uploader) { LogoUploader.new(provider, :logo) }

  before do
    LogoUploader.enable_processing = true
    File.open(file_fixture("bl.png")) { |f| uploader.store!(f) }
  end

  after do
    LogoUploader.enable_processing = false
    uploader.remove!
  end

  context 'resize to fit' do
    it "resizes a landscape image to fit within 500 by 200 pixels" do
      expect(uploader).to be_no_larger_than(500, 200)
    end
  end

  it "makes the image publicly readable and not executable" do
    expect(uploader).to have_permissions(0644)
  end

  it "keeps the filename" do
    expect(uploader.filename).to eq(provider.symbol.downcase + ".png")
  end

  it "has the correct format" do
    expect(uploader).to be_format("png")
  end

  it "has the correct content type" do
    expect(uploader.content_type).to eq("image/png")
  end
end
