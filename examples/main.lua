local WebP = require("love-webp")

local tex
function love.load()
  local image = WebP.loadImage(love.filesystem.newFileData("still.webp"))
  tex = love.graphics.newImage(image)
end

function love.draw()
  local x,y = love.mouse.getPosition()
  love.graphics.draw(tex, -x,-y)
end
