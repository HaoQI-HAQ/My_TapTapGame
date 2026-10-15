-- ============================================================================
-- 《酒桌文化》v1.2.1 核心游戏逻辑
-- 5天循环 / 职级晋升 / 休息日 / 区域老板双局制 / 结算判定
-- ============================================================================

local GameData = require("Data.GameData")

local GameLogic = {}

-- ============================================================================
-- 游戏状态
-- ============================================================================
GameLogic.State = {
    -- 开局选择（一旦选定整局不变）
    workplace = nil,    ---@type table|nil
    character = nil,    ---@type table|nil

    -- 当日酒局选择（每天重选）
    restaurant = nil,   ---@type table|nil
    drinkType = nil,    ---@type table|nil
    drinkBrand = nil,   ---@type table|nil
    dish = nil,         ---@type table|nil
    opponent = nil,     ---@type table|nil
    lastChoiceFeedback = "", -- 上一回合实际变化，保留到下一回合显示
    lastChoiceChanges = {},  ---@type table<string, number>
    banquetId = 0,
    banquetSerial = 0,
    settledBanquets = {},    ---@type table<number, table>
    bossFinalAnswered = false,
    bossApproved = false,
    bossCompleted = false,
    bossDefeated = false,
    budgetFailure = false, -- 无法负担当天完整酒局，按optimized结算，不充值

    -- 职级系统
    currentLevel = 1,       -- 当前职级 Lv.1~8
    startLevel = 1,         -- 起始职级（用于终局评定）
    money = 0,              -- 当前资金

    -- 5天系统
    currentDay = 1,         -- 当前天数 (1~5, 区域老板 1~2)
    maxDays = 5,            -- 总天数 (普通5, 区域老板2)
    optimizeCount = 0,      -- 被优化次数
    maxOptimize = 3,        -- 最大被优化次数 (普通3, 区域老板1)
    restDayUsed = false,    -- 是否已用过休息日
    todayIsRest = false,    -- 今天是否为休息日
    banquetCount = 0,       -- 实际完成酒局数
    consecutivePromote = 0, -- 连续升职次数
    maxConsecutive = 0,     -- 最高连续升职

    -- 每日酒局属性（每场重置）
    favor = 50,         -- 好感度 (0-100)
    dignity = 50,       -- 尊严值 (0-100)
    sober = 100,        -- 清醒度 (0-100)
    vibe = 50,          -- 氛围值 (0-100)
    face = 0,           -- 面子值
    pro = 0,            -- 专业度

    -- 回合状态
    round = 0,
    maxRounds = 8,
    playerDice = 0,
    opponentDice = 0,
    currentEvent = nil,     ---@type table|nil
    eventHistory = {},
    usedSkillToday = false,
    drinkCount = 0,
    totalSpent = 0,
    firstMistakeUsed = false, -- 实习生萌新光环

    -- 历史记录
    dayHistory = {},    -- { day=1, result="promote", levelBefore=1, levelAfter=2 }

    -- 游戏阶段
    phase = "menu",
    -- menu / select_workplace / select_character /
    -- day_start / rest_day /
    -- select_restaurant / select_drink_type / select_drink_brand / select_dish /
    -- playing / day_result /
    -- game_over

    -- 终局类型
    gameOverType = nil, -- "win" / "fired" / "timeout"
}

-- ============================================================================
-- 初始化 / 重置
-- ============================================================================
function GameLogic.Reset()
    local s = GameLogic.State
    s.workplace = nil
    s.character = nil
    s.restaurant = nil
    s.drinkType = nil
    s.drinkBrand = nil
    s.dish = nil
    s.opponent = nil
    s.lastChoiceFeedback = ""
    s.lastChoiceChanges = {}
    s.banquetId = 0
    s.banquetSerial = 0
    s.settledBanquets = {}
    s.bossFinalAnswered = false
    s.bossApproved = false
    s.bossCompleted = false
    s.bossDefeated = false
    s.budgetFailure = false
    s.currentLevel = 1
    s.startLevel = 1
    s.money = 0
    s.currentDay = 1
    s.maxDays = 5
    s.optimizeCount = 0
    s.maxOptimize = 3
    s.restDayUsed = false
    s.todayIsRest = false
    s.banquetCount = 0
    s.consecutivePromote = 0
    s.maxConsecutive = 0
    s.favor = 50
    s.dignity = 50
    s.sober = 100
    s.vibe = 50
    s.face = 0
    s.pro = 0
    s.round = 0
    s.maxRounds = 8
    s.playerDice = 0
    s.opponentDice = 0
    s.currentEvent = nil
    s.eventHistory = {}
    s.usedSkillToday = false
    s.drinkCount = 0
    s.totalSpent = 0
    s.firstMistakeUsed = false
    s.dayHistory = {}
    s.phase = "menu"
    s.gameOverType = nil
