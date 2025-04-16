# BarcodeLookup

A Lua package or EAN, UPC, GTIN and ISBN name lookup and validation

To use the EAN-Search.org API, you need an API access token from
https://www.ean-search.org/ean-database-api.html

For the example we store the API token in the environment variable EAN_SEARCH_API_TOKEN.

```lua
local barcodeLookup = BarcodeLookup:new(os.getenv("EAN_SEARCH_API_TOKEN"))

local product = barcodeLookup:barcodeLookup("5099750442227")
if (product.error) then
    print(product.error)
else
    print(product.name, product.categoryName)
end
local product = barcodeLookup:barcodeLookup("5099750442228")
if (product.error) then
    print(product.error)
else
    print(product.name, product.categoryName)
end

local productList = barcodeLookup:productSearch("iphone 16")
local i = 1
while productList[i] ~= nil do
    print(productList[i].ean, productList[i].name, productList[i].categoryName)
    i = i + 1
end

print (barcodeLookup:verifyChecksum("5099750442227"))
print (barcodeLookup:verifyChecksum("5099750442228"))

print (barcodeLookup:issuingCountryLookup("5099750442227"))

