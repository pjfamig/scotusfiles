module SeoHelper
  SITE_NAME = "SCOTUSfiles".freeze
  DEFAULT_TITLE = "SCOTUSfiles — Read and discuss Supreme Court opinions".freeze
  DEFAULT_DESCRIPTION = "Every U.S. Supreme Court opinion, converted from the official PDF into clean, searchable text " \
    "you can read and discuss sentence by sentence. Holdings, dissents, and concurrences for every term.".freeze
  DEFAULT_ROBOTS = "index, follow, max-image-preview:large, max-snippet:-1, max-video-preview:-1".freeze
  SUPREME_COURT = { "@type": "GovernmentOrganization", name: "Supreme Court of the United States", url: "https://www.supremecourt.gov" }.freeze

  # Absolute URLs always point at the canonical host in production, whatever host the request came in on.
  def site_url
    host = Rails.configuration.x.canonical_host
    host.present? ? "https://#{host}" : request.base_url
  end

  def absolute_url(path) = "#{site_url}#{path}"

  def page_title
    content_for?(:title) ? "#{content_for(:title)} · #{SITE_NAME}" : DEFAULT_TITLE
  end

  def social_title
    content_for?(:title) ? content_for(:title) : DEFAULT_TITLE
  end

  def meta_description
    content_for?(:description) ? content_for(:description) : DEFAULT_DESCRIPTION
  end

  def canonical_url
    content_for?(:canonical) ? content_for(:canonical) : absolute_url(request.path)
  end

  def robots_directive
    content_for?(:robots) ? content_for(:robots) : DEFAULT_ROBOTS
  end

  def noindex!
    content_for :robots, "noindex, follow"
  end

  def og_image_url = absolute_url("/icon.png")

  def json_ld(data)
    tag.script(ERB::Util.json_escape(data.to_json).html_safe, type: "application/ld+json")
  end

  def publisher_schema
    { "@type": "Organization", name: SITE_NAME, url: absolute_url("/"),
      logo: { "@type": "ImageObject", url: og_image_url, width: 512, height: 512 } }
  end

  def website_schema
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: SITE_NAME,
      alternateName: "SCOTUS files",
      url: absolute_url("/"),
      description: DEFAULT_DESCRIPTION,
      inLanguage: "en-US",
      publisher: publisher_schema,
      potentialAction: {
        "@type": "SearchAction",
        target: { "@type": "EntryPoint", urlTemplate: "#{absolute_url(decisions_path)}?q={search_term_string}" },
        "query-input": "required name=search_term_string"
      }
    }
  end

  def breadcrumb_schema(crumbs)
    {
      "@context": "https://schema.org",
      "@type": "BreadcrumbList",
      itemListElement: crumbs.each_with_index.map do |(name, path), index|
        { "@type": "ListItem", position: index + 1, name: name, item: absolute_url(path) }
      end
    }
  end
end
