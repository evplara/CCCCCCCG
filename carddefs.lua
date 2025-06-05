

local CardDefs = {
    WoodenCow = {
        cost = 1,
        basePower = 1,
        onReveal = function(self, game) end
    },
    Pegasus = {
        cost = 3,
        basePower = 5,
        onReveal = function(self, game) end
    },
    Minotaur = {
        cost = 5,
        basePower = 9,
        onReveal = function(self, game) end
    },
    Titan = {
        cost = 6,
        basePower = 12,
        onReveal = function(self, game) end
    },

    Zeus = {
        cost = 5,
        basePower = 4,
        onReveal = function(self, game)
            local loc = self.location
            for _, c in ipairs(game.zones[self.owner][loc]) do
                c.currentPower = math.max(0, c.currentPower - 1)
            end
            for _, c in ipairs(game.zones[self.opponent][loc]) do
                c.currentPower = math.max(0, c.currentPower - 1)
            end
        end
    },

    Artemis = {
        cost = 4,
        basePower = 3,
        onReveal = function(self, game)
            local loc = self.location
            local enemyCount = #game.zones[self.opponent][loc]
            if enemyCount == 1 then
                self.currentPower = self.currentPower + 5
            end
        end
    },

    Athena = {
        cost = 2,
        basePower = 2,
        onReveal = function(self, game)
            local loc = self.location
            table.insert(game.listeners, function(ev)
                if ev.type == "cardPlayed"
                  and ev.player == self.owner
                  and ev.location == loc
                  and ev.card ~= self
                then
                    self.currentPower = self.currentPower + 1
                end
            end)
        end
    },

    Apollo = {
        cost = 2,
        basePower = 1,
        onReveal = function(self, game)
            game.nextTurnManaBonus[self.owner] =
                (game.nextTurnManaBonus[self.owner] or 0) + 1
        end
    },

    Demeter = {
        cost = 3,
        basePower = 0,
        onReveal = function(self, game)
            game:drawCard(self.owner)
            game:drawCard(self.opponent)
        end
    },

    Midas = {
        cost = 5,
        basePower = 5,
        onReveal = function(self, game)
            local loc = self.location
            for _, c in ipairs(game.zones[self.owner][loc]) do
                c.currentPower = 3
            end
            for _, c in ipairs(game.zones[self.opponent][loc]) do
                c.currentPower = 3
            end
        end
    },

    Ares = {
        cost = 5,
        basePower = 6,
        onReveal = function(self, game)
            local loc = self.location
            local numEnemy = #game.zones[self.opponent][loc]
            self.currentPower = self.currentPower + 2 * numEnemy
        end
    },

    Hades = {
        cost = 4,
        basePower = 3,
        onReveal = function(self, game)
            local discardCount = #game.discards[self.owner]
            self.currentPower = self.currentPower + 2 * discardCount
        end
    },

    Hera = {
        cost = 3,
        basePower = 2,
        onReveal = function(self, game)
            for _, c in ipairs(game.hands[self.owner]) do
                c.currentPower = c.currentPower + 1
            end
        end
    },

    Prometheus = {
        cost = 4,
        basePower = 2,
        onReveal = function(self, game)
            game:drawCard(self.opponent)
        end
    },
}

return CardDefs
