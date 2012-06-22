# A sample Guardfile
# More info at https://github.com/guard/guard#readme

guard 'sprockets', :destination => "build", :asset_paths => ['app', '.'], :minify => false do
  watch (%r{^app/js/.*}){ |m| "app/js/index.js" }
  watch (%r{^app/css/.*}){ |m| "app/css/index.css" }
end