end

-- ============================================================================
-- 开局选择
-- ============================================================================
function GameLogic.StartNewGame()
    GameLogic.Reset()
    GameLogic.State.phase = "select_workplace"
end

function GameLogic.SelectWorkplace(workplace)
    local s = GameLogic.State
    s.workplace = workplace
    s.phase = "select_character"
end

function GameLogic.SelectCharacter(character)
    local s = GameLogic.State
    s.character = character
    s.startLevel = character.startLevel
    s.currentLevel = character.startLevel

    -- 根据职级设置初始资金
    local levelData = GameData.Levels[s.currentLevel]
    s.money = levelData.money

    -- 区域老板特殊规则
    if character.isRegionalBoss then
        s.maxDays = 2
        s.maxOptimize = 1
    else
        s.maxDays = 5
        s.maxOptimize = 3
    end

    -- 进入第一天
    s.currentDay = 1
    s.phase = "day_start"
end

-- ============================================================================
-- 每日流程
-- ============================================================================

--- 判定今天是否是休息日
function GameLogic.DetermineRestDay()
    local s = GameLogic.State

    -- 区域老板没有休息日
    if s.character.isRegionalBoss then
        s.todayIsRest = false
        return false
    end

    -- 休息日只在第2-4天，且只出现一次，概率30%
    if not s.restDayUsed and s.currentDay >= 2 and s.currentDay <= 4 then
        if math.random() < 0.3 then
            s.todayIsRest = true
            s.restDayUsed = true
            return true
        end
    end

    s.todayIsRest = false
    return false
end

--- 开始新一天（由 UI 调用）
function GameLogic.StartDay()
    local s = GameLogic.State
    if s.phase ~= "day_start" or not s.character then return false, "当前不能开始新一天" end

    -- 仅在每日消费之前重置；后续餐厅/酒/菜加成不得再被清掉。
    GameLogic.ResetBanquetStats()
    s.restaurant = nil
    s.drinkType = nil
    s.drinkBrand = nil
    s.dish = nil
    s.opponent = nil

    if GameLogic.DetermineRestDay() then
        s.banquetId = 0
        s.phase = "rest_day"
    else
        s.banquetSerial = s.banquetSerial + 1
        s.banquetId = s.banquetSerial
        s.phase = "select_restaurant"
    end
    print(string.format("[Day] day=%d phase=%s banquet=%d", s.currentDay, s.phase, s.banquetId))
    return true
end

--- 休息日结束 → 进入下一天
function GameLogic.EndRestDay()
    local s = GameLogic.State
    if s.phase ~= "rest_day" then return false, "当前不是休息日" end
    table.insert(s.dayHistory, {
        day = s.currentDay,
        result = "rest",
        levelBefore = s.currentLevel,
        levelAfter = s.currentLevel,
    })
    return GameLogic.AdvanceDay()
end

-- ============================================================================
-- 选择阶段（每日酒局）
-- ============================================================================

-- 使用目录数据作为权威来源；列表副本的 cost/affordable 不会改变价格或效果。
---@param items table[]
---@param selected table|string|nil
---@return table|nil
local function FindItem(items, selected)
    if not selected then return nil end
    local id = type(selected) == "table" and selected.id or selected
    local name = type(selected) == "table" and selected.name or selected
    for _, item in ipairs(items) do
        if (id and item.id == id) or (name and item.name == name) then return item end
    end
    return nil
end

-- 为后续必选项预留最低预算，避免选完场地/酒后卡在无可负担菜品的软锁。
---@param tier number
local function MinimumDishCost(tier)
    local cost = math.huge
    for _, dish in ipairs(GameData.Dishes) do
        if dish.tier == tier or dish.allTiers then cost = math.min(cost, dish.price) end
    end
    return cost
end

