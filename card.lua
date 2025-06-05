

local CardDefs = require "carddefs"

local Card = {}
Card.__index = Card

function Card:new(name, owner)
    assert(CardDefs[name], "Unknown card name: " .. tostring(name))
    local def = CardDefs[name]

    local obj = setmetatable({
        name = name,
        cost = def.cost,
        basePower = def.basePower,
        currentPower = def.basePower,

        owner = owner,  
        opponent = (owner == "player") and "ai" or "player",

        location = nil,
        inZone = false,
        faceDown = false,
        revealed = false,

        x = 0,
        y = 0,
        width = 40,
        height = 60,
        isDragging = false,
        offsetX = 0,
        offsetY = 0,

        onReveal = def.onReveal
    }, Card)

    return obj
end

function Card:draw()
    if self.faceDown then
        love.graphics.setColor(0.2, 0.2, 0.2)
        love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)
        return
    end

    if self.owner == "player" then
        love.graphics.setColor(0.8, 0.9, 1)
    else
        love.graphics.setColor(1, 0.9, 0.8)
    end
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)

    love.graphics.setFont(love.graphics.getFont())
    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(self.name, self.x + 2, self.y + 2, self.width - 4, "center")

    love.graphics.setColor(0.1, 0.1, 0.1)
    love.graphics.circle("fill", self.x + 12, self.y + 12, 12)
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(tostring(self.cost), self.x + 7, self.y + 4, 10, "center")

    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(
        "P:" .. tostring(self.currentPower),
        self.x,
        self.y + self.height - 18,
        self.width,
        "center"
    )
end

function Card:containsPoint(px, py)
    return px >= self.x
       and px <= self.x + self.width
       and py >= self.y
       and py <= self.y + self.height
end

return Card
