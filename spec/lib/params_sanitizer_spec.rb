# frozen_string_literal: true

require "rails_helper"

describe "ParamsSanitizer", type: :concern do
  let(:valid_xml) { "PHJlc291cmNlIHhtbG5zOnhzaT0iaHR0cDovL3d3dy53My5vcmcvMjAwMS9YTUxTY2hlbWEtaW5zdGFuY2UiIHhtbG5zPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCIgeHNpOnNjaGVtYUxvY2F0aW9uPSJodHRwOi8vZGF0YWNpdGUub3JnL3NjaGVtYS9rZXJuZWwtNCBodHRwczovL3NjaGVtYS5kYXRhY2l0ZS5vcmcvbWV0YS9rZXJuZWwtNC40L21ldGFkYXRhLnhzZCI+CjxpZGVudGlmaWVyIGlkZW50aWZpZXJUeXBlPSJET0kiPjEwLjUwNzIvRDNQMjZRMzVSLVRlc3Q8L2lkZW50aWZpZXI+CjxjcmVhdG9ycz4KPGNyZWF0b3I+CjxjcmVhdG9yTmFtZSBuYW1lVHlwZT0iUGVyc29uYWwiPkZvc21pcmUsIE1pY2hhZWw8L2NyZWF0b3JOYW1lPgo8Z2l2ZW5OYW1lPk1pY2hhZWw8L2dpdmVuTmFtZT4KPGZhbWlseU5hbWU+Rm9zbWlyZTwvZmFtaWx5TmFtZT4KPC9jcmVhdG9yPgo8Y3JlYXRvcj4KPGNyZWF0b3JOYW1lIG5hbWVUeXBlPSJQZXJzb25hbCI+V2VydHosIFJ1dGg8L2NyZWF0b3JOYW1lPgo8Z2l2ZW5OYW1lPlJ1dGg8L2dpdmVuTmFtZT4KPGZhbWlseU5hbWU+V2VydHo8L2ZhbWlseU5hbWU+CjwvY3JlYXRvcj4KPGNyZWF0b3I+CjxjcmVhdG9yTmFtZSBuYW1lVHlwZT0iUGVyc29uYWwiPlB1cnplciwgU2VuYXk8L2NyZWF0b3JOYW1lPgo8Z2l2ZW5OYW1lPlNlbmF5PC9naXZlbk5hbWU+CjxmYW1pbHlOYW1lPlB1cnplcjwvZmFtaWx5TmFtZT4KPC9jcmVhdG9yPgo8L2NyZWF0b3JzPgo8dGl0bGVzPgo8dGl0bGUgeG1sOmxhbmc9ImVuIj5Dcml0aWNhbCBFbmdpbmVlcmluZyBMaXRlcmFjeSBUZXN0IChDRUxUKTwvdGl0bGU+CjwvdGl0bGVzPgo8cHVibGlzaGVyIHhtbDpsYW5nPSJlbiI+UHVyZHVlIFVuaXZlcnNpdHkgUmVzZWFyY2ggUmVwb3NpdG9yeSAoUFVSUik8L3B1Ymxpc2hlcj4KPHB1YmxpY2F0aW9uWWVhcj4yMDEzPC9wdWJsaWNhdGlvblllYXI+CjxzdWJqZWN0cz4KPHN1YmplY3QgeG1sOmxhbmc9ImVuIj5Bc3Nlc3NtZW50PC9zdWJqZWN0Pgo8c3ViamVjdCB4bWw6bGFuZz0iZW4iPkluZm9ybWF0aW9uIExpdGVyYWN5PC9zdWJqZWN0Pgo8c3ViamVjdCB4bWw6bGFuZz0iZW4iPkVuZ2luZWVyaW5nPC9zdWJqZWN0Pgo8c3ViamVjdCB4bWw6bGFuZz0iZW4iPlVuZGVyZ3JhZHVhdGUgU3R1ZGVudHM8L3N1YmplY3Q+CjxzdWJqZWN0IHhtbDpsYW5nPSJlbiI+Q0VMVDwvc3ViamVjdD4KPHN1YmplY3QgeG1sOmxhbmc9ImVuIj5QdXJkdWUgVW5pdmVyc2l0eTwvc3ViamVjdD4KPC9zdWJqZWN0cz4KPGxhbmd1YWdlPmVuPC9sYW5ndWFnZT4KPHJlc291cmNlVHlwZSByZXNvdXJjZVR5cGVHZW5lcmFsPSJEYXRhc2V0Ij5EYXRhc2V0PC9yZXNvdXJjZVR5cGU+Cjx2ZXJzaW9uPjEuMDwvdmVyc2lvbj4KPGRlc2NyaXB0aW9ucz4KPGRlc2NyaXB0aW9uIHhtbDpsYW5nPSJlbiIgZGVzY3JpcHRpb25UeXBlPSJBYnN0cmFjdCI+V2UgZGV2ZWxvcGVkIGFuIGluc3RydW1lbnQsIENyaXRpY2FsIEVuZ2luZWVyaW5nIExpdGVyYWN5IFRlc3QgKENFTFQpLCB3aGljaCBpcyBhIG11bHRpcGxlIGNob2ljZSBpbnN0cnVtZW50IGRlc2lnbmVkIHRvIG1lYXN1cmUgdW5kZXJncmFkdWF0ZSBzdHVkZW50c+KAmSBzY2llbnRpZmljIGFuZCBpbmZvcm1hdGlvbiBsaXRlcmFjeSBza2lsbHMuIEl0IHJlcXVpcmVzIHN0dWRlbnRzIHRvIGZpcnN0IHJlYWQgYSB0ZWNobmljYWwgbWVtbyBhbmQsIGJhc2VkIG9uIHRoZSBtZW1v4oCZcyBhcmd1bWVudHMsIGFuc3dlciBlaWdodCBtdWx0aXBsZSBjaG9pY2UgYW5kIHNpeCBvcGVuLWVuZGVkIHJlc3BvbnNlIHF1ZXN0aW9ucy4gV2UgY29sbGVjdGVkIGRhdGEgZnJvbSAxNDMgZmlyc3QteWVhciBlbmdpbmVlcmluZyBzdHVkZW50cyBhbmQgY29uZHVjdGVkIGFuIGl0ZW0gYW5hbHlzaXMuIFRoZSBLUi0yMCByZWxpYWJpbGl0eSBvZiB0aGUgaW5zdHJ1bWVudCB3YXMgLjM5LiBJdGVtIGRpZmZpY3VsdGllcyByYW5nZWQgYmV0d2VlbiAuMTcgdG8gLjgzLiBUaGUgcmVzdWx0cyBpbmRpY2F0ZSBsb3cgcmVsaWFiaWxpdHkgaW5kZXggYnV0IGFjY2VwdGFibGUgbGV2ZWxzIG9mIGl0ZW0gZGlmZmljdWx0aWVzIGFuZCBpdGVtIGRpc2NyaW1pbmF0aW9uIGluZGljZXMuIFN0dWRlbnRzIHdlcmUgbW9zdCBjaGFsbGVuZ2VkIHdoZW4gYW5zd2VyaW5nIGl0ZW1zIG1lYXN1cmluZyBzY2llbnRpZmljIGFuZCBtYXRoZW1hdGljYWwgbGl0ZXJhY3kgKGkuZS4sIGlkZW50aWZ5aW5nIGluY29ycmVjdCBpbmZvcm1hdGlvbikuPC9kZXNjcmlwdGlvbj4KPC9kZXNjcmlwdGlvbnM+CjwvcmVzb3VyY2U+" }
  describe "instance methods" do
    let(:params) { { "xml" => nil } }
    subject { ParamsSanitizer.new(params) }

    context "responds to its methods" do
      it { expect(subject).to respond_to(:cleanse) }
    end
  end


  describe "add_xml" do
    context "when xml is nil" do
      let(:params) { { "xml" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        expect(subject.add_xml).to eq(nil)
      end
    end

    context "when xml is empty" do
      let(:params) { { "xml" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        expect(subject.add_xml).to eq(nil)
      end
    end

    context "when xml is not string" do
      let(:params) { { "xml" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        expect(subject.add_xml).to eq(nil)
      end
    end

    context "when xml is string" do
      let(:params) { { "xml" => "<xml></xml>" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        expect(subject.add_xml).to eq(nil)
      end
    end

    context "when xml is correctly encoded b64 string" do
        let(:params) { { xml: valid_xml } }
        subject { ParamsSanitizer.new(params) }
        it "should return the xml" do
          expect(subject.add_xml).to eq(Base64.decode64(params[:xml]).force_encoding("UTF-8"))
        end
      end

    context "when xml has trailing spaces" do
      let(:params) { { xml: "PHhtbD48L3htbD4g" } }
      subject { ParamsSanitizer.new(params) }
      it "should remove trailing spaces" do
        expect(subject.add_xml).to eq("<xml></xml>")
      end
    end
  end


  describe "add_xml_attributes" do
    let(:params) { { "xml" => valid_xml } }
    context "when meta includes valid attributes" do
      let(:meta) { { "url" => nil, "language" => "en" } }
      subject { ParamsSanitizer.new(params) }
      it "it merges attributes that exist" do
        expect(subject.add_xml_attributes(meta)).to include(:url, :language)
      end
    end

    context "when meta is includes distribution and url" do
      let(:meta) { { "url" => "https://datacite.com", "address" => "https://datacite.com" } }
      subject { ParamsSanitizer.new(params) }
      it "it doesn't merges attributes that exist" do
        expect(subject.add_xml_attributes(meta)).not_to include(:address)
      end
    end
  end

  describe "add_metadata_version" do
    context "when params is nil" do
      let(:params) { { "version_info" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        subject.add_metadata_version(params)
        expect(subject.get_params[:version_info]).to eq(nil)
      end
    end

    context "when params is empty" do
      let(:params) { { "version_info" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_metadata_version(params)
        expect(subject.get_params[:version_info]).to eq(nil)
      end
    end

    context "when params is a hash" do
      let(:params) { { "version_info" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return input" do
        subject.add_metadata_version(params)
        expect(subject.get_params[:version_info]).equal?(123)
      end
    end
  end


  describe "add_random_id" do
    context "when params is nil" do
      let(:params) { { "prefix" => nil, "doi" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        subject.add_random_id
        expect(subject.get_params[:doi]).to eq(nil)
      end
    end

    context "when params is empty" do
      let(:params) { { "prefix" => "", "doi" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_random_id
        expect(subject.get_params[:doi]).to eq(nil)
      end
    end

    context "when params is not hash" do
      let(:params) { { "prefix" => 123, "doi" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_random_id
        expect(subject.get_params[:doi]).to eq(nil)
      end
    end

    context "when params is hash" do
      subject { ParamsSanitizer.new({ prefix: "10.1233", doi: "" }) }

      it "adds correctly random doi" do
        subject.add_random_id()
        expect(subject.get_params[:doi]).to start_with("10.1233")
      end
    end
  end


  describe "add_schema_version" do
    context "when params is nil" do
      let(:params) { { "schemaVersion" => nil } }
      subject { ParamsSanitizer.new(params) }

      it "should return nil" do
        subject.add_schema_version(params)
        expect(subject.get_params[:schemaVersion]).to eq(nil)
      end
    end

    context "when params is empty" do
      let(:params) { { "schemaVersion" => "" } }
      subject { ParamsSanitizer.new(params) }
      it "should return nil" do
        subject.add_schema_version(params)
        expect(subject.get_params[:schemaVersion]).to eq(nil)
      end
    end

    context "when params is hash" do
      let(:params) { { "schemaVersion" => 123 } }
      subject { ParamsSanitizer.new(params) }
      it "should return value" do
        subject.add_schema_version(params)
        expect(subject.get_params[:schemaVersion]).equal?(123)
      end
    end

    context "when params is hash and from is datacite " do
      subject { ParamsSanitizer.new({ schemaVersion: "3.1" }) }

      it "add schema version correctly" do
        subject.add_schema_version({ from: "datacite" })
        expect(subject.get_params[:schemaVersion]).equal?("3")
      end
    end
  end
end