---@param typeId string|nil
local function MinimumBrandCost(typeId)
    local cost = math.huge
    for id, brands in pairs(GameData.DrinkBrands) do
        if not typeId or id == typeId then
            for _, brand in ipairs(brands) do cost = math.min(cost, brand.price) end
        end
    end
    return cost
end

---@param item table
---@param cost number
---@param reserve number|nil
---@return table
local function SelectionItem(item, cost, reserve)
    local copy = {}
    for key, value in pairs(item) do copy[key] = value end
    copy.cost = cost
    copy.reserve = reserve or 0
    copy.requiredBudget = cost + copy.reserve
    copy.affordable = GameLogic.State.money >= copy.requiredBudget
    return copy
end

---@param cost number
---@param reserve number|nil
---@return boolean, string|nil
local function Pay(cost, reserve)
    local s = GameLogic.State
    local required = cost + (reserve or 0)
    if s.money < required then
        local err = string.format("预算不足：需 ¥%d，余额 ¥%d", required, s.money)
        if reserve and reserve > 0 then err = err .. string.format("（含后续酒菜最低预算 ¥%d）", reserve) end
        print("[Budget] " .. err)
        return false, err
    end
    s.money = s.money - cost
    s.totalSpent = s.totalSpent + cost
    print(string.format("[Budget] banquet=%d cost=%d balance=%d", s.banquetId, cost, s.money))
    return true
end

--- 获取当前职级可选的餐厅
function GameLogic.GetAvailableRestaurants()
    local s = GameLogic.State
    local minTier, maxTier = GameData.GetTierRange(s.currentLevel)
    local results = {}
    for _, r in ipairs(GameData.Restaurants) do
        if r.tier >= minTier and r.tier <= maxTier then
            table.insert(results, SelectionItem(r, r.costPerPerson * 2, MinimumBrandCost(nil) + MinimumDishCost(r.tier)))
        end
    end
    return results
end

--- 普通对手依据餐厅而非职级；最终日用确定规则，不额外抽隐藏概率。
function GameLogic.SelectOpponent()
    local s = GameLogic.State
    if not s.restaurant then return nil end
    local opponent = GameData.HiddenBosses[1]
    if s.currentDay ~= s.maxDays then
        for _, npc in ipairs(GameData.Opponents) do
            if s.restaurant.tier >= npc.minTier and s.restaurant.tier <= npc.maxTier then
                opponent = npc
                break
            end
        end
    end
    -- 使用副本：最终回合切立绘不能污染静态数据或下一场。
    s.opponent = SelectionItem(opponent, 0)
    s.opponent.illustration = opponent.illustration or opponent.portrait
    print(string.format("[Opponent] day=%d tier=%d id=%s", s.currentDay, s.restaurant.tier, opponent.id))
    return s.opponent
end

function GameLogic.SelectRestaurant(restaurant)
    local s = GameLogic.State
    if s.phase ~= "select_restaurant" then return false, "当前不是选餐厅阶段" end
    local item = FindItem(GameLogic.GetAvailableRestaurants(), restaurant)
    if not item then return false, "餐厅尚未解锁" end
    local ok, err = Pay(item.costPerPerson * 2, item.reserve)
    if not ok then return false, err end
    s.restaurant = item
    s.face = s.face + item.faceBonus
    GameLogic.SelectOpponent()
    s.phase = "select_drink_type"
    return true
end

function GameLogic.SelectDrinkType(drinkType)
    local s = GameLogic.State
    if s.phase ~= "select_drink_type" then return false, "当前不是选酒类阶段" end
    local item = FindItem(GameData.DrinkTypes, drinkType)
    if not item then return false, "未知酒类" end
    if not s.restaurant then return false, "请先选择餐厅" end
    local required = MinimumBrandCost(item.id) + MinimumDishCost(s.restaurant.tier)
    if s.money < required then return false, "预算不足：这个酒类无法同时负担酒品牌和推荐菜，请换一种酒" end
    s.drinkType = item
    s.phase = "select_drink_brand"
    return true
end

function GameLogic.GetAvailableBrands()
    local s = GameLogic.State
    if not s.drinkType then return {} end
    local results = {}
    for _, brand in ipairs(GameData.DrinkBrands[s.drinkType.id] or {}) do
        local reserve = s.restaurant and MinimumDishCost(s.restaurant.tier) or 0
        table.insert(results, SelectionItem(brand, brand.price, reserve))
    end
    return results
end

