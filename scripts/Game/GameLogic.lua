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
    -- select_restaurant / select_drink_type / select_drink_brand /
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

    -- 判定休息日
    if GameLogic.DetermineRestDay() then
        s.phase = "rest_day"
    else
        -- 正常酒局日，进入选饭局
        s.phase = "select_restaurant"
    end
end

--- 休息日结束 → 进入下一天
function GameLogic.EndRestDay()
    local s = GameLogic.State
    table.insert(s.dayHistory, {
        day = s.currentDay,
        result = "rest",
        levelBefore = s.currentLevel,
        levelAfter = s.currentLevel,
    })
    GameLogic.AdvanceDay()
end

-- ============================================================================
-- 选择阶段（每日酒局）
-- ============================================================================

--- 获取当前职级可选的餐厅
function GameLogic.GetAvailableRestaurants()
    local s = GameLogic.State
    local minTier, maxTier = GameData.GetTierRange(s.currentLevel)
    local results = {}
    for _, r in ipairs(GameData.Restaurants) do
        if r.tier >= minTier and r.tier <= maxTier then
            table.insert(results, r)
        end
    end
    return results
end

function GameLogic.SelectRestaurant(restaurant)
    local s = GameLogic.State
    s.restaurant = restaurant
    local cost = restaurant.costPerPerson * 2
    s.money = s.money - cost
    s.totalSpent = s.totalSpent + cost
    s.face = s.face + restaurant.faceBonus
    s.phase = "select_drink_type"
end

function GameLogic.SelectDrinkType(drinkType)
    local s = GameLogic.State
    s.drinkType = drinkType
    s.phase = "select_drink_brand"
end

function GameLogic.GetAvailableBrands()
    local s = GameLogic.State
    local typeId = s.drinkType.id
    return GameData.DrinkBrands[typeId] or {}
end

function GameLogic.SelectDrinkBrand(brand)
    local s = GameLogic.State
    s.drinkBrand = brand
    s.money = s.money - brand.price
    s.totalSpent = s.totalSpent + brand.price
    s.face = s.face + brand.face

    -- 特殊效果：茅台在国企加好感
    if brand.name == "飞天茅台" and s.workplace.id == "state" then
        s.favor = math.min(100, s.favor + 10)
    end

    -- 重置每场属性
    GameLogic.ResetBanquetStats()
    s.phase = "playing"
end

--- 重置每场酒局的回合状态
function GameLogic.ResetBanquetStats()
    local s = GameLogic.State
    s.favor = 50
    s.dignity = 50
    s.sober = 100
    s.vibe = 50
    s.pro = 0
    s.round = 0
    s.maxRounds = math.random(6, 10)
    s.eventHistory = {}
    s.usedSkillToday = false
    s.drinkCount = 0
    s.firstMistakeUsed = false
    s.currentEvent = nil
end

-- ============================================================================
-- 骰子系统
-- ============================================================================
function GameLogic.RollDice()
    local s = GameLogic.State
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
    s.round = s.round + 1

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
function GameLogic.MakeChoice(choiceIndex)
    local s = GameLogic.State
    if not s.currentEvent then return nil end

    local choice = s.currentEvent.choices[choiceIndex]
    if not choice then return nil end

    local effects = choice.effects or {}

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

    -- 检查本场酒局是否结束
    if s.round >= s.maxRounds or s.sober <= 0 then
        s.phase = "day_result"
    end

    return choice
end

-- ============================================================================
-- 单日结算
-- ============================================================================

--- 判定本场酒局结果: "promote" / "maintain" / "demote" / "optimized"
function GameLogic.GetBanquetResult()
    local s = GameLogic.State

    -- 醉倒 → 被优化
    if s.sober <= 0 then
        return "optimized"
    end

    -- 综合评分
    local score = 0
    score = score + s.favor * 0.35
    score = score + s.face * 0.2
    score = score + s.pro * 0.15
    score = score + s.vibe * 0.15
    score = score + (s.sober / 100) * 15  -- 清醒度贡献最多15分

    -- 职级越高越难升
    local difficultyPenalty = s.currentLevel * 3
    score = score - difficultyPenalty

    if score >= 55 then
        return "promote"
    elseif score >= 35 then
        return "maintain"
    elseif score >= 20 then
        return "demote"
    else
        return "optimized"
    end
end

--- 应用单日结算结果
function GameLogic.ApplyBanquetResult(result)
    local s = GameLogic.State
    local levelBefore = s.currentLevel

    if result == "promote" then
        s.currentLevel = math.min(8, s.currentLevel + 1)
        s.consecutivePromote = s.consecutivePromote + 1
        s.maxConsecutive = math.max(s.maxConsecutive, s.consecutivePromote)
    elseif result == "demote" then
        s.currentLevel = math.max(1, s.currentLevel - 1)
        s.consecutivePromote = 0
    elseif result == "optimized" then
        s.currentLevel = math.max(1, s.currentLevel - 1)
        s.optimizeCount = s.optimizeCount + 1
        s.consecutivePromote = 0
    else -- maintain
        s.consecutivePromote = 0
    end

    -- 更新资金到新职级
    local newLevelData = GameData.Levels[s.currentLevel]
    if newLevelData and result == "promote" then
        s.money = math.max(s.money, newLevelData.money)
    end

    s.banquetCount = s.banquetCount + 1

    -- 记录历史
    table.insert(s.dayHistory, {
        day = s.currentDay,
        result = result,
        levelBefore = levelBefore,
        levelAfter = s.currentLevel,
    })
end

-- ============================================================================
-- 天数推进 / 终局判定
-- ============================================================================

--- 推进到下一天或触发终局
function GameLogic.AdvanceDay()
    local s = GameLogic.State

    -- 检查胜利条件：升到Lv.8
    if s.currentLevel >= 8 then
        s.gameOverType = "win"
        s.phase = "game_over"
        return
    end

    -- 检查失败条件：被优化次数达上限
    if s.optimizeCount >= s.maxOptimize then
        s.gameOverType = "fired"
        s.phase = "game_over"
        return
    end

    -- 检查时间条件：天数用完
    if s.currentDay >= s.maxDays then
        s.gameOverType = "timeout"
        s.phase = "game_over"
        return
    end

    -- 正常推进
    s.currentDay = s.currentDay + 1
    s.phase = "day_start"
end

--- 从 day_result 进入下一天
function GameLogic.ProceedAfterResult()
    GameLogic.AdvanceDay()
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
