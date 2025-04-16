local http = require("socket.http")
local ltn12 = require("ltn12")
local cjson = require("cjson")

local BarcodeLookup = {}
BarcodeLookup.__index = BarcodeLookup

BarcodeLookup.BASE_URL = "https://api.ean-search.org/api?format=json"
BarcodeLookup.MAX_API_TRIES = 3

function BarcodeLookup:new(accessToken)
    local self = setmetatable({}, BarcodeLookup)
    self.accessToken = accessToken
    self.remaining = -1
    self.timeout = 180
    return self
end

function BarcodeLookup:setTimeout(sec)
    self.timeout = sec
end

-- get access token from https://www.ean-search.org/ean-database-api.html
function BarcodeLookup:gtinLookup(ean, lang)
    lang = lang or 1
    local response = self:apiCall("op=barcode-lookup&ean=" .. ean .. "&language=" .. lang)
    return response[1] or nil
end

function BarcodeLookup:upcLookup(upc, lang)
    local response = self:apiCall("op=barcode-lookup&upc=" .. upc .. "&language=" .. lang)
    if response[1] then
        return respone[1].name
	else
        return nil
    end
end

function BarcodeLookup:isbnLookup(isbn)
    local response = self:apiCall("op=barcode-lookup&isbn=" .. isbn)
    if response[1] then
        return respone[1].name
	else
        return nil
    end
end

function BarcodeLookup:barcodePrefixSearch(prefix, page)
    page = page or 0
    local response = self:apiCall("op=barcode-prefix-search&prefix=" .. prefix .. "&page=" .. page)
    if not response then return {} end
    return response
end

function BarcodeLookup:productSearch(name, page)
    page = page or 0
	name = urlencode(name)
    local response = self:apiCall("op=product-search&name=" .. name .. "&page=" .. page)
    if not response then return {} end
    return response.productlist or {}
end

function BarcodeLookup:similarProductSearch(name, page)
    page = page or 0
    name = urlencode(name)
    local response = self:apiCall("op=similar-product-search&name=" .. name .. "&page=" .. page)
    if not response then return {} end
    return response.productlist or {}
end

function BarcodeLookup:categorySearch(category, name, page)
    page = page or 0
    name = urlencode(name or "")
    local response = self:apiCall("op=category-search&category=" .. category .. "&name=" .. name .. "&page=" .. page)
    if not response then return {} end
    return response.productlist or {}
end

-- returns PNG barcode image base64 encoded
function BarcodeLookup:barcodeImage(ean, width, height)
    width = width or 102
    height = height or 50
    local response = self:apiCall("op=barcode-image&ean=" .. ean .. "&width=" .. width .. "&height=" .. height)
    local response = xml.load(response)
    return response:find("product/barcode"):getText()
end

function BarcodeLookup:verifyChecksum(ean)
    local response = self:apiCall("op=verify-checksum&ean=" .. ean)
    return response[1].valid == "1"
end

function BarcodeLookup:issuingCountryLookup(ean)
    local response = self:apiCall("op=issuing-country&ean=" .. ean)
    return response[1].issuingCountry
end

function BarcodeLookup:creditsRemaining()
    return self.remaining
end

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

print(table.concat(response_body))
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

function urlencode(str)
    local hex = string.gsub(str, 
        "([^%w%s])", 
        function(c)
            return string.format("%%%02X", string.byte(c))
        end)
    return string.gsub(hex, " ", "+")
end