function GameLogic.SelectDrinkBrand(brand)
    local s = GameLogic.State
    if s.phase ~= "select_drink_brand" then return false, "当前不是选酒品牌阶段" end
    local item = FindItem(GameLogic.GetAvailableBrands(), brand)
    if not item then return false, "品牌不属于所选酒类" end
    local ok, err = Pay(item.price, item.reserve)
    if not ok then return false, err end
    s.drinkBrand = item
    s.face = s.face + item.face

    if item.name == "飞天茅台" and s.workplace and s.workplace.id == "state" then
        s.favor = math.min(100, s.favor + 10)
        print("[Bonus] 飞天茅台 + 国企：好感+10（保留至酒局）")
    end
    s.phase = "select_dish"
    return true
end

--- 同餐厅Tier推荐菜 + 所有Tier均可选的解酒水果。
function GameLogic.GetAvailableDishes()
    local s = GameLogic.State
    if not s.restaurant then return {} end
    local results = {}
    for _, dish in ipairs(GameData.Dishes) do
        if dish.tier == s.restaurant.tier or dish.allTiers then
            table.insert(results, SelectionItem(dish, dish.price))
        end
    end
    return results
end

function GameLogic.SelectDish(dish)
    local s = GameLogic.State
    if s.phase ~= "select_dish" then return false, "当前不是选推荐菜阶段" end
    local item = FindItem(GameLogic.GetAvailableDishes(), dish)
    if not item then return false, "这道菜不在当前菜单" end
    local ok, err = Pay(item.price)
    if not ok then return false, err end
    s.dish = item
    s.face = s.face + item.face
    s.vibe = math.max(0, math.min(100, s.vibe + item.vibe))
    s.sober = math.max(0, math.min(100, s.sober + item.sober))
    s.phase = "playing"
    print(string.format("[Banquet] id=%d dish=%s face=%d favor=%d", s.banquetId, item.id, s.face, s.favor))
    return true
end

--- UI可据此显示“余额不足，结束当天”按钮；未付款也作为一次预算失误结算。
function GameLogic.GetBudgetStatus()
    local s = GameLogic.State
    local minimum = math.huge
    if s.phase == "select_restaurant" then
        for _, restaurant in ipairs(GameLogic.GetAvailableRestaurants()) do
            minimum = math.min(minimum, restaurant.requiredBudget)
        end
    elseif s.phase == "select_drink_type" and s.restaurant then
        minimum = MinimumBrandCost(nil) + MinimumDishCost(s.restaurant.tier)
    elseif s.phase == "select_drink_brand" then
        for _, brand in ipairs(GameLogic.GetAvailableBrands()) do minimum = math.min(minimum, brand.requiredBudget) end
    elseif s.phase == "select_dish" then
        for _, dish in ipairs(GameLogic.GetAvailableDishes()) do minimum = math.min(minimum, dish.requiredBudget) end
    else
        return { canContinue = true, canEndDay = false, minimumRequired = 0, shortfall = 0, message = "" }
    end
    local canContinue = s.money >= minimum
    return {
        canContinue = canContinue, canEndDay = not canContinue,
        minimumRequired = minimum, shortfall = math.max(0, minimum - s.money),
        message = canContinue and "" or string.format("余额 ¥%d，最低酒局剩余预算 ¥%d；可结束当天，按被优化结算，不再扣钱", s.money, minimum),
    }
end

function GameLogic.EndDayForInsufficientBudget()
    local s = GameLogic.State
    local status = GameLogic.GetBudgetStatus()
    if not status.canEndDay then return false, "尚有可负担选项，不能以预算不足结束当天" end
    s.budgetFailure = true
    s.currentEvent = nil
    s.lastChoiceFeedback = status.message
    s.phase = "day_result"
    print(string.format("[BudgetFailure] day=%d banquet=%d balance=%d minimum=%d -> optimized", s.currentDay, s.banquetId, s.money, status.minimumRequired))
    return true
end

--- 重置每场酒局的回合状态（只允许每日开始前调用，拒绝消费后毁掉加成）
function GameLogic.ResetBanquetStats()
    local s = GameLogic.State
    if s.phase ~= "day_start" and s.phase ~= "menu" then
        return false, "酒局消费后不能重置属性"
    end
    s.favor = 50
    s.dignity = 50
    s.sober = 100
    s.vibe = 50
    s.face = 0
    s.pro = 0
    s.round = 0
    s.maxRounds = math.random(6, 10)
    s.playerDice = 0
    s.opponentDice = 0
    s.eventHistory = {}
    s.usedSkillToday = false
    s.drinkCount = 0
    s.firstMistakeUsed = false
    s.currentEvent = nil
    s.lastChoiceFeedback = ""
    s.lastChoiceChanges = {}
    s.bossFinalAnswered = false
    s.bossApproved = false
    s.bossCompleted = false
    s.bossDefeated = false
    s.budgetFailure = false
    return true
