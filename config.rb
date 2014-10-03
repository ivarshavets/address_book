# encoding: utf-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

Time.zone = "Kyiv"

set :css_dir, 'stylesheets'
set :js_dir, 'javascripts'
set :images_dir, 'images'
set :markdown_engine, :redcarpet
set :markdown, filter_html: false, fenced_code_blocks: true, smartypants: true
set :encoding, 'utf-8'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

  # Minify Javascript on build
  activate :minify_javascript

  activate :asset_hash
  # min html
  activate :minify_html
end

# deploy
activate :deploy do |deploy|
  deploy.method = :git
  deploy.branch = "gh-pages"
  deploy.clean = true
end