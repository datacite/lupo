# unregister all Mime types, keep only :text
Mime::EXTENSION_LOOKUP.map { |i| i.first.to_sym }.each do |f|
  Mime::Type.unregister(f)
end

# re-register some default Mime types
Mime::Type.register "text/html", :html, %w( application/xhtml+xml ), %w( xhtml )
Mime::Type.register "text/plain", :text, [], %w(txt)
Mime::Type.register "application/json", :json, %w( text/x-json application/vnd.api+json application/jsonrequest )

# Mime types supported by bolognese gem https://github.com/datacite/bolognese
Mime::Type.register "application/vnd.crossref.unixref+xml", :crossref
Mime::Type.register "application/vnd.crosscite.crosscite+json", :crosscite
Mime::Type.register "application/vnd.datacite.datacite+xml", :datacite, %w( application/x-datacite+xml )
Mime::Type.register "application/vnd.datacite.datacite+json", :datacite_json
Mime::Type.register "application/vnd.schemaorg.ld+json", :schema_org
Mime::Type.register "application/rdf+xml", :rdf_xml
Mime::Type.register "text/turtle", :turtle
Mime::Type.register "application/vnd.jats+xml", :jats
Mime::Type.register "application/vnd.citationstyles.csl+json", :citeproc, %w( application/citeproc+json )
Mime::Type.register "application/vnd.codemeta.ld+json", :codemeta
Mime::Type.register "application/x-bibtex", :bibtex
Mime::Type.register "application/x-research-info-systems", :ris
Mime::Type.register "text/x-bibliography", :citation

AVAILABLE_CONTENT_TYPES = Mime::LOOKUP.map { |k, v| [k, v.to_sym] }.to_h.except %w(text/html application/xhtml+xml text/plain)

# register renderers for these Mime types
# :citation is handled differently
%w(crosscite datacite_json schema_org turtle citeproc codemeta).each do |f|
  ActionController::Renderers.add f.to_sym do |obj, options|
    data = obj.send(f)
    fail AbstractController::ActionNotFound unless data.present?

    self.content_type ||= Mime[f.to_sym]
    self.response_body = data
  end
end

# these Mime types send a file for download. We give proper filename and extension
%w(crossref datacite rdf_xml jats).each do |f|
  ActionController::Renderers.add f.to_sym do |obj, options|
    uri = Addressable::URI.parse(obj.identifier)
    data = obj.send(f)
    fail AbstractController::ActionNotFound unless data.present?

    filename = uri.path.gsub(/[^0-9A-Za-z.\-]/, '_')
    send_data data, type: Mime[f.to_sym],
      disposition: "attachment; filename=#{filename}.xml"
  end
end

ActionController::Renderers.add :bibtex do |obj, options|
  uri = Addressable::URI.parse(obj.identifier)
  data = obj.send("bibtex")
  fail AbstractController::ActionNotFound unless data.present?

  filename = uri.path.gsub(/[^0-9A-Za-z.\-]/, '_')
  send_data data, type: Mime[:bibtex],
    disposition: "attachment; filename=#{filename}.bib"
end

ActionController::Renderers.add :ris do |obj, options|
  uri = Addressable::URI.parse(obj.identifier)
  data = obj.send("ris")
  fail AbstractController::ActionNotFound unless data.present?

  filename = uri.path.gsub(/[^0-9A-Za-z.\-]/, '_')
  send_data data, type: Mime[:ris],
    disposition: "attachment; filename=#{filename}.ris"
end

ActionController::Renderers.add :citation do |obj, options|
  data = obj.send("citation")
  fail AbstractController::ActionNotFound unless data.present?

  self.content_type ||= "text/plain"
  self.response_body = data
end
