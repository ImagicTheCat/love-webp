local WebP = require("love-webp")

local overlay, short_anim, long_anim
local t_overlay, t_short, t_long = true, true, true
function love.load()
  short_anim = love.graphics.newArrayImage((WebP.loadImages(love.filesystem.newFileData("short-anim.webp"))))

  long_anim = WebP.loadAnimation(love.filesystem.newFileData("long-anim.webp"))
  long_anim:play()

  overlay = love.graphics.newImage(WebP.loadImage(love.filesystem.newFileData("still.webp")))
end

function love.update(dt)
  if t_long then
    long_anim:tick(dt)
  end
end

function love.draw()
  if t_short then
    -- display short anim
    local layer = math.floor(love.timer.getTime()*15)%short_anim:getLayerCount()+1
    for i=0,15 do
      for j=0,8 do
        love.graphics.drawLayer(short_anim, layer, i*80, j*80)
      end
    end
  end

  if t_long then
    -- display long anim centered
    love.graphics.draw(long_anim.texture, love.graphics.getWidth()/2-long_anim.texture:getWidth()/2, love.graphics.getHeight()/2-long_anim.texture:getHeight()/2)
  end

  if t_overlay then
    -- display overlay
    love.graphics.draw(overlay)
  end

  love.graphics.print("toggles (scancode):\n[Q] short anim\n[W] long anim\n[E] overlay", 0,0)
end

function love.keypressed(key, scancode, isrepeat)
  if scancode == "q" then t_short = not t_short
  elseif scancode == "w" then t_long = not t_long
  elseif scancode == "e" then t_overlay = not t_overlay end
end
