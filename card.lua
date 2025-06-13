

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
        description = def.description,

        owner = owner,  
        opponent = (owner == "player") and "ai" or "player",

        location = nil,
        inZone = false,
        faceDown = false,
        revealed = false,

        x = 0,
        y = 0,
        width = 60,
        height = 70,
        isDragging = false,
        offsetX = 0,
        offsetY = 0,

        onReveal = def.onReveal
    }, Card)

    return obj
end

function Card:clone()
    local copy = Card:new(self.name, self.owner)
    copy.currentPower = self.currentPower
    copy.basePower    = self.basePower
    copy.description  = self.description

    copy.opponent = self.opponent
    copy.location = self.location
    copy.inZone   = self.inZone
    copy.faceDown = self.faceDown
    copy.revealed = self.revealed

    copy.x = self.x
    copy.y = self.y
    copy.isDragging = false
    copy.offsetX    = 0
    copy.offsetY    = 0
    return copy
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
    
    local font = love.graphics.getFont()
    local textHeight = font:getHeight()
    local nameY = self.y + (self.height - textHeight) / 2

    love.graphics.setColor(0, 0, 0)
    love.graphics.printf(self.name,
                         self.x,
                         nameY,
                         self.width,
                         "center")
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
