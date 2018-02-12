require 'rails_helper'

RSpec.describe ElasticsearchJob, type: :job do
  let(:bearer) { User.generate_token }
  let(:provider) { create(:provider, password_input: "12345") }
  let!(:client) { create(:client, provider: provider) }
  let(:params) do
    { "data" => { "type" => "clients",
                  "attributes" => {
                    "symbol" => provider.symbol + ".IMPERIAL",
                    "name" => "Imperial College",
                    "contact-name" => "Madonna",
                    "contact-email" => "bob@example.com"
                  },
                  "relationships": {
              			"provider": {
              				"data":{
              					"type": "providers",
              					"id": provider.symbol.downcase
              				}
              			}
                  }} }
  end
  subject(:job) { ElasticsearchJob.perform_later(params) }

  it 'queues the job' do
    expect { job }.to have_enqueued_job(ElasticsearchJob)
      .on_queue("default")
  end
end