local WebP = require("love-webp")

local bg
local short_anim
function love.load()
  local image = WebP.loadImage(love.filesystem.newFileData("still.webp"))

  short_anim = love.graphics.newArrayImage((WebP.loadImages(love.filesystem.newFileData("short-anim.webp"))))
  bg = love.graphics.newImage(image)
end

function love.draw()
  love.graphics.draw(bg)
  love.graphics.drawLayer(short_anim, (love.timer.getTime()*15)%short_anim:getLayerCount()+1, love.graphics.getWidth()/2-short_anim:getWidth()/2, love.graphics.getHeight()-short_anim:getHeight()/2)
end
