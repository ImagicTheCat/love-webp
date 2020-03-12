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
local webp = ffi.load("webp")
local webpdemux = ffi.load("webpdemux")
ffi.cdef([[
int WebPGetInfo(const uint8_t* data, size_t data_size,
                            int* width, int* height);

uint8_t* WebPDecodeRGBAInto(
    const uint8_t* data, size_t data_size,
    uint8_t* output_buffer, size_t output_buffer_size, int output_stride);

typedef enum WEBP_CSP_MODE {
  MODE_RGB = 0, MODE_RGBA = 1,
  MODE_BGR = 2, MODE_BGRA = 3,
  MODE_ARGB = 4, MODE_RGBA_4444 = 5,
  MODE_RGB_565 = 6,
  // RGB-premultiplied transparent modes (alpha value is preserved)
  MODE_rgbA = 7,
  MODE_bgrA = 8,
  MODE_Argb = 9,
  MODE_rgbA_4444 = 10,
  // YUV modes must come after RGB ones.
  MODE_YUV = 11, MODE_YUVA = 12,  // yuv 4:2:0
  MODE_LAST = 13
} WEBP_CSP_MODE;

typedef struct {
  // Output colorspace. Only the following modes are supported:
  // MODE_RGBA, MODE_BGRA, MODE_rgbA and MODE_bgrA.
  WEBP_CSP_MODE color_mode;
  int use_threads;           // If true, use multi-threaded decoding.
  uint32_t padding[7];       // Padding for later use.
} WebPAnimDecoderOptions;

typedef struct {
  uint32_t canvas_width;
  uint32_t canvas_height;
  uint32_t loop_count;
  uint32_t bgcolor;
  uint32_t frame_count;
  uint32_t pad[4];   // padding for later use
} WebPAnimInfo;

typedef struct {
  const uint8_t* bytes;
  size_t size;
} WebPData;

typedef struct {
} WebPAnimDecoder;

enum{
  WEBP_DEMUX_ABI_VERSION = 0x0107    // MAJOR(8b) + MINOR(8b)
};

int WebPAnimDecoderOptionsInitInternal(
    WebPAnimDecoderOptions*, int);

WebPAnimDecoder* WebPAnimDecoderNewInternal(
    const WebPData*, const WebPAnimDecoderOptions*, int);

int WebPAnimDecoderGetInfo(const WebPAnimDecoder* dec,
                                       WebPAnimInfo* info);

int WebPAnimDecoderHasMoreFrames(const WebPAnimDecoder* dec);

int WebPAnimDecoderGetNext(WebPAnimDecoder* dec,
                                       uint8_t** buf, int* timestamp);

void WebPAnimDecoderReset(WebPAnimDecoder* dec);

void WebPAnimDecoderDelete(WebPAnimDecoder* dec);
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

-- load WebP image
-- data: string, Data or cdata
-- size: (optional) for cdata
-- return ImageData or nil on failure
local function loadImage(data, size)
  local data, size = normalize_data(data, size)

  -- read header
  local dims = ffi.new("int[2]")
  if webp.WebPGetInfo(data, size, dims, dims+1) == 1 then
    -- allocate/decode
    local image = love.image.newImageData(dims[0], dims[1], "rgba8")
    if webp.WebPDecodeRGBAInto(data, size, image:getFFIPointer(), dims[0]*dims[1]*4, dims[0]*4) ~= nil then
      return image
    end
  end
end

-- load WebP frames
-- data: string, Data or cdata
-- size: (optional) for cdata
-- return (ImageData list, frame durations list, loop_count) or nil
local function loadImages(data, size)
  local data, size = normalize_data(data, size)

  -- decoding
  local options = ffi.new("WebPAnimDecoderOptions")
  local webp_data = ffi.new("WebPData", data, size)

  if webpdemux.WebPAnimDecoderOptionsInitInternal(options, webpdemux.WEBP_DEMUX_ABI_VERSION) ~= 0 then
    local decoder = webpdemux.WebPAnimDecoderNewInternal(webp_data, options, webpdemux.WEBP_DEMUX_ABI_VERSION)
    if decoder ~= nil then
      local anim_info = ffi.new("WebPAnimInfo")
      local buffer = ffi.new("uint8_t*[1]")
      local timestamp = ffi.new("int[1]")

      local images, timestamps = {}, {}

      if webpdemux.WebPAnimDecoderGetInfo(decoder, anim_info) ~= 0 then
        -- decode each frame
        while webpdemux.WebPAnimDecoderHasMoreFrames(decoder) ~= 0 do
          if webpdemux.WebPAnimDecoderGetNext(decoder, buffer, timestamp) ~= 0 then
            local image = love.image.newImageData(anim_info.canvas_width, anim_info.canvas_height, "rgba8")
            -- copy from WebPDecoder buffer to ImageData
            ffi.copy(image:getFFIPointer(), buffer[0], anim_info.canvas_width*anim_info.canvas_height*4)
            table.insert(images, image)
            table.insert(timestamps, timestamp[0])
          end
        end
      end

      webpdemux.WebPAnimDecoderDelete(decoder)

      return images, timestamps, anim_info.loop_count
    end
  end
end

return {
  loadImage = loadImage,
  loadImages = loadImages
}
