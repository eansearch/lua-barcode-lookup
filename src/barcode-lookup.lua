--- BarcodeLookup module for EAN, UPC, and ISBN lookup and validation
--- Copyright Relaxed Communications GmbH, 2025
---           info@relaxedcommunications.com
---           https://www.ean-search.org
-- Provides functionality for accessing the EAN-Search.org API to perform various barcode-related operations.

local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("cjson")

local BarcodeLookup = {}
BarcodeLookup.__index = BarcodeLookup

--- Base URL for the EAN-Search.org API
BarcodeLookup.BASE_URL = "https://api.ean-search.org/api?format=json"

--- Maximum number of retries for API calls
BarcodeLookup.MAX_API_TRIES = 3

--- Creates a new BarcodeLookup instance
-- @param accessToken API access token
-- @return A new BarcodeLookup instance
function BarcodeLookup:new(accessToken)
    local self = setmetatable({}, BarcodeLookup)
    self.accessToken = accessToken
    self.remaining = -1
    self.timeout = 180
    return self
end

--- Sets the timeout for API requests
-- @param sec timeout in seconds
function BarcodeLookup:setTimeout(sec)
    self.timeout = sec
end

--- Look up a 13-digit barcode (EAN/GTIN) and retrieve product information
-- @param ean The EAN/GTIN to look up.
-- @param lang preferred language code (default is 1 = English)
-- @return product information or nil if not found
function BarcodeLookup:gtinLookup(ean, lang)
    lang = lang or 1
    local response = self:apiCall("op=barcode-lookup&ean=" .. ean .. "&language=" .. lang)
    return response[1] or nil
end

--- Look up a 12-digit UPC and retrieve product name
-- @param upc UPC to look up
-- @param lang preferred language code (default is 1 = English)
-- @return product information or nil if not found
function BarcodeLookup:upcLookup(upc, lang)
    local response = self:apiCall("op=barcode-lookup&upc=" .. upc .. "&language=" .. lang)
    return response[1] or nil
end

--- Look up an 10-digit ISBN and retrieve book title
-- @param isbn ISBN to look up
-- @return book title or nil if not found
function BarcodeLookup:isbnLookup(isbn)
    local response = self:apiCall("op=barcode-lookup&isbn=" .. isbn)
    if response[1] then
        return response[1].name
    else
        return nil
    end
end

--- Searches for products by barcode prefix
-- @param prefix barcode prefix to search
-- @param page page number of results (default is 0)
-- @return list of products matching the prefix
function BarcodeLookup:barcodePrefixSearch(prefix, page)
    page = page or 0
    local response = self:apiCall("op=barcode-prefix-search&prefix=" .. prefix .. "&page=" .. page)
    if not response then return {} end
    return response
end

--- Search for products by name
-- @param name product name to search
-- @param page page number of results (default is 0)
-- @return list of products matching the name
function BarcodeLookup:productSearch(name, page)
    page = page or 0
    name = urlencode(name)
    local response = self:apiCall("op=product-search&name=" .. name .. "&page=" .. page)
    if not response then return {} end
    return response.productlist or {}
end

--- Search for similar products by name
-- @param name product name to search
-- @param page page number of results (default is 0)
-- @return list of similar products partially matching the name
function BarcodeLookup:similarProductSearch(name, page)
    page = page or 0
    name = urlencode(name)
    local response = self:apiCall("op=similar-product-search&name=" .. name .. "&page=" .. page)
    if not response then return {} end
    return response.productlist or {}
end

--- Search for products by category and name
-- @param category category code to search
-- @param name product name to search (optional)
-- @param page page number of results (default is 0)
-- @return A list of products matching the category and name.
function BarcodeLookup:categorySearch(category, name, page)
    page = page or 0
    name = urlencode(name or "")
    local response = self:apiCall("op=category-search&category=" .. category .. "&name=" .. name .. "&page=" .. page)
    if not response then return {} end
    return response.productlist or {}
end

--- Retrieves a base64-encoded PNG image of the barcode
-- @param ean EAN/GTIN to generate the barcode for
-- @param width width of the barcode image (default is 102)
-- @param height height of the barcode image (default is 50)
-- @return base64-encoded barcode image
function BarcodeLookup:barcodeImage(ean, width, height)
    width = width or 102
    height = height or 50
    local response = self:apiCall("op=barcode-image&ean=" .. ean .. "&width=" .. width .. "&height=" .. height)
    local response = xml.load(response)
    return response:find("product/barcode"):getText()
end

--- Verify the checksum of a barcode
-- @param ean EAN/GTIN to verify
-- @return True if the checksum is valid, false otherwise
function BarcodeLookup:verifyChecksum(ean)
    local response = self:apiCall("op=verify-checksum&ean=" .. ean)
    return response[1].valid == "1"
end

--- Retrieve the issuing country of any barcode
-- @param ean EAN/GTIN to look up
-- @return issuing country of the barcode
function BarcodeLookup:issuingCountryLookup(ean)
    local response = self:apiCall("op=issuing-country&ean=" .. ean)
    return response[1].issuingCountry
end

--- Retrieve the remaining API credits
-- @return number of remaining API credits
function BarcodeLookup:creditsRemaining()
    return self.remaining
end

--- internal function to make API calls to EAN-Search.org
-- @param params The query parameters for the API call
-- @param tries current retry attempt (default is 1)
-- @return decoded JSON response from the API
function BarcodeLookup:apiCall(params, tries)
    tries = tries or 1
    local url = BarcodeLookup.BASE_URL .. "&token=" .. self.accessToken .. "&" .. params
    local response_body = {}
    local res, code, headers = http.request{
        url = url,
        method = "GET",
        sink = ltn12.sink.table(response_body),
        timeout = self.timeout
    }

    if code == 429 and tries < BarcodeLookup.MAX_API_TRIES then
        os.execute("sleep 1")
        return self:apiCall(params, tries + 1)
    end
    if code == 400 then
        return {}
    end

    if headers and headers["X-Credits-Remaining"] then
        self.remaining = tonumber(headers["X-Credits-Remaining"])
    end

    local json = table.concat(response_body)
    return cjson.decode(json)
end

--- helper function to encode a string for use in a URL
-- @param str string to encode
-- @return URL-encoded string
function urlencode(str)
    local hex = string.gsub(str, 
        "([^%w%s])", 
        function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    return string.gsub(hex, " ", "+")
end

return BarcodeLookup

