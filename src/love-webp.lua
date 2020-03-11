-- https://github.com/ImagicTheCat/love-webp
-- MIT license (see LICENSE)

--[[
MIT License

Copyright (c) 2020 Imagic

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]]

local ffi = require("ffi")
local C = ffi.load("webp")
ffi.cdef([[
int WebPGetInfo(const uint8_t* data, size_t data_size,
                            int* width, int* height);

uint8_t* WebPDecodeRGBAInto(
    const uint8_t* data, size_t data_size,
    uint8_t* output_buffer, size_t output_buffer_size, int output_stride);
]])

-- return data, size (or trigger an error)
local function normalize_data(data, size)
  if type(data) == "string" then
    return data, string.len(data)
  elseif type(data) == "userdata" and data:typeOf("Data") then
    return data:getFFIPointer(), data:getSize()
  elseif type(data) == "cdata" then
    return data, size
  else error("invalid data argument") end
end

-- data: string, Data or cdata
-- size: (optional) for cdata
-- return ImageData or nil on failure
local function loadImage(data, size)
  local data, size = normalize_data(data, size)

  -- read header
  local dims = ffi.new("int[2]")
  if C.WebPGetInfo(data, size, dims, dims+1) == 1 then
    -- allocate/decode
    local image = love.image.newImageData(dims[0], dims[1], "rgba8")
    if C.WebPDecodeRGBAInto(data, size, image:getFFIPointer(), dims[0]*dims[1]*4, dims[0]*4) ~= nil then
      return image
    end
  end
end

return {
  loadImage = loadImage
}
