# frozen_string_literal: true

require "rails_helper"

describe "MDS routing", type: :routing do
  let(:mds_host) { "mds.local" }

  def mds_url(path)
    "http://#{mds_host}#{path}"
  end

  describe "when Host is an MDS host" do
    it "routes GET /doi to mds/dois#index" do
      expect(get: mds_url("/doi")).to route_to("mds/dois#index")
    end

    it "routes GET /doi/:id with slashes to mds/dois#show" do
      expect(get: mds_url("/doi/10.14454/abc")).to route_to(
        "mds/dois#show", id: "10.14454/abc",
      )
    end

    it "routes PUT /doi/:id to mds/dois#update" do
      expect(put: mds_url("/doi/10.14454/abc")).to route_to(
        "mds/dois#update", id: "10.14454/abc",
      )
    end

    it "routes DELETE /doi/:id to mds/dois#destroy" do
      expect(delete: mds_url("/doi/10.14454/abc")).to route_to(
        "mds/dois#destroy", id: "10.14454/abc",
      )
    end

    it "routes POST /doi to mds/dois#update" do
      expect(post: mds_url("/doi")).to route_to("mds/dois#update")
    end

    it "routes PUT /metadata/:doi_id to mds/metadata#create" do
      expect(put: mds_url("/metadata/10.14454/abc")).to route_to(
        "mds/metadata#create", doi_id: "10.14454/abc",
      )
    end

    it "routes GET /metadata/:doi_id to mds/metadata#show" do
      expect(get: mds_url("/metadata/10.14454/abc")).to route_to(
        "mds/metadata#show", doi_id: "10.14454/abc",
      )
    end

    it "routes DELETE /metadata/:doi_id to mds/metadata#destroy" do
      expect(delete: mds_url("/metadata/10.14454/abc")).to route_to(
        "mds/metadata#destroy", doi_id: "10.14454/abc",
      )
    end

    it "routes GET /media/:doi_id to mds/media#index" do
      expect(get: mds_url("/media/10.14454/abc")).to route_to(
        "mds/media#index", doi_id: "10.14454/abc",
      )
    end

    it "routes POST /media/:doi_id to mds/media#create" do
      expect(post: mds_url("/media/10.14454/abc")).to route_to(
        "mds/media#create", doi_id: "10.14454/abc",
      )
    end

    it "routes nested media under /doi" do
      expect(get: mds_url("/doi/10.14454/abc/media")).to route_to(
        "mds/media#index", doi_id: "10.14454/abc",
      )
    end

    it "routes GET /heartbeat to mds/heartbeat#index" do
      expect(get: mds_url("/heartbeat")).to route_to("mds/heartbeat#index")
    end

    it "routes GET /login to mds/index#login" do
      expect(get: mds_url("/login")).to route_to("mds/index#login")
    end
  end

  describe "when Host is not an MDS host" do
    it "does not route classic /doi on default host to MDS controllers" do
      expect(get: "http://www.example.com/doi/10.14454/abc").not_to route_to(
        "mds/dois#show", id: "10.14454/abc",
      )
    end

    it "still routes REST /dois on the default host" do
      expect(get: "http://www.example.com/dois").to route_to("datacite_dois#index")
    end

    it "does not treat example.org as an MDS host" do
      expect(get: "http://example.org/doi").not_to route_to("mds/dois#index")
    end
  end
end

