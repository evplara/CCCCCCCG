
local Game = require "game"

local WINDOW_WIDTH   = 1024
local WINDOW_HEIGHT  = 768

local CARD_WIDTH     = 60
local CARD_HEIGHT    = 70

local HAND_Y         = WINDOW_HEIGHT - CARD_HEIGHT - 20
local HAND_SPACING   = 15

local ZONE_TOP_Y     = 80
local ZONE_BOTTOM_Y  = 400
local ZONE_HEIGHT    = 80
local ZONE_SPACING   = 20
local ZONE_COUNT     = 3

local FONT_SMALL = nil
local FONT_LARGE = nil

local game = nil


function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.window.setTitle("Greek Mythology CCG")

    FONT_SMALL = love.graphics.newFont(12)
    FONT_LARGE = love.graphics.newFont(24)
    love.graphics.setFont(FONT_SMALL)

    love.math.setRandomSeed(os.time())

    game = Game:new()
    game:layoutHands()
end

function love.update(dt)
    if game.draggingCard then
        local mx, my = love.mouse.getPosition()
        game.draggingCard.x = mx - game.draggingCard.offsetX
        game.draggingCard.y = my - game.draggingCard.offsetY
    end
end


function love.draw()
  
    love.graphics.clear(0.15, 0.15, 0.15)

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(FONT_LARGE)
    love.graphics.print("Turn: " .. tostring(game.turn), 20, 20)
    love.graphics.print("You: " .. tostring(game.points.player), 200, 20)
    love.graphics.print("AI:  " .. tostring(game.points.ai), 350, 20)
    love.graphics.print("Mana: " .. tostring(game.mana), 500, 20)

    for loc = 1, ZONE_COUNT do
        local yAI     = ZONE_TOP_Y + (loc - 1) * (ZONE_HEIGHT + ZONE_SPACING)
        local yPlayer = ZONE_BOTTOM_Y + (loc - 1) * (ZONE_HEIGHT + ZONE_SPACING)

        love.graphics.setColor(0.4, 0.4, 0.4)
        love.graphics.rectangle("fill", 50, yAI, WINDOW_WIDTH - 100, ZONE_HEIGHT)
        love.graphics.rectangle("fill", 50, yPlayer, WINDOW_WIDTH - 100, ZONE_HEIGHT)
        love.graphics.setColor(1, 1, 1)
        love.graphics.rectangle("line", 50, yAI, WINDOW_WIDTH - 100, ZONE_HEIGHT)
        love.graphics.rectangle("line", 50, yPlayer, WINDOW_WIDTH - 100, ZONE_HEIGHT)

        love.graphics.setFont(FONT_SMALL)
        love.graphics.print("Location " .. loc, 55, yAI + 5)
        love.graphics.print("Location " .. loc, 55, yPlayer + 5)

        for i, c in ipairs(game.zones.ai[loc]) do
            local drawX = 60 + (i - 1) * (c.width + 10)
            local drawY = yAI + (ZONE_HEIGHT - c.height) / 2
            c.x = drawX
            c.y = drawY
            c:draw()
        end


        for i, c in ipairs(game.zones.player[loc]) do
            c.x = 60 + (i - 1) * (c.width + 10)
            c.y = yPlayer + (ZONE_HEIGHT - c.height) / 2
            c:draw()
        end
    end

    for _, c in ipairs(game.hands.player) do
        c:draw()
    end

    for i, c in ipairs(game.hands.ai) do
        local x = 60 + (i - 1) * (CARD_WIDTH + 10)
        local y = HAND_Y - 120
        c.x = x; c.y = y
        c.faceDown = true
        c:draw()
        c.faceDown = false
    end

    if not game.gameOver then
        local btnW, btnH = 120, 40
        local bx = (WINDOW_WIDTH - btnW) / 2
        local by = WINDOW_HEIGHT - btnH - 80
        love.graphics.setColor(0.2, 0.6, 0.2)
        love.graphics.rectangle("fill", bx, by, btnW, btnH, 6, 6)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(FONT_SMALL)
        love.graphics.printf("Submit", bx, by + 12, btnW, "center")
    end

    if game.gameOver then
        love.graphics.setColor(0, 0, 0, 0.7)
        love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(FONT_LARGE)
        love.graphics.printf(game.winner, 0, WINDOW_HEIGHT / 2 - 50, WINDOW_WIDTH, "center")
        love.graphics.setFont(FONT_SMALL)
        love.graphics.printf("Press R to Restart", 0, WINDOW_HEIGHT / 2 + 10, WINDOW_WIDTH, "center")
    end
end


function love.mousepressed(x, y, button)
  print(string.format("MOUSEPRESSED @ (%d, %d) button=%d", x, y, button))
    if button ~= 1 then return end
    if game.gameOver then return end

    local btnW, btnH = 120, 40
    local bx = (WINDOW_WIDTH - btnW) / 2
    local by = WINDOW_HEIGHT - btnH - 80
    if x >= bx and x <= bx + btnW and y >= by and y <= by + btnH then
        if not game.submitted then
            game.submitted = true
            game:aiPlaceCards()
            game:resolveReveals()
            game:computePointsAndCleanup()
            if not game.gameOver then
               game:nextTurn()
               game:layoutHands()
            end
            return
        end
    end


    if not game.submitted then
        for _, c in ipairs(game.hands.player) do
            if c:containsPoint(x, y) then
                game.draggingCard = c
                c.isDragging = true
                c.offsetX = x - c.x
                c.offsetY = y - c.y
                break
            end
        end
    end
end


function love.mousereleased(x, y, button)
    if button ~= 1 or not game.draggingCard then return end
    local c = game.draggingCard
    c.isDragging = false

    if not game.submitted then
        local loc = game:getZoneAt(x, y, "player")
        if loc and game:placeCardInZone(c, loc) then
        else
            game:layoutHands()
        end
    end

    game.draggingCard = nil
end


function love.keypressed(key)
    if key == "r" and game.gameOver then
        game = Game:new()
        game:layoutHands()
    elseif key == "n" and not game.gameOver then
        
        if game.submitted then
            game:nextTurn()
            game:layoutHands()
        end
    end
end
