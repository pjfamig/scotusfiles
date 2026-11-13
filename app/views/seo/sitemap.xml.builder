xml.instruct! :xml, version: "1.0", encoding: "UTF-8"
xml.urlset xmlns: "http://www.sitemaps.org/schemas/sitemap/0.9" do
  xml.url do
    xml.loc absolute_url(root_path)
    xml.lastmod @terms.values.first.iso8601 if @terms.any?
  end

  @terms.drop(1).each do |term, updated_at|
    xml.url do
      xml.loc absolute_url(term_path(term))
      xml.lastmod updated_at.iso8601
    end
  end

  @decisions.each do |decision|
    xml.url do
      xml.loc absolute_url(decision_path(decision))
      xml.lastmod [ decision.imported_at, decision.updated_at ].compact.max.iso8601
    end
  end
end
