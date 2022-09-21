# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReferenceRepository, type: :model , elasticsearch: true do
  describe "Validations" do
    it { should validate_uniqueness_of(:re3doi).case_insensitive }
  end

  describe "Creation from client" do
    it "when a client is created" do
      client = create(:client)
      expect(
        ReferenceRepository.find_by(client_id: client.uid)
      ).not_to be_nil
    end

    it "gets assigned client_id from client" do
      client = create(:client)
      repository = ReferenceRepository.find_by(client_id: client.uid)
      expect(repository.client_id).to eq(client.uid)
    end

    it "gets assigned re3data_id from client" do
      client = create(:client, re3data_id: "10.17616/r3989r")
      repository = ReferenceRepository.find_by(client_id: client.uid)
      expect(repository.re3doi).not_to be_nil
      expect(repository.re3doi).to eq(client.re3data_id)
    end

    it "get nil re3data_id from client if client does not have re3data_id" do
      client = create(:client)
      repository = ReferenceRepository.find_by(client_id: client.uid)
      expect(repository.re3doi).to be_nil
    end
  end

  describe "Updates" do
    it "propegate from clients" do
      doi = "10.17616/r3989r"
      client = create(:client)

      expect(client.re3data_id).to be_nil
      repository = ReferenceRepository.find_by(client_id: client.uid)
      expect(repository.re3doi).to be_nil

      client.re3data = "https://doi.org/" + doi
      expect(client.save).to be true
      expect(client.re3data_id).to eq(doi)

      repository = ReferenceRepository.find_by(client_id: client.uid)
      expect(repository.re3doi).to eq(doi)
    end

    it "propegate from clients but re3data_id  exists" do
      Rails.logger.level = :fatal
      doi = "10.17616/R3P01C"
      create(:reference_repository, re3doi: doi)

      client = create(:client)
      expect(client.re3data_id).to be_nil
      repository_client = ReferenceRepository.find_by(client_id: client.uid)
      expect(repository_client.re3doi).to be_nil

      expect(
        client.update({ re3data: "https://doi.org/" + doi })
      ).to be true
      expect(client.re3data_id).to eq(doi)

      repository_client2 = ReferenceRepository.find_by(client_id: client.uid)
      expect(repository_client2.re3doi).to eq(doi.downcase)
    end
  end

  describe "Deletes" do
    it "propegate from clients" do
      Rails.logger.level = :fatal
      client = create(:client)
      expect(
        ReferenceRepository.find_by(client_id: client.uid)
      ).not_to be_nil
      client.destroy!
      expect(
        ReferenceRepository.find_by(client_id: client.uid)
      ).to be_nil
    end
  end
end
