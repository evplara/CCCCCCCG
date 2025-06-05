
print( type(love) )
if false then
  baby:hurt(me)
end
local Card = require "card"

local Game = {}
Game.__index = Game


local WINDOW_WIDTH   = 1024
local WINDOW_HEIGHT  = 768

local CARD_WIDTH     = 40
local CARD_HEIGHT    = 60

local HAND_Y         = WINDOW_HEIGHT - CARD_HEIGHT - 20
local HAND_SPACING   = 15

local ZONE_TOP_Y     = 80
local ZONE_BOTTOM_Y  = 400
local ZONE_HEIGHT    = 80
local ZONE_SPACING   = 20
local ZONE_COUNT     = 3
local SLOTS_PER_ZONE = 4

local TARGET_POINTS  = 15  

local function shuffle(t)
    for i = #t, 2, -1 do
        local j = love.math.random(1, i)
        t[i], t[j] = t[j], t[i]
    end
end


function Game:new()
    local obj = setmetatable({
        decks    = { player = {}, ai = {} },  
        hands    = { player = {}, ai = {} },  
        discards = { player = {}, ai = {} },

        zones    = {
            player = { {}, {}, {} }, 
            ai     = { {}, {}, {} }
        },

        listeners   = {}, 
        stagingOrder = {},  

        mana             = 0,
        aiMana           = 0,
        nextTurnManaBonus= { player = 0, ai = 0 },

        points = { player = 0, ai = 0 },
        turn   = 1,

        draggingCard = nil,
        submitted    = false,

        gameOver = false,
        winner   = nil
    }, Game)

    obj:initializeDecks()
    obj:shuffleAndDeal()
    return obj
end


function Game:initializeDecks()
    local nonVanillaNames = {
        "Zeus", "Artemis", "Athena", "Apollo", "Demeter",
        "Midas", "Ares", "Hades", "Hera", "Prometheus"
    }

    for _, owner in ipairs({ "player", "ai" }) do
        for _, name in ipairs(nonVanillaNames) do
            table.insert(self.decks[owner], Card:new(name, owner))
            table.insert(self.decks[owner], Card:new(name, owner))
        end
        shuffle(self.decks[owner])
    end
end


function Game:drawCard(owner)
    if #self.hands[owner] >= 7 then return end
    local deck = self.decks[owner]
    if #deck == 0 then return end

    local card = table.remove(deck, 1)
    card.currentPower = card.basePower
    card.faceDown     = false
    card.inZone       = false
    card.location     = nil

    table.insert(self.hands[owner], card)
end


function Game:shuffleAndDeal()
    shuffle(self.decks.player)
    shuffle(self.decks.ai)
    for i = 1, 3 do
        self:drawCard("player")
        self:drawCard("ai")
    end
    self.mana   = self.turn
    self.aiMana = self.turn
end


function Game:layoutHands()
    
    local hand = self.hands.player
    local count = #hand
    local totalWidth = count * CARD_WIDTH + (count - 1) * HAND_SPACING
    local startX = (WINDOW_WIDTH - totalWidth) / 2
    for i, card in ipairs(hand) do
        card.x = startX + (i - 1) * (CARD_WIDTH + HAND_SPACING)
        card.y = HAND_Y
    end

    
    local aiHand = self.hands.ai
    local aicount = #aiHand
    local totalAIW = aicount * CARD_WIDTH + (aicount - 1) * HAND_SPACING
    local aiStartX = (WINDOW_WIDTH - totalAIW) / 2
    for i, card in ipairs(aiHand) do
        card.x = aiStartX + (i - 1) * (CARD_WIDTH + HAND_SPACING)
        card.y = 20 
    end
end


function Game:zoneHasSpace(owner, loc)
    return #self.zones[owner][loc] < SLOTS_PER_ZONE
end


function Game:getZoneAt(px, py, owner)
    for loc = 1, ZONE_COUNT do
        local y1, y2
        if owner == "player" then
            y1 = ZONE_BOTTOM_Y + (loc - 1) * (ZONE_HEIGHT + ZONE_SPACING)
            y2 = y1 + ZONE_HEIGHT
        else
            y1 = ZONE_TOP_Y + (loc - 1) * (ZONE_HEIGHT + ZONE_SPACING)
            y2 = y1 + ZONE_HEIGHT
        end
        if py >= y1 and py <= y2 then
            return loc
        end
    end
    return nil
