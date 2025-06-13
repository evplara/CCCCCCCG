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

local COLOR_BG       = {133/255, 23/255, 23/255}
local COLOR_ZONE     = {199/255, 38/255, 38/255}

local FONT_SMALL = nil
local FONT_LARGE = nil

local game = nil
local screen = "title"
local inspectedCard = nil

local function startGame()
    game = Game:new()
    game:layoutHands()
    game:recordHistory()
end

local function findCardAt(x, y)
    if not game then return nil end
    local candidates = {}
    for _, c in ipairs(game.hands.player) do table.insert(candidates, c) end
    for _, c in ipairs(game.hands.ai) do table.insert(candidates, c) end
    for _, owner in ipairs({"player", "ai"}) do
        for loc = 1, ZONE_COUNT do
            for _, c in ipairs(game.zones[owner][loc]) do
                table.insert(candidates, c)
            end
        end
    end
    for _, c in ipairs(candidates) do
        if not c.faceDown and c:containsPoint(x, y) then
            return c
        end
    end
    return nil
end


function love.load()
    love.window.setMode(WINDOW_WIDTH, WINDOW_HEIGHT)
    love.window.setTitle("Greek Mythology CCG")

    FONT_SMALL = love.graphics.newFont(12)
    FONT_LARGE = love.graphics.newFont(24)
    love.graphics.setFont(FONT_SMALL)

    love.math.setRandomSeed(os.time())
end

function love.update(dt)
    if screen == "game" and game and game.draggingCard then
        local mx, my = love.mouse.getPosition()
        game.draggingCard.x = mx - game.draggingCard.offsetX
        game.draggingCard.y = my - game.draggingCard.offsetY
    end
end


function love.draw()

    love.graphics.clear(COLOR_BG[1], COLOR_BG[2], COLOR_BG[3])

    if screen == "title" then
        love.graphics.setColor(1, 1, 1)
        love.graphics.setFont(FONT_LARGE)
        love.graphics.printf("Greek Mythology CCG", 0, WINDOW_HEIGHT / 2 - 50, WINDOW_WIDTH, "center")
        love.graphics.setFont(FONT_SMALL)
        love.graphics.printf("Press Enter to Start, Right Click To Inspect", 0, WINDOW_HEIGHT / 2 + 10, WINDOW_WIDTH, "center")
        return
    end

    love.graphics.setColor(1, 1, 1)
    love.graphics.setFont(FONT_LARGE)
    love.graphics.print("Turn: " .. tostring(game.turn), 20, 20)
    love.graphics.print("You: " .. tostring(game.points.player), 200, 20)
    love.graphics.print("AI:  " .. tostring(game.points.ai), 350, 20)
    love.graphics.print("Mana: " .. tostring(game.mana), 500, 20)

    for loc = 1, ZONE_COUNT do
        local yAI     = ZONE_TOP_Y + (loc - 1) * (ZONE_HEIGHT + ZONE_SPACING)
        local yPlayer = ZONE_BOTTOM_Y + (loc - 1) * (ZONE_HEIGHT + ZONE_SPACING)

        love.graphics.setColor(COLOR_ZONE[1], COLOR_ZONE[2], COLOR_ZONE[3])
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

        if #game.history > 1 then
            local ux, uy = 20, WINDOW_HEIGHT - btnH - 20
            love.graphics.setColor(0.4, 0.4, 0.8)
            love.graphics.rectangle("fill", ux, uy, btnW, btnH, 6, 6)
            love.graphics.setColor(1,1,1)
            love.graphics.printf("Undo", ux, uy + 12, btnW, "center")
        end
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

    if screen == "inspect" and inspectedCard then
        love.graphics.setColor(0, 0, 0, 0.8)
        love.graphics.rectangle("fill", 0, 0, WINDOW_WIDTH, WINDOW_HEIGHT)
        love.graphics.setColor(1, 1, 1)
        local scale = 3
        local cx = WINDOW_WIDTH / 2
        local cy = WINDOW_HEIGHT / 2 - 40
        love.graphics.push()
        love.graphics.translate(cx - inspectedCard.width * scale / 2, cy - inspectedCard.height * scale / 2)
        love.graphics.scale(scale)
        local ox, oy = inspectedCard.x, inspectedCard.y
        inspectedCard.x, inspectedCard.y = 0, 0
        inspectedCard:draw()
        inspectedCard.x, inspectedCard.y = ox, oy
        love.graphics.pop()
        love.graphics.setFont(FONT_LARGE)
        love.graphics.printf(inspectedCard.name, 0, cy + inspectedCard.height * scale / 2 + 10, WINDOW_WIDTH, "center")
        love.graphics.setFont(FONT_SMALL)
        love.graphics.printf("Cost: " .. tostring(inspectedCard.cost), 0, cy + inspectedCard.height * scale / 2 + 40, WINDOW_WIDTH, "center")
        if inspectedCard.description then
            love.graphics.printf(inspectedCard.description,
                WINDOW_WIDTH/2 - 200,
                cy + inspectedCard.height * scale / 2 + 60,
                400,
                "center")
        end
        love.graphics.printf("Click to close", 0, WINDOW_HEIGHT - 40, WINDOW_WIDTH, "center")
    end
end


function love.mousepressed(x, y, button)

    if screen == "title" then
        if button == 1 then
            startGame()
            screen = "game"
        end
        return
    elseif screen == "inspect" then
        screen = "game"
        inspectedCard = nil
        return
    end

    if screen == "game" and button == 2 then
        local c = findCardAt(x, y)
        if c then
            inspectedCard = c
            screen = "inspect"
            return
        end
    end

    if button ~= 1 or game.gameOver then return end

    local btnW, btnH = 120, 40
    local ux, uy = 20, WINDOW_HEIGHT - btnH - 20
    if x >= ux and x <= ux + btnW and y >= uy and y <= uy + btnH then
        local prev = game:undoTurn()
        if prev then
            game = prev
        end
        return
    end

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
               game:recordHistory()
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
    if screen ~= "game" then return end
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
    if screen == "title" then
        if key == "return" or key == "space" then
            startGame()
            screen = "game"
        end
        return
    elseif screen == "inspect" then
        screen = "game"
        inspectedCard = nil
        return
    end

    if key == "r" and game.gameOver then
        startGame()
    elseif key == "n" and not game.gameOver then
        if game.submitted then
            game:nextTurn()
            game:layoutHands()
            game:recordHistory()
        end
    end
end
