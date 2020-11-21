require "rails_helper"

describe Media, type: :model do
  it { should validate_presence_of(:url) }
end

context "validations" do
  let(:provider) { create(:provider, symbol: "ADMIN") }
  let(:client) { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client) }

  it "URL valid" do
    subject = build(:media, url: "https://example.org")
    expect(subject).to be_valid
    expect(subject.url).to eq("https://example.org")
  end

  it "URL valid ftp" do
    subject = build(:media, url: "ftp://example.org")
    expect(subject).to be_valid
    expect(subject.url).to eq("ftp://example.org")
  end

  it "URL valid s3" do
    subject = build(:media, url: "s3://example.org")
    expect(subject).to be_valid
    expect(subject.url).to eq("s3://example.org")
  end

  it "URL valid gs" do
    subject = build(:media, url: "gs://example.org")
    expect(subject).to be_valid
    expect(subject.url).to eq("gs://example.org")
  end

  it "URL valid dos" do
    subject = build(:media, url: "dos://example.org")
    expect(subject).to be_valid
    expect(subject.url).to eq("dos://example.org")
  end

  it "URL invalid" do
    subject = build(:media, url: "mailto:info@example.org")
    expect(subject).to_not be_valid
    expect(subject.url).to eq("mailto:info@example.org")
  end

  it "Media type valid" do
    subject = build(:media, media_type: "text/plain")
    expect(subject).to be_valid
    expect(subject.media_type).to eq("text/plain")
  end

  it "Media type invalid" do
    subject = build(:media, media_type: "text")
    expect(subject).to_not be_valid
    expect(subject.media_type).to eq("text")
  end

  it "Media type not unique" do
    media = create(:media, doi: doi)
    subject = build(:media, doi: doi, media_type: "text/plain")
    expect(subject).to be_valid
    expect(subject.media_type).to eq("text/plain")
  end
end
