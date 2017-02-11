require 'spec_helper'

describe Maremma do
  subject { Maremma }
  let(:url) { "http://example.org" }
  let(:data) { { "name" => "Fred" } }
  let(:post_data) { { "name" => "Jack" } }
  let(:accept_header) { "text/html,application/json,application/xml;q=0.9, text/plain;q=0.8,image/png,*/*;q=0.5" }

  context "get" do
    it "get json" do
      stub = stub_request(:get, url).to_return(:body => data.to_json, :status => 200, :headers => { "Content-Type" => "application/json" })
      response = subject.get(url)
      expect(response.body).to eq("data" => data)
      expect(response.headers).to eq("Content-Type"=>"application/json")
      expect(stub).to have_been_requested
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "application/xml" })
      response = subject.get(url, accept: 'xml')
      expect(response.body).to eq("data"=>data)
      expect(response.headers).to eq("Content-Type"=>"application/xml")
      expect(stub).to have_been_requested
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:body => data.to_s, :status => 200, :headers => { "Content-Type" => "text/html" })
      response = subject.get(url, accept: 'html')
      expect(response.body).to eq("data" => data.to_s)
      expect(response.headers).to eq("Content-Type"=>"text/html")
      expect(stub).to have_been_requested
    end

    it "get json with params", vcr: true do
      params = { q: "*:*",
                 fl: "doi,title,description,publisher,publicationYear,resourceType,resourceTypeGeneral,rightsURI,datacentre_symbol,xml,minted,updated",
                 fq: %w(has_metadata:true is_active:true),
                 facet: "true",
                 'facet.field' => %w(resourceType_facet publicationYear datacentre_facet),
                 'facet.limit' => 10,
                 'f.resourceType_facet.facet.limit' => 15,
                 wt: "json" }.compact
      url = "https://search.datacite.org/api?" + URI.encode_www_form(params)
      expect(url).to eq("https://search.datacite.org/api?q=*%3A*&fl=doi%2Ctitle%2Cdescription%2Cpublisher%2CpublicationYear%2CresourceType%2CresourceTypeGeneral%2CrightsURI%2Cdatacentre_symbol%2Cxml%2Cminted%2Cupdated&fq=has_metadata%3Atrue&fq=is_active%3Atrue&facet=true&facet.field=resourceType_facet&facet.field=publicationYear&facet.field=datacentre_facet&facet.limit=10&f.resourceType_facet.facet.limit=15&wt=json")
      response = subject.get(url)
      facet_fields = response.body.fetch("data", {}).fetch("facet_counts", {}).fetch("facet_fields", {})
      expect(facet_fields["datacentre_facet"].each_slice(2).first).to eq(["CDL.DPLANET - Data-Planet", 866368])
      expect(facet_fields["resourceType_facet"].each_slice(2).first).to eq(["Dataset", 2875784])
      expect(facet_fields["publicationYear"].each_slice(2).first).to eq(["2015", 2050685])
    end

    it "get json with meta hash" do
      data = { "data" => { "name" => "Jack" }, "meta" => { "count" => 12 }}
      stub = stub_request(:get, url).to_return(:body => data.to_json, :status => 200, :headers => { "Content-Type" => "application/json" })
      response = subject.get(url)
      expect(response.body).to eq("data"=>{"name"=>"Jack"}, "meta"=>{"count"=>12})
      expect(response.headers).to eq("Content-Type"=>"application/json")
      expect(stub).to have_been_requested
    end

    it "get xml raw" do
      stub = stub_request(:get, url).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "application/xml" })
      response = subject.get(url, accept: 'xml', raw: true)
      expect(response.body).to eq("data"=>data.to_xml)
      expect(response.headers).to eq("Content-Type"=>"application/xml")
      expect(stub).to have_been_requested
    end
  end

  context "head" do
    it "head html" do
      stub = stub_request(:head, url).to_return(:body => data.to_s, :status => 200, :headers => { "Content-Type" => "text/html" })
      response = subject.head(url, accept: 'html')
      expect(response.body).to be_nil
      expect(response.headers).to eq("Content-Type"=>"text/html")
      expect(stub).to have_been_requested
    end
  end

  context "post" do
    it "post json" do
      stub = stub_request(:post, url).with(:body => post_data.to_json).to_return(:body => data.to_json, :status => 200, :headers => { "Content-Type" => "application/json" })
      subject.post(url, content_type: 'json', data: post_data.to_json) { |response| expect(response.body).to eq(2) }
      expect(stub).to have_been_requested
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "text/html" })
      subject.post(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.body.to_s)["hash"]).to eq(data) }
      expect(stub).to have_been_requested
    end
  end

  context "put" do
    it "put json" do
      stub = stub_request(:put, url).with(:body => post_data.to_json).to_return(:body => data.to_json, :status => 200, :headers => { "Content-Type" => "application/json" })
      subject.put(url, content_type: 'json', data: post_data.to_json) { |response| expect(JSON.parse(response.body.to_s)).to eq(data) }
      expect(stub).to have_been_requested
    end

    it "put xml" do
      stub = stub_request(:put, url).with(:body => post_data.to_xml).to_return(:body => data.to_xml, :status => 200, :headers => { "Content-Type" => "text/html" })
      subject.put(url, content_type: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.body.to_s)["hash"]).to eq(data) }
      expect(stub).to have_been_requested
    end
  end

  context "empty response" do
    it "get json" do
      stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/json" })
      response = subject.get(url)
      expect(response.body).to eq("data"=>nil)
      expect(response.headers).to eq("Content-Type"=>"application/json")
      expect(stub).to have_been_requested
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/xml" })
      response = subject.get(url, accept: 'xml')
      expect(response.body).to eq("data"=>nil)
      expect(response.headers).to eq("Content-Type"=>"application/xml")
      expect(stub).to have_been_requested
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "text/html" })
      response = subject.get(url, accept: 'html')
      expect(response.body).to eq("data" => nil)
      expect(response.headers).to eq("Content-Type"=>"text/html")
      expect(stub).to have_been_requested
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/xml" })
      subject.post(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to eq("data" => nil) }
      expect(stub).to have_been_requested
    end

    it "put xml" do
      stub = stub_request(:put, url).with(:body => post_data.to_xml).to_return(:body => nil, :status => 200, :headers => { "Content-Type" => "application/xml" })
      subject.put(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to eq("data" => nil) }
      expect(stub).to have_been_requested
    end
  end

  context "not found" do
    let(:error) { { "errors" => [{ "status" => 404, "title" => "Not found" }]} }

    it "get json" do
      stub = stub_request(:get, url).to_return(:body => error.to_json, :status => [404], :headers => { "Content-Type" => "application/json" })
      response = subject.get(url, accept: 'json')
      expect(response.body).to eq(error)
      expect(stub).to have_been_requested
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:body => error.to_xml, :status => [404], :headers => { "Content-Type" => "application/xml" })
      response = subject.get(url, accept: 'xml')
      expect(response.body).to eq(error)
      expect(stub).to have_been_requested
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:body => error.to_s, :status => [404], :headers => { "Content-Type" => "text/html" })
      response = subject.get(url, accept: 'html')
      expect(response.body).to eq(error)
      expect(stub).to have_been_requested
    end

    it "head html" do
      stub = stub_request(:head, url).to_return(:body => error.to_s, :status => [404], :headers => { "Content-Type" => "text/html" })
      response = subject.head(url, accept: 'html')
      expect(response.status).to eq(404)
      expect(stub).to have_been_requested
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:body => error.to_xml, :status => [404], :headers => { "Content-Type" => "application/xml" })
      subject.post(url, accept: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.to_s)["hash"]).to eq(error) }
      expect(stub).to have_been_requested
    end

    it "put xml" do
      stub = stub_request(:put, url).with(:body => post_data.to_xml).to_return(:body => error.to_xml, :status => [404], :headers => { "Content-Type" => "application/xml" })
      subject.put(url, accept: 'xml', data: post_data.to_xml) { |response| expect(Hash.from_xml(response.to_s)["hash"]).to eq(error) }
      expect(stub).to have_been_requested
    end
  end

  context "request timeout" do
    it "get json" do
      stub = stub_request(:get, url).to_return(:status => [408])
      response = subject.get(url)
      expect(response.body).to eq("errors"=>[{"status"=>408, "title"=>"Request timeout"}])
      expect(stub).to have_been_requested
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(:status => [408])
      response = subject.get(url, accept: 'xml')
      expect(response.body).to eq("errors"=>[{"status"=>408, "title"=>"Request timeout"}])
      expect(stub).to have_been_requested
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(:status => [408])
      response = subject.get(url, accept: 'html')
      expect(response.body).to eq("errors"=>[{"status"=>408, "title"=>"Request timeout"}])
      expect(stub).to have_been_requested
    end

    it "head html" do
      stub = stub_request(:head, url).to_return(:status => [408])
      response = subject.head(url, accept: 'html')
      expect(response.status).to eq(408)
      expect(stub).to have_been_requested
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_return(:status => [408])
      subject.post(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end

    it "put xml" do
      stub = stub_request(:put, url).with(:body => post_data.to_xml).to_return(:status => [408])
      subject.put(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end
  end

  context "delete" do
    it "delete" do
      stub = stub_request(:delete, url).to_return(:status => 204, :headers => { "Content-Type" => "text/html" })
      response = subject.delete(url)
      expect(response.body).to eq("data"=>nil)
      expect(response.headers).to eq("Content-Type"=>"text/html")
      expect(response.status).to eq(204)
      expect(stub).to have_been_requested
    end
  end

  context "connection failed" do
    it "get json" do
      stub = stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new("Connection refused - connect(2)"))
      response = subject.get(url)
      expect(response.body).to eq("errors"=>[{"status"=>"403", "title"=>"Connection refused - connect(2)"}])
      expect(stub).to have_been_requested
    end

    it "get xml" do
      stub = stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new("Connection refused - connect(2)"))
      response = subject.get(url, accept: 'xml')
      expect(response.body).to eq("errors"=>[{"status"=>"403", "title"=>"Connection refused - connect(2)"}])
      expect(stub).to have_been_requested
    end

    it "get html" do
      stub = stub_request(:get, url).to_raise(Faraday::ConnectionFailed.new("Connection refused - connect(2)"))
      response = subject.get(url, accept: 'html')
      expect(response.body).to eq("errors"=>[{"status"=>"403", "title"=>"Connection refused - connect(2)"}])
      expect(stub).to have_been_requested
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_raise(Faraday::ConnectionFailed.new("Connection refused - connect(2)"))
      subject.post(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end

    it "put xml" do
      stub = stub_request(:put, url).with(:body => post_data.to_xml).to_raise(Faraday::ConnectionFailed.new("Connection refused - connect(2)"))
      subject.put(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end
  end

  context "request timeout internal" do
    it "get json" do
      stub = stub_request(:get, url).to_timeout
      response = subject.get(url)
      expect(response.body).to eq("errors"=>[{"status"=>408, "title"=>"Request timeout"}])
      expect(stub).to have_been_requested
    end

    it "get xml" do
      stub = stub_request(:get, url).to_timeout
      response = subject.get(url, accept: 'xml')
      expect(response.body).to eq("errors"=>[{"status"=>408, "title"=>"Request timeout"}])
      expect(stub).to have_been_requested
    end

    it "get html" do
      stub = stub_request(:get, url).to_timeout
      response = subject.get(url, accept: 'html')
      expect(response.body).to eq("errors"=>[{"status"=>408, "title"=>"Request timeout"}])
      expect(stub).to have_been_requested
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml).to_timeout
      subject.post(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end

    it "put xml" do
      stub = stub_request(:put, url).with(:body => post_data.to_xml).to_timeout
      subject.put(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end
  end

  context "rate limit exceeded" do
    it "get json" do
      stub = stub_request(:get, url).to_return(status: 200, headers: { 'X-Rate-Limit-Remaining' => 3 })
      response = subject.get(url)
      expect(response.body).to eq("errors"=>[{"status"=>429, "title"=>"Too many requests"}])
      expect(stub).to have_been_requested
    end

    it "get xml" do
      stub = stub_request(:get, url).to_return(status: 200, headers: { 'X-Rate-Limit-Remaining' => 3 })
      response = subject.get(url, accept: 'xml')
      expect(response.body).to eq("errors"=>[{"status"=>429, "title"=>"Too many requests"}])
      expect(stub).to have_been_requested
    end

    it "get html" do
      stub = stub_request(:get, url).to_return(status: 200, headers: { 'X-Rate-Limit-Remaining' => 3 })
      response = subject.get(url, accept: 'html')
      expect(response.body).to eq("errors"=>[{"status"=>429, "title"=>"Too many requests"}])
      expect(stub).to have_been_requested
    end

    it "post xml" do
      stub = stub_request(:post, url).with(:body => post_data.to_xml)
        .to_return(status: 200, headers: { 'X-Rate-Limit-Remaining' => 3 })
      subject.post(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end

    it "put xml" do
      stub = stub_request(:put, url).with(:body => post_data.to_xml)
        .to_return(status: 200, headers: { 'X-Rate-Limit-Remaining' => 3 })
      subject.put(url, accept: 'xml', data: post_data.to_xml) { |response| expect(response.body).to be_nil }
      expect(stub).to have_been_requested
    end
  end

  context "redirect requests" do
    let(:redirect_url) { "http://www.example.org/redirect" }

    it "redirect" do
      stub_request(:get, url).to_return(status: 301, headers: { location: redirect_url })
      stub_request(:get, redirect_url).to_return(status: 200, body: "Test")
      response = subject.get(url)
      expect(response.body).to eq("data"=>"Test")
      expect(response.url).to eq("http://www.example.org/redirect")
    end

    it "redirect four times" do
      stub_request(:get, url).to_return(status: 301, headers: { location: redirect_url })
      stub_request(:get, redirect_url).to_return(status: 301, headers: { location: redirect_url + "/x" })
      stub_request(:get, redirect_url+ "/x").to_return(status: 301, headers: { location: redirect_url + "/y" })
      stub_request(:get, redirect_url+ "/y").to_return(status: 301, headers: { location: redirect_url + "/z" })
      stub_request(:get, redirect_url + "/z").to_return(status: 200, body: "Test")
      response = subject.get(url)
      expect(response.body).to eq("data"=>"Test")
    end

    it "redirect limit 1" do
      stub_request(:get, url).to_return(status: 301, headers: { location: redirect_url })
      stub_request(:get, redirect_url).to_return(status: 301, headers: { location: redirect_url + "/x" })
      stub_request(:get, redirect_url+ "/x").to_return(status: 301, headers: { location: redirect_url + "/y" })
      response = subject.get(url, limit: 1)
      expect(response.body).to eq("errors"=>[{"status"=>400, "title"=>"too many redirects; last one to: http://www.example.org/redirect/x"}])
    end

    it "redirect limit 0" do
      stub_request(:get, url).to_return(status: 301, headers: { location: redirect_url })
      response = subject.get(url, limit: 0)
      expect(response.headers["Location"]).to eq("http://www.example.org/redirect")
    end

    it "redirect limit 0 head" do
      stub_request(:head, url).to_return(status: 301, headers: { location: redirect_url })
      response = subject.head(url, limit: 0)
      expect(response.headers["Location"]).to eq("http://www.example.org/redirect")
    end
  end

  context "content negotiation" do
    it "redirects to URL", vcr: true do
      url = "https://doi.org/10.5281/ZENODO.21430"
      response = subject.get(url)
      doc = Nokogiri::HTML(response.body.fetch("data", ""))
      title = doc.at_css("head title").text
      expect(title).to eq("DataCite-ORCID: 1.0 | Zenodo")
    end

    it "returns content as bibtex", vcr: true do
      url = "https://doi.org/10.5281/ZENODO.21430"
      response = subject.get(url, accept: "application/x-bibtex")
      expect(response.body.fetch("data", nil)).to eq("@misc{https://doi.org/10.5281/ZENODO.21430,\n  doi = {10.5281/ZENODO.21430},\n  url = {https://doi.org/10.5281/ZENODO.21430},\n  author = {Martin Fenner and Karl Jonathan Ward and Gudmundur A. Thorisson and Robert Peters},\n  publisher = {Zenodo},\n  title = {DataCite-ORCID: 1.0},\n  year = {2015}\n}")
    end

    it "returns content as APA-formatted citation", vcr: true do
      url = "https://doi.org/10.5281/ZENODO.21430"
      response = subject.get(url, accept: "text/x-bibliography; style=apa")
      expect(response.body.fetch("data", nil)).to eq("Martin Fenner, Karl Jonathan Ward, Gudmundur A. Thorisson, & Robert Peters. (2015). DataCite-ORCID: 1.0. Zenodo. https://doi.org/10.5281/ZENODO.21430")
    end
  end

  context "link headers" do
    it "parses link headers", vcr: true do
      url = "https://search.datacite.org/works/10.5281/ZENODO.21430"
      response = subject.get(url)
      headers = response.headers.fetch("Link", "").split(", ")
      expect(headers.first).to eq("<https://doi.org/10.5281/ZENODO.21430> ; rel=\"identifier\"")
    end
  end

  context 'parse_error_response' do
    it 'json' do
      string = '{ "error": "An error occured." }'
      expect(subject.parse_error_response(string)).to eq("An error occured.")
    end

    it 'json not error' do
      string = '{ "customError": "An error occured." }'
      expect(subject.parse_error_response(string)).to eq("customError"=>"An error occured.")
    end

    it 'xml' do
      string = '<error>An error occured.</error>'
      expect(subject.parse_error_response(string)).to eq("An error occured.")
    end
  end

  context 'parse_success_response' do
    it 'from_json' do
      string = '{ "word": "abc" }'
      expect(subject.parse_success_response(string)).to eq({"data"=>{"word"=>"abc"}})
    end

    it 'from_json with data' do
      string = '{ "data": { "word": "abc" }}'
      expect(subject.parse_success_response(string)).to eq({"data"=>{"word"=>"abc"}})
    end

    it 'from_json with data and meta' do
      string = '{ "data": { "word": "abc" }, "meta": { "total": 12 }}'
      expect(subject.parse_success_response(string)).to eq({"data"=>{"word"=>"abc"},"meta"=>{"total"=>12}})
    end

    it 'from_xml' do
      string = "<word>abc</word>"
      expect(subject.parse_success_response(string)).to eq("data"=>{"word"=>"abc"})
    end

    it 'from_string' do
      string = "abc"
      expect(subject.parse_success_response(string)).to eq("data"=>"abc")
    end

    it 'from_string with utf-8' do
      string = "fön  "
      expect(subject.parse_success_response(string)).to eq("data"=>"fön")
    end
  end

  context 'accept headers' do
    it 'default' do
      headers = subject.set_request_headers(url)
      expect(headers["Accept"]).to eq("text/html,application/json,application/xml;q=0.9, text/plain;q=0.8,image/png,*/*;q=0.5")
    end

    it 'json' do
      headers = subject.set_request_headers(url, accept: 'json')
      expect(headers["Accept"]).to eq("application/json")
    end

    it 'xml' do
      headers = subject.set_request_headers(url, accept: 'xml')
      expect(headers["Accept"]).to eq("application/xml")
    end

    it 'html' do
      headers = subject.set_request_headers(url, accept: 'html')
      expect(headers["Accept"]).to eq("text/html; charset=UTF-8")
    end

    it 'other' do
      headers = subject.set_request_headers(url, accept: 'application/x-bibtex')
      expect(headers["Accept"]).to eq("application/x-bibtex")
    end
  end

  context 'authentication' do
    it 'no auth' do
      options = {}
      expect(subject.set_request_headers(url, options)["Authorization"]).to be nil
    end

    it 'bearer' do
      options = { bearer: 'mF_9.B5f-4.1JqM' }
      expect(subject.set_request_headers(url, options)["Authorization"]).to eq("Bearer mF_9.B5f-4.1JqM")
    end

    it 'token' do
      options = { token: '12345' }
      expect(subject.set_request_headers(url, options)["Authorization"]).to eq("Token token=12345")
    end

    it 'basic' do
      options = { username: 'foo', password: '12345' }
      basic = Base64.encode64("foo:12345").rstrip
      expect(subject.set_request_headers(url, options)["Authorization"]).to eq("Basic #{basic}")
    end
  end

  context 'host' do
    it 'empty' do
      options = {}
      expect(subject.set_request_headers(url, options)["Host"]).to be nil
    end

    it 'true' do
      options = { host: true}
      expect(subject.set_request_headers(url, options)["Host"]).to eq("example.org")
    end
  end
end
