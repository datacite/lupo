require 'rails_helper'

describe Media, type: :model do
  it { should validate_presence_of(:url) }
  it { should validate_presence_of(:media_type) }
end

context "validations" do
  let(:provider)  { create(:provider, symbol: "ADMIN") }
  let(:client)  { create(:client, provider: provider) }
  let(:doi) { create(:doi, client: client) }

  it "URL valid" do
    subject = build(:media, url: "https://example.org")
    expect(subject).to be_valid
    expect(subject.url).to eq("https://example.org")
    expect(subject.version).to eq(0)
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
    expect(subject.version).to eq(0)
  end

  it "Media type invalid" do
    subject = build(:media, media_type: "text")
    expect(subject).to_not be_valid
    expect(subject.media_type).to eq("text")
  end
end
