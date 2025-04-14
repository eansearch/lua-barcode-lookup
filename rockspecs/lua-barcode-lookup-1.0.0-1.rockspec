-- lua-barcode-lookup-1.0.0-1.rockspec
rockspec_format = "3.0"
package = "lua-barcode-lookup"
version = "1.0.0-1"
source = {
  url = "git+https://github.com/eansearch/lua-barcode-lookup",
  tag = "v1.0.0"
}
description = {
  summary = "Barcode lookup by EAN, UPC, ISBN or product name",
  detailed = [[
    A Lua package that implements barcode looup by EAN, UPC or ISBN as well as searching for products and their barcode by product name.
  ]],
  homepage = "https://github.com/eansearch/lua-barcode-lookup",
  license = "MIT",
  issues_url = "https://github.com/eansearch/lua-barcode-lookup/issues",
  labels = {
    "barcode lookup",
    "EAN",
    "UPC",
    "ISBN",
    "GTIN",
    "barcodes"
  },
  maintainer = "Jan Willamowius <info@relaxedcommunications.com>"
}
dependencies = {
  "lua >= 5.1",
  "socket.http >= 1",
  "ltn12 >= 1",
  "cjson >= 1"
}
build = {
  type = "builtin",
  modules = {
    main = "src/BarcodeLookup.lua"
  },
  copy_directories = { "doc" }
}
test_dependencies = { "luaunit >= 3.4" }