end

-- ============================================================================
-- 骰子系统
-- ============================================================================
function GameLogic.RollDice()
    local s = GameLogic.State
    if s.phase ~= "playing" or s.currentEvent then return s.playerDice, s.opponentDice end
    s.playerDice = math.random(1, 6)
    s.opponentDice = math.random(1, 6)

    -- 面子值加成
    if s.face > 20 and math.random() < 0.2 then
        s.playerDice = math.min(6, s.playerDice + 1)
    end

    return s.playerDice, s.opponentDice
end

function GameLogic.GetDiceResult()
    local s = GameLogic.State
    if s.playerDice == s.opponentDice then
        return "tie"
    elseif s.playerDice > s.opponentDice then
        return "advantage"
    else
        return "passive"
    end
end

-- ============================================================================
-- 事件系统
-- ============================================================================
function GameLogic.GetNextEvent()
    local s = GameLogic.State
    if s.phase ~= "playing" then return nil end
    -- 重建屏幕不能偷偷推进回合；必须先回答当前事件。
    if s.currentEvent then return s.currentEvent end
    if s.round >= s.maxRounds or s.sober <= 0 then
        s.phase = "day_result"
        return nil
    end
    s.round = s.round + 1

    if s.opponent and s.opponent.isBoss then
        local lastIndex = #GameData.BossEvents
        local index = s.round >= s.maxRounds and lastIndex or ((s.round - 1) % (lastIndex - 1) + 1)
        local event = GameData.BossEvents[index]
        if event.type == "final" then
            s.opponent.portrait = s.opponent.finalPortrait
        elseif s.opponent.portraits then
            -- 表情用于对话头像；illustration始终保持舞台全身立绘。
            local mood = s.sober <= 30 and "drunk" or s.favor >= 70 and "smile" or s.favor < 40 and "skeptical" or "normal"
            s.opponent.portrait = s.opponent.portraits[mood]
        end
        s.currentEvent = event
        table.insert(s.eventHistory, event.id)
        print(string.format("[BossEvent] banquet=%d round=%d id=%s", s.banquetId, s.round, event.id))
        return event
    end

    -- 最后回合触发终极事件
    if s.round >= s.maxRounds then
        for _, e in ipairs(GameData.DialogEvents) do
            if e.type == "final" then
                s.currentEvent = e
                return e
            end
        end
    end

    -- 醉酒事件
    if s.sober <= 30 then
        for _, e in ipairs(GameData.DialogEvents) do
            if e.type == "drunk" then
                s.currentEvent = e
                return e
            end
        end
    end

    -- 常规事件筛选
    local diceResult = GameLogic.GetDiceResult()
    local candidates = {}

    for _, e in ipairs(GameData.DialogEvents) do
        if e.type ~= "final" and e.type ~= "drunk" then
            local triggerMatch = (e.trigger == "any" or e.trigger == s.workplace.id)
            if triggerMatch then
                local used = false
                for _, h in ipairs(s.eventHistory) do
                    if h == e.id then used = true; break end
                end
                if not used then
                    if diceResult == "tie" and e.type == "drink" then
                        table.insert(candidates, 1, e)
                    else
                        table.insert(candidates, e)
                    end
                end
            end
        end
    end

    if #candidates > 0 then
        local idx = math.random(1, #candidates)
        local event = candidates[idx]
        table.insert(s.eventHistory, event.id)
        s.currentEvent = event
        return event
    end

    -- 所有事件用完，随机重用
    local allEvents = {}
    for _, e in ipairs(GameData.DialogEvents) do
        if e.type ~= "final" and e.type ~= "drunk" then
            local triggerMatch = (e.trigger == "any" or e.trigger == s.workplace.id)
            if triggerMatch then
                table.insert(allEvents, e)
            end
        end
    end
    if #allEvents > 0 then
        local event = allEvents[math.random(1, #allEvents)]
        s.currentEvent = event
        return event
    end

    return nil
end

-- ============================================================================
-- 选择处理
-- ============================================================================
--- 保留原 choice 返回值；UI可传事件id/回合数拒绝旧按钮的迟到回调。
function GameLogic.MakeChoice(choiceIndex, eventId, round)
    local s = GameLogic.State
    if s.phase ~= "playing" or not s.currentEvent then return nil, "当前没有待回答事件" end
    local event = s.currentEvent
    if (eventId and eventId ~= event.id) or (round and round ~= s.round) then
        return nil, "该选项已过期"
    end
    local choice = event.choices[choiceIndex]
    if not choice then return nil, "无效选项" end

    local effects = choice.effects or {}
    if effects.money and effects.money < 0 and s.money < -effects.money then
        return nil, "预算不足，无法执行该选项"
    end
    local before = {
        favor = s.favor, dignity = s.dignity, sober = s.sober, vibe = s.vibe,
        face = s.face, pro = s.pro, money = s.money,
    }
    local skillMessage = ""

    -- 应用效果
    if effects.favor then
        local delta = effects.favor
        -- 销售技能：好感度增减×1.5
        if s.character.id == "sales" then
            delta = math.floor(delta * 1.5)
        end
        -- 实习生技能：第一次失误不扣好感
        if s.character.id == "intern" and delta < 0 and not s.firstMistakeUsed then
            s.firstMistakeUsed = true
            delta = 0
            skillMessage = "；萌新光环免除本次好感损失"
        end
        s.favor = math.max(0, math.min(100, s.favor + delta))
    end
    if effects.dignity then s.dignity = math.max(0, math.min(100, s.dignity + effects.dignity)) end
    if effects.sober then
        local soberDelta = effects.sober
        -- 程序员技能：清醒度下降减半
        if s.character.id == "dev" and soberDelta < 0 then
            soberDelta = math.floor(soberDelta / 2)
        end
        s.sober = math.max(0, math.min(100, s.sober + soberDelta))
    end
    if effects.vibe then s.vibe = math.max(0, math.min(100, s.vibe + effects.vibe)) end
    if effects.face then s.face = s.face + effects.face end
    if effects.pro then s.pro = s.pro + effects.pro end
    if effects.money then
        s.money = s.money + effects.money
        if effects.money < 0 then
            s.totalSpent = s.totalSpent + math.abs(effects.money)
        end
    end

    -- 统计
    if effects.sober and effects.sober < 0 then
        s.drinkCount = s.drinkCount + 1
    end

    if s.opponent and s.opponent.isBoss and event.type == "final" then
        s.bossFinalAnswered = true
        s.bossApproved = effects.bossApproval == true
        s.bossCompleted = true
    end

    -- 用实际变化生成反馈（包含技能修正和上下限裁剪，不报原始配置值）。
    local labels = { favor = "好感", dignity = "尊严", sober = "清醒", vibe = "氛围", face = "面子", pro = "专业", money = "资金" }
    local changes, parts = {}, {}
    for _, key in ipairs({ "favor", "dignity", "sober", "vibe", "face", "pro", "money" }) do
        local delta = s[key] - before[key]
        changes[key] = delta
        if delta ~= 0 then table.insert(parts, labels[key] .. string.format("%+d", delta)) end
    end
    s.lastChoiceChanges = changes
    s.lastChoiceFeedback = "上一回合：" .. choice.text .. "；" .. (#parts > 0 and table.concat(parts, "、") or "属性无变化") .. skillMessage
    if s.opponent and s.opponent.isBoss and event.type == "final" then
        s.lastChoiceFeedback = s.lastChoiceFeedback .. (s.bossApproved and "；普老板认可你的责任承诺" or "；普老板未认可这份回答")
    end
    print(string.format("[Choice] banquet=%d round=%d %s", s.banquetId, s.round, s.lastChoiceFeedback))
    s.currentEvent = nil -- 本事件只可回答一次；下一次GetNextEvent才生成新事件。

    if s.round >= s.maxRounds or s.sober <= 0 then
        s.phase = "day_result"
    else
        s.phase = "playing"
    end

    return choice
end

-- ============================================================================
-- 单日结算
-- ============================================================================

--- 纯数值评分，保留既有权重；可直接在独立Lua环境测试。
function GameLogic.GetBanquetScore()
    local s = GameLogic.State
    return s.favor * 0.35 + s.face * 0.2 + s.pro * 0.15 + s.vibe * 0.15
        + (s.sober / 100) * 15 - s.currentLevel * 3
end

function GameLogic.GetPromotionThreshold()
    return GameData.PromotionRules.scoreThresholds[GameLogic.State.currentLevel] or 55
end

--- 判定本场酒局结果: "promote" / "maintain" / "demote" / "optimized"
function GameLogic.GetBanquetResult()
    local s = GameLogic.State
    local settled = s.settledBanquets[s.banquetId]
    if settled then return settled.result end
    if s.budgetFailure or s.sober <= 0 then return "optimized" end
    local score = GameLogic.GetBanquetScore()
    if score >= GameLogic.GetPromotionThreshold() then
        -- 普老板不是花钱刷面子就能通过，必须完成终局且回答获认可。
        if s.opponent and s.opponent.isBoss and (not s.bossFinalAnswered or not s.bossApproved) then
            return "maintain"
        end
        return "promote"
    elseif score >= 35 then
        return "maintain"
    elseif score >= 20 then
        return "demote"
    else
        return "optimized"
    end
end

--- 正常晋升+1；极佳表现+2，条件公开且不改变随机数或为测试强行升职。
function GameLogic.GetPromotionSteps()
    local s = GameLogic.State
    if s.character and s.character.isRegionalBoss then return 1 end
    local rule = GameData.PromotionRules
    if GameLogic.GetBanquetScore() >= GameLogic.GetPromotionThreshold() and s.favor >= rule.minFavor
        and s.sober >= rule.minSober and s.dignity >= rule.minDignity and s.pro >= rule.minPro then
        return rule.exceptionalLevels
    end
    return 1
end

--- 每场id幂等：首次 true,record；重复 false,原record；错误 false,err。
--- 可选banquetId用于拒绝上一场的迟到回调；旧调用 ApplyBanquetResult(result) 仍合法。
function GameLogic.ApplyBanquetResult(result, banquetId)
    local s = GameLogic.State
    local id = banquetId or s.banquetId
    local settled = s.settledBanquets[id]
    if settled then
        print(string.format("[Result] ignore duplicate banquet=%d", id))
        return false, settled
    end
    if id ~= s.banquetId or id <= 0 or s.phase ~= "day_result" then
        return false, "酒局尚未结束或结算已过期"
    end
    result = result or GameLogic.GetBanquetResult()
    if result ~= "promote" and result ~= "maintain" and result ~= "demote" and result ~= "optimized" then
        return false, "无效结算结果"
    end
    local levelBefore = s.currentLevel
    local score = GameLogic.GetBanquetScore()
    local promotionThreshold = GameLogic.GetPromotionThreshold()
    local promotionSteps = 0
    if result == "promote" then
        promotionSteps = GameLogic.GetPromotionSteps()
        s.currentLevel = math.min(8, s.currentLevel + promotionSteps)
        s.consecutivePromote = s.consecutivePromote + 1
        s.maxConsecutive = math.max(s.maxConsecutive, s.consecutivePromote)
    elseif result == "demote" then
        s.currentLevel = math.max(1, s.currentLevel - 1)
        s.consecutivePromote = 0
    elseif result == "optimized" then
        s.currentLevel = math.max(1, s.currentLevel - 1)
        s.optimizeCount = s.optimizeCount + 1
        s.consecutivePromote = 0
    else
        s.consecutivePromote = 0
    end

    local newLevelData = GameData.Levels[s.currentLevel]
    if newLevelData and result == "promote" then
        s.money = math.max(s.money, newLevelData.money)
    end
    s.banquetCount = s.banquetCount + 1
    s.bossDefeated = s.opponent ~= nil and s.opponent.isBoss == true
        and s.bossFinalAnswered and s.bossApproved and result == "promote" and s.sober > 0

    local record = {
        banquetId = id, day = s.currentDay, result = result,
        levelBefore = levelBefore, levelAfter = s.currentLevel,
        score = score, promotionThreshold = promotionThreshold, promotionSteps = s.currentLevel - levelBefore,
        promotionReason = promotionSteps > 1 and GameData.PromotionRules.description or "",
        opponentId = s.opponent and s.opponent.id or "",
        bossCompleted = s.bossCompleted, bossDefeated = s.bossDefeated,
        budgetFailure = s.budgetFailure,
    }
    s.settledBanquets[id] = record
    table.insert(s.dayHistory, record)
    print(string.format("[Result] banquet=%d result=%s score=%.2f Lv.%d->%d bossDefeated=%s",
        id, result, score, levelBefore, s.currentLevel, tostring(s.bossDefeated)))
    if promotionSteps > 1 then print("[Promotion] " .. GameData.PromotionRules.description) end
    return true, record
end

-- ============================================================================
-- 天数推进 / 终局判定
-- ============================================================================

--- 推进到下一天或触发终局
function GameLogic.AdvanceDay()
    local s = GameLogic.State
    if s.phase ~= "day_result" and s.phase ~= "rest_day" then
        return false, "当天尚未完成或已经推进"
    end
    local settled = s.settledBanquets[s.banquetId]
    if s.phase == "day_result" and not settled then return false, "请先完成酒局结算" end

    -- 失败优先，不能用之前升到Lv.8掩盖本日被优化。
    if s.optimizeCount >= s.maxOptimize then
        s.gameOverType = "fired"
        s.phase = "game_over"
        return true
    end

    -- 区域老板Day1到Lv.8仍继续Day2；必须在Day2完成且击败普老板。
    -- 普通角色也必须完成最终日Boss；提前到Lv.8不能跳过终局。
    local regional = s.character and s.character.isRegionalBoss
    local canWin = s.currentLevel >= 8 and s.currentDay == s.maxDays
        and settled ~= nil and settled.bossDefeated == true
    if regional then
        canWin = canWin and s.currentDay == 2
    end
    if canWin then
        s.gameOverType = "win"
        s.phase = "game_over"
        return true
    end

    if s.currentDay >= s.maxDays then
        s.gameOverType = "timeout"
        s.phase = "game_over"
        return true
    end

    s.currentDay = s.currentDay + 1
    s.phase = "day_start"
    return true
end

--- 从 day_result 进入下一天
function GameLogic.ProceedAfterResult()
    return GameLogic.AdvanceDay()
end

-- ============================================================================
-- 终局评定
-- ============================================================================

--- 获取终局评定（5天用完时）
function GameLogic.GetFinalRating()
    local s = GameLogic.State
    local diff = s.currentLevel - s.startLevel

    if s.currentLevel == 7 then
        return GameData.FinalRatings[1] -- 差一步
    elseif diff >= 3 then
        return GameData.FinalRatings[2] -- 表现优秀
    elseif diff >= 1 then
        return GameData.FinalRatings[3] -- 有所进步
    elseif diff == 0 then
        return GameData.FinalRatings[4] -- 原地踏步
    else
        return GameData.FinalRatings[5] -- 不升反降
    end
end

--- 获取称号
function GameLogic.GetTitle()
    local s = GameLogic.State

    if s.gameOverType == "win" and s.banquetCount <= 3 then
        return GameData.Titles[7] -- 速通之王
    end
    if s.gameOverType == "fired" and s.dignity >= 70 then
        return GameData.Titles[1] -- 00后整顿职场
    end
    if s.gameOverType == "timeout" and s.currentLevel == 7 then
        return GameData.Titles[8] -- 无冕之王
    end
    if s.drinkCount >= 8 and s.sober > 0 then
        return GameData.Titles[3] -- 千杯不醉
    end
    if s.favor >= 90 then
        return GameData.Titles[4] -- 舔王
    end
    if s.totalSpent >= 20000 then
        return GameData.Titles[5] -- 钞能力
    end

    -- 默认
    return { name = "职场新人", desc = "普普通通的打工人" }
end

--- 获取职级数据
function GameLogic.GetLevelData(level)
    return GameData.Levels[level] or GameData.Levels[1]
end

--- 获取结算描述文案
function GameLogic.GetResultMessage(result)
    local messages = {
        promote = { "恭喜！下周一去新部门报到！", "表现亮眼，升职加薪！", "领导很满意你今晚的表现！" },
        maintain = { "这顿饭...好像白吃了", "不功不过，明天继续搬砖", "至少没丢工作" },
        demote = { "最近状态不太好啊...", "你被调去了边缘部门", "表现不行，降级处理" },
        optimized = { "明天来HR办公室一趟", "你已被移出工作群", "收拾收拾东西吧..." },
    }
    local pool = messages[result] or messages.maintain
    return pool[math.random(1, #pool)]
end

return GameLogic
