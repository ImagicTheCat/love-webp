local WebP = require("love-webp")

local overlay, short_anim, long_anim
function love.load()
  short_anim = love.graphics.newArrayImage((WebP.loadImages(love.filesystem.newFileData("short-anim.webp"))))

  long_anim = WebP.loadAnimation(love.filesystem.newFileData("long-anim.webp"))
  long_anim:play()

  overlay = love.graphics.newImage(WebP.loadImage(love.filesystem.newFileData("still.webp")))
end

function love.update(dt)
  long_anim:tick(dt)
end

function love.draw()
  -- display short anim centered
  love.graphics.drawLayer(short_anim, (love.timer.getTime()*15)%short_anim:getLayerCount()+1, love.graphics.getWidth()/2-short_anim:getWidth()/2, love.graphics.getHeight()/2-short_anim:getHeight()/2)

  -- display long anim centered
  love.graphics.draw(long_anim.texture, love.graphics.getWidth()/2-long_anim.texture:getWidth()/2, love.graphics.getHeight()/2-long_anim.texture:getHeight()/2)

  -- display overlay
  love.graphics.draw(overlay)
end