end


function Game:placeCardInZone(card, loc)
    if card.owner ~= "player" then return false end
    if self.submitted then return false end
    if not self:zoneHasSpace("player", loc) then return false end
    if self.mana < card.cost then return false end

    self.mana = self.mana - card.cost

    for i, c in ipairs(self.hands.player) do
        if c == card then
            table.remove(self.hands.player, i)
            break
        end
    end

    card.inZone   = true
    card.location = loc
    card.faceDown = true
    card.revealed = false

    table.insert(self.zones.player[loc], card)
    table.insert(self.stagingOrder, { card = card, owner = "player", location = loc })

    for _, listener in ipairs(self.listeners) do
        listener({ type = "cardPlayed", player = "player", card = card, location = loc })
    end

    return true
end


function Game:aiPlaceCards()
    local keepGoing = true
    while keepGoing do
        keepGoing = false

        local choices = {}
        for _, c in ipairs(self.hands.ai) do
            if c.cost <= self.aiMana then
                table.insert(choices, c)
            end
        end
        if #choices == 0 then break end

        local idx = love.math.random(#choices)
        local c = choices[idx]

        local possibleLocs = {}
        for loc = 1, ZONE_COUNT do
            if self:zoneHasSpace("ai", loc) then
                table.insert(possibleLocs, loc)
            end
        end
        if #possibleLocs == 0 then break end

        local chosenLoc = possibleLocs[love.math.random(#possibleLocs)]

        
        self.aiMana = self.aiMana - c.cost
        for i, x in ipairs(self.hands.ai) do
            if x == c then
                table.remove(self.hands.ai, i)
                break
            end
        end

        c.inZone   = true
        c.location = chosenLoc
        c.faceDown = true
        c.revealed = false

        table.insert(self.zones.ai[chosenLoc], c)


        table.insert(self.stagingOrder, { card = c, owner = "ai", location = chosenLoc })

        for _, listener in ipairs(self.listeners) do
            listener({ type = "cardPlayed", player = "ai", card = c, location = chosenLoc })
        end

        keepGoing = true
    end
end


function Game:resolveReveals()
    for _, entry in ipairs(self.stagingOrder) do
        local c = entry.card
        c.faceDown     = false
        c.revealed     = true
        c.currentPower = c.basePower
        if c.onReveal then
            c:onReveal(self)
        end
    end

    self.listeners = {}
end


function Game:computePointsAndCleanup()
    for loc = 1, ZONE_COUNT do
        local pSum, aSum = 0, 0
        for _, c in ipairs(self.zones.player[loc]) do
            pSum = pSum + c.currentPower
        end
        for _, c in ipairs(self.zones.ai[loc]) do
            aSum = aSum + c.currentPower
        end

        if pSum > aSum then
            self.points.player = self.points.player + (pSum - aSum)
        elseif aSum > pSum then
            self.points.ai = self.points.ai + (aSum - pSum)
        end
    end

    for _, owner in ipairs({ "player", "ai" }) do
        for loc = 1, ZONE_COUNT do
            while #self.zones[owner][loc] > 0 do
                local c = table.remove(self.zones[owner][loc], 1)
                c.inZone   = false
                c.location = nil
                c.faceDown = false
                c.revealed = false
                table.insert(self.discards[owner], c)
            end
        end
    end

    if self.points.player >= TARGET_POINTS or self.points.ai >= TARGET_POINTS then
        self.gameOver = true
        if self.points.player > self.points.ai then
            self.winner = "You Win!"
        elseif self.points.ai > self.points.player then
            self.winner = "AI Wins!"
        else
            self.winner = "Tie!"
        end
    end
end


function Game:nextTurn()
    if self.gameOver then return end

    self.turn = self.turn + 1

    self.mana   = self.turn + (self.nextTurnManaBonus.player or 0)
    self.aiMana = self.turn + (self.nextTurnManaBonus.ai or 0)
    self.nextTurnManaBonus.player = 0
    self.nextTurnManaBonus.ai     = 0

    self:drawCard("player")
    self:drawCard("ai")

    self.stagingOrder = {}
    self.submitted    = false
end

return Game
