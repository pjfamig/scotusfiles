require "test_helper"

class SeoTest < ActionDispatch::IntegrationTest
  test "decision pages describe the case for search engines and social previews" do
    get decision_path(decisions(:paxton), s: "1-1")

    assert_response :success
    assert_select "title", "Free Speech Coalition, Inc. v. Paxton, 606 U.S. 461 (2025) · SCOTUSfiles"
    assert_select "meta[name=description][content^=?]", "Free Speech Coalition, Inc. v. Paxton (No. 23-1122, decided June 27, 2025). H. B. 1181 survives intermediate scrutiny. Opinion by Justice Thomas."
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/decisions/free-speech-coalition-inc-v-paxton-23-1122"
    assert_select "meta[property='og:type'][content=article]"
    assert_select "meta[property='article:published_time'][content=?]", "2025-06-27"
    assert_select "meta[name=robots][content^=index]"

    article, breadcrumbs = json_ld_documents
    assert_equal "Article", article["@type"]
    assert_equal "2025-06-27", article["datePublished"]
    assert_equal "Justice Thomas", article.dig("creator", "name")
    assert_equal [ "Decisions", "October Term 2024", "Free Speech Coalition, Inc. v. Paxton" ], breadcrumbs["itemListElement"].pluck("name")
  end

  test "the home page lists the newest term and describes the site" do
    get root_path

    assert_response :success
    assert_select "title", SeoHelper::DEFAULT_TITLE
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/"
    assert_equal "WebSite", json_ld_documents.first["@type"]
  end

  test "older terms have their own indexable pages" do
    get term_path(2024)

    assert_response :success
    assert_select "title", "October Term 2024 Supreme Court Opinions · SCOTUSfiles"
    assert_select "h1", /October Term 2024/
    assert_select "link[rel=canonical][href=?]", "http://www.example.com/terms/2024"
    assert_select "a[href=?]", "/terms/2024", text: "OT 2024"
    assert_select "a[href=?]", "/", text: "OT 2025"
  end

  test "duplicate listing URLs redirect permanently to their canonical pages" do
    get decisions_path(term: 2024)
    assert_redirected_to term_path(2024)
    assert_response :moved_permanently

    get decisions_path(term: 2025)
    assert_redirected_to root_path

    get decisions_path
    assert_redirected_to root_path

    get term_path(2025)
    assert_redirected_to root_path
    assert_response :moved_permanently
  end

  test "unknown terms are not found" do
    get term_path(1999)

    assert_response :not_found
  end

  test "search results and account pages stay out of the index" do
    get decisions_path(q: "Paxton")
    assert_select "meta[name=robots][content=?]", "noindex, follow"

    get new_session_path
    assert_select "meta[name=robots][content=?]", "noindex, follow"
  end

  test "the sitemap lists listing pages and decisions" do
    get sitemap_path

    assert_response :success
    assert_equal "application/xml", response.media_type
    locations = Nokogiri::XML(response.body).remove_namespaces!.xpath("//url/loc").map(&:text)
    assert_includes locations, "http://www.example.com/"
    assert_includes locations, "http://www.example.com/terms/2024"
    assert_includes locations, "http://www.example.com/decisions/free-speech-coalition-inc-v-paxton-23-1122"
    assert_not_includes locations, "http://www.example.com/terms/2025"
  end

  test "robots.txt points crawlers at the sitemap" do
    get robots_path

    assert_response :success
    assert_equal "text/plain", response.media_type
    assert_includes response.body, "Sitemap: http://www.example.com/sitemap.xml"
  end

  test "the feed lists imported decisions" do
    get feed_path

    assert_response :success
    assert_equal "application/atom+xml", response.media_type
    assert_includes response.body, "Free Speech Coalition, Inc. v. Paxton, 606 U.S. 461 (2025)"
    assert_not_includes response.body, "Example v. Pending"
  end

  test "crawlers reporting old browser versions still get the page" do
    old_chrome = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/100.0.0.0 Safari/537.36"

    get root_path, headers: { "User-Agent" => old_chrome }
    assert_response :not_acceptable

    get root_path, headers: { "User-Agent" => "Mozilla/5.0 AppleWebKit/537.36 (KHTML, like Gecko; compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm) Chrome/100.0.0.0 Safari/537.36" }
    assert_response :success
  end

  test "non-canonical hosts redirect to the canonical host" do
    with_canonical_host("www.example.com") do
      get "http://example.com/terms/2024?ref=x"
      assert_redirected_to "https://www.example.com/terms/2024?ref=x"
      assert_response :moved_permanently

      get "http://scotusfiles-123.herokuapp.com/"
      assert_redirected_to "https://www.example.com/"

      get "http://www.example.com/terms/2024"
      assert_response :success
      assert_select "link[rel=canonical][href=?]", "https://www.example.com/terms/2024"
    end
  end

  private
    def json_ld_documents
      css_select("script[type='application/ld+json']").map { |script| JSON.parse(script.text) }
    end

    def with_canonical_host(host)
      previous, Rails.configuration.x.canonical_host = Rails.configuration.x.canonical_host, host
      yield
    ensure
      Rails.configuration.x.canonical_host = previous
    end
end
