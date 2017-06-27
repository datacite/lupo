module Metadatable
  extend ActiveSupport::Concern

  included do
    def get_doi_ra(doi, options = {})
      return {} if doi.blank?

      options[:timeout] ||= 120
      doi = CGI.unescape(clean_doi(doi))
      prefix_string = Array(/^(10\.\d{4,5})\/.+/.match(doi)).last
      return {} if prefix_string.blank?

      # return registration agency cached in Redis if it exists and not test
      unless options[:test]
        ra = redis.get prefix_string
        return ra if ra.present?
      end

      url = "http://doi.crossref.org/doiRA/#{doi}"
      response = Maremma.get(url, options.merge(host: true))

      response["errors"] = [{ "status" => 400, "title" => response["data"] }] if response["data"].is_a?(String)
      return response["errors"] if response["errors"].present?

      ra = response.fetch("data", [{}]).first.fetch("RA", nil)
      if ra.present?
        ra = ra.delete(' ').downcase

        # store prefix/registration agency pair in Redis unless test
        redis.set prefix_string, ra unless options[:test]
        ra
      else
        error = response.fetch("data", [{}]).first.fetch("status", "An error occured")
        { "errors" => [{ "title" => error, "status" => 400 }] }
      end
    end

    # remove non-printing whitespace
    def clean_doi(doi)
      doi.gsub(/\u200B/, '')
    end

    def github_from_url(url)
      return {} unless /\Ahttps:\/\/github\.com\/(.+)(?:\/)?(.+)?(?:\/tree\/)?(.*)\z/.match(url)
      words = URI.parse(url).path[1..-1].split('/')

      { owner: words[0],
        repo: words[1],
        release: words[3] }.compact
    end

    def github_repo_from_url(url)
      github_from_url(url).fetch(:repo, nil)
    end

    def github_release_from_url(url)
      github_from_url(url).fetch(:release, nil)
    end

    def github_owner_from_url(url)
      github_from_url(url).fetch(:owner, nil)
    end

    def github_as_owner_url(github_hash)
      "https://github.com/#{github_hash[:owner]}" if github_hash[:owner].present?
    end

    def github_as_repo_url(github_hash)
      "https://github.com/#{github_hash[:owner]}/#{github_hash[:repo]}" if github_hash[:repo].present?
    end

    def github_as_release_url(github_hash)
      "https://github.com/#{github_hash[:owner]}/#{github_hash[:repo]}/tree/#{github_hash[:release]}" if github_hash[:release].present?
    end
  end
end
