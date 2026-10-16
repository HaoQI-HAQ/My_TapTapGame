-- 日结页仅负责展示：判定、应用结算与推进仍由 Screens / GameLogic 管理。
-- 参考 v2 PC 双栏与手机竖屏图；所有数值来自当前状态和已落盘的单场记录。
local UI = require("urhox-libs/UI")
local Art = require("UI.ArtTheme")
local GameLogic = require("Game.GameLogic")
local DayResult = {}
local C, A = Art.C, Art.Assets

local notices = {promote = "升职通知！", maintain = "职级维持", demote = "岗位调整", optimized = "优化通知"}
local statNames = {favor = "好感", dignity = "尊严", sober = "清醒", vibe = "氛围", face = "面子", pro = "专业"}
local statOrder = {"favor", "dignity", "sober", "vibe", "face", "pro"}

---@param value number
local function Number(value)
    return string.format("%g", value)
end

---@param value number
local function Signed(value)
    return (value > 0 and "+" or "") .. Number(value)
end

local function BrushLabel(text, size, extra)
    local unit = Art.Unit()
    return UI.Panel(Art.Merge({backgroundImage = A.brushInk, backgroundFit = "contain",
        paddingHorizontal = 14 * unit, paddingVertical = 3 * unit, flexShrink = 0,
        width = 156 * unit, height = 156 * unit * 125 / 488,
        justifyContent = "center", overflow = "hidden",
        children = {Art.Title(text, size or 14, C.paper, {width = "100%", textAlign = "center"})}}, extra))
end

---@param state table
---@param record table
---@param result string
local function Reason(state, record, result)
    if record.budgetFailure then
        return "当前预算不足以支付完整酒局，本场按被优化结算。"
    elseif state.quitInDrunk then
        return "醉后当场辞职，本场按被优化结算。"
    elseif state.sober and state.sober <= 0 then
        return "清醒归零，饭局提前结束，本场按被优化结算。"
    end
    local reasons = {
        promote = "本场综合表现达晋升线，已按规则完成职级结算。",
        maintain = "本场判定为维持，职级未改变。",
        demote = "本场判定为降级，岗位已按规则调整。",
        optimized = "本场判定为被优化，被优化次数已计入。",
    }
    return reasons[result] or "饭局已结算，以下为本场实际记录。"
end

local function Portrait(path, name, subtitle)
    local unit = Art.Unit()
    local image = Art.Picture(path, {width = "100%", height = 214 * unit, backgroundFit = "contain"})
    local caption = Art.Title(name, 17, C.ink, {width = "100%", textAlign = "center"})
    local note = Art.Text(subtitle, 12, C.ink, {width = "100%", textAlign = "center"})
    local label = UI.Panel {width = "100%", minWidth = 0, gap = 2 * unit, children = {caption, note}}
    local card = UI.Panel {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0,
        padding = 12 * unit, gap = 7 * unit, borderWidth = 2 * unit, borderColor = C.ink, borderRadius = 3 * unit,
        backgroundColor = C.yellow, children = {image, label}}
    return {card = card, image = image, label = label, caption = caption}
end

---@param state table
local function AttributeRows(state)
    local unit = Art.Unit()
    local changes = state.lastChoiceChanges or {}
    local hasChanges = false
    for _, key in ipairs(statOrder) do
        if type(changes[key]) == "number" then hasChanges = true; break end
    end
    local rows = UI.Panel {width = "100%", gap = 0, minWidth = 0}
    for _, key in ipairs(statOrder) do
        local value = changes[key]
        if not hasChanges then value = state[key] end
        if type(value) == "number" then
            local label = key == "dignity" and state.mode == "offwork" and "骨气" or statNames[key]
            local text = hasChanges and Signed(value) or Number(value)
            local valueColor = hasChanges and value < 0 and C.orange or C.ink
            local parts = {}
            if A.icons[key] then
                parts[#parts + 1] = Art.Picture(A.icons[key], {width = 18 * unit, height = 18 * unit})
            end
            parts[#parts + 1] = Art.Text(label, 12, C.ink,
                {flexGrow = 1, flexBasis = 0, flexShrink = 1, fontWeight = "bold", lineHeight = 1.2})
            parts[#parts + 1] = Art.Title(text, 12, valueColor,
                {minWidth = 44 * unit, textAlign = "right", whiteSpace = "nowrap", lineHeight = 1.2})
            rows:AddChild(UI.Panel {width = "100%", minHeight = 24 * unit, flexDirection = "row", gap = 7 * unit,
                alignItems = "center", paddingHorizontal = 5 * unit, paddingVertical = 2 * unit,
                borderBottomWidth = 1, borderBottomColor = C.line, children = parts})
        end
    end
    return UI.Panel {width = "100%", gap = 3 * unit, children = {
        Art.Text(hasChanges and "末轮实际变化 · 非整场累计" or "当前属性", 12, C.ink,
            {width = "100%", lineHeight = 1.2}),
        rows,
    }}
end

---@param state table
---@param resultCache table
---@param onContinue fun()
function DayResult.Create(state, resultCache, onContinue)
    -- 必须只读取本场记录。不可使用上一场奖励、重新掷文案或在 resize 中应用结算。
    local unit = Art.Unit()
    local records = state.settledBanquets or {}
    local record = records[state.banquetId] or {} --[[@as table]]
    local result = resultCache.result or record.result or "maintain"
    local before = resultCache.before or state.currentLevel
    local after = resultCache.after or state.currentLevel
    local level = state.currentLevel
    local character = state.character or {}
    local intern = character.id == "intern"
    local characterPath = intern and A.internEmbarrassedPortrait or Art.Character(character, true)
    local player = Portrait(characterPath or Art.Character(character, true), character.name or "当前角色",
        intern and "尴尬" or ("Lv." .. tostring(level)))

    local opponent = state.opponent or {}
    local opponentName, opponentPath = Art.Opponent(state)
    if opponent.id == "boss" then opponentPath = Art.Character(opponent, true) end
    local satisfied = opponent.id == "leader" and result == "promote"
    if satisfied then opponentPath = A.leaderSatisfiedPortrait or opponentPath end
    -- 没入席的预算失败不虚构对手；普瑞斯和区域老板也绝不替换成领导/实习生。
    if not state.opponent then opponentName, opponentPath = "本日未入席", A.layoffBox end
    local guest = Portrait(opponentPath, opponentName, satisfied and "满意" or (state.opponent and "本场对手" or "预算结算"))

    local noticeText = Art.Title(notices[result] or "饭局结算", 46, C.ink,
        {width = "100%", textAlign = "center", lineHeight = 1.2})
    local notification = UI.Panel {width = "100%", height = 114, paddingHorizontal = 20,
        paddingVertical = 16, justifyContent = "center", backgroundImage = A.brushGold,
        backgroundFit = "contain", children = {noticeText}}
    local day = Art.Text("第 " .. tostring(state.currentDay) .. " / " .. tostring(state.maxDays) .. " 天 · 散席复盘",
        13, C.ink, {width = "100%", textAlign = "center"})
    local portraits = UI.Panel {width = "100%", flexDirection = "row", alignItems = "stretch",
        gap = 20, zIndex = 1, children = {player.card, guest.card}}
    local tableForeground = Art.Picture(A.foreground, {position = "absolute", bottom = -12,
        left = 0, width = "100%", height = 156, backgroundFit = "cover", zIndex = 0})
    local layoff = Art.Picture(A.layoffBox, {position = "absolute", bottom = 18, left = 14,
        width = 118, height = 112, zIndex = 1})
    layoff:SetVisible(result == "optimized" and state.opponent ~= nil)
    local stage = UI.Panel {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0,
        minHeight = 0, gap = 14, children = {tableForeground, layoff, notification, day, portraits}}

    local roleTitle = Art.Title("当前岗位 · " .. GameLogic.GetLevelData(level).name, 16, C.ink,
        {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, lineHeight = 1.2})
    -- 结算工牌只用无文字叠层图标，避免旧 Art.Badge 的 L 标签在大字号下变成竖条。
    local badge = Art.Picture(A.icons.badge or A.icons.rank, {width = 36 * unit, height = 36 * unit})
    local rankHeading = UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", gap = 7 * unit,
        children = {badge, roleTitle}}
    local rankStrip = BrushLabel("Lv." .. tostring(before) .. " → Lv." .. tostring(after)
        .. "  (" .. Signed(after - before) .. ")", 12,
        {width = 180 * unit, height = 180 * unit * 125 / 488, alignSelf = "center"})
    local budget = UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", gap = 8 * unit,
        paddingVertical = 3 * unit, borderBottomWidth = 1, borderBottomColor = C.line, children = {
            Art.Text("余额 ¥" .. Number(state.money), 12, C.ink,
                {flexGrow = 1, flexBasis = 0, flexShrink = 1, lineHeight = 1.2, fontWeight = "bold"}),
            Art.Text("被优化 " .. tostring(state.optimizeCount) .. "/" .. tostring(state.maxOptimize), 12,
                state.optimizeCount > 0 and C.orange or C.ink,
                {flexGrow = 1, flexBasis = 0, flexShrink = 1, textAlign = "right", lineHeight = 1.2}),
        }}
    ---@type Widget[]
    local detailChildren = {rankHeading, rankStrip, budget, AttributeRows(state)}
    local reward = record.challengerReward or {} --[[@as table]]
    -- 普通晋升没有本场加薪字段，不能拿新职级初始资金推导“+工资”。
    if record.challengerDefeated and type(reward.money) == "number" then
        detailChildren[#detailChildren + 1] = Art.StatRow("本场挑战者奖励", "¥" .. Signed(reward.money), C.ink)
    end
    local reasonHeading = BrushLabel("结算原因", 12, {alignSelf = "flex-start", width = 156 * unit})
    local feedbackHeading = BrushLabel("散席反馈", 12, {alignSelf = "flex-start", width = 156 * unit})
    detailChildren[#detailChildren + 1] = reasonHeading
    detailChildren[#detailChildren + 1] = Art.Text(Reason(state, record, result), 13, C.ink,
        {width = "100%", lineHeight = 1.55})
    if type(record.score) == "number" and type(record.promotionThreshold) == "number" then
        detailChildren[#detailChildren + 1] = Art.Text("本场综合分 " .. Number(record.score)
            .. " / 晋升线 " .. Number(record.promotionThreshold), 12, C.ink, {width = "100%"})
    end
    if type(record.promotionReason) == "string" and record.promotionReason ~= "" then
        detailChildren[#detailChildren + 1] = Art.Text(record.promotionReason, 12, C.ink,
            {width = "100%", lineHeight = 1.55})
    end
    detailChildren[#detailChildren + 1] = feedbackHeading
    detailChildren[#detailChildren + 1] = Art.Text(resultCache.message or "饭局已结束。", 14, C.ink,
        {width = "100%", fontWeight = "bold", lineHeight = 1.55})
    if state.lastChoiceFeedback and state.lastChoiceFeedback ~= "" then
        detailChildren[#detailChildren + 1] = Art.Text(state.lastChoiceFeedback, 12, C.ink,
            {width = "100%", lineHeight = 1.65})
    end
    local details = UI.Panel {width = "100%", gap = 4 * unit, paddingRight = 5 * unit, paddingBottom = 8 * unit,
        minWidth = 0, children = detailChildren}
    local scroll = UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, flexShrink = 1,
        minHeight = 0, scrollY = true, showScrollbar = true, children = {details}}
    local continueText = state.currentDay >= state.maxDays and "查看旅程结果" or "继续下一天"
    local continueButton = Art.Button(continueText, onContinue, false,
        {id = "continue_day_result", width = "100%", minHeight = math.max(48 * unit, Art.TouchSize(48)), fontSize = 14,
            paddingVertical = 8 * unit})
    local settlement = Art.Paper({scroll, continueButton},
        {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, minHeight = 0,
            padding = 24, gap = 10, borderRadius = 0, boxShadow = {},
            backgroundSlice = {14, 25, 14, 25}, id = "day_result_card"})
    local composition = UI.Panel {width = "100%", height = "100%", maxWidth = 1480, alignSelf = "center",
        minHeight = 0, padding = 28, gap = 30, flexDirection = "row", children = {stage, settlement}}
    local root = Art.Root({Art.Safe({composition})})
    print("[DayResultUI] display banquet=" .. tostring(state.banquetId) .. " result=" .. result
        .. " Lv." .. tostring(before) .. "->" .. tostring(after))

    return Art.Responsive(root, function(w, h)
        local portrait = h > w
        local unitNow = Art.Unit()
        local compact = h / unitNow < 560
        local padding = (portrait and 14 or (compact and 16 or 28)) * unitNow
        local columnGap = (portrait and 12 or (compact and 18 or 30)) * unitNow
        composition:SetStyle({flexDirection = portrait and "column" or "row", padding = padding,
            maxWidth = 1480 * unitNow, gap = columnGap})
        -- 通知与并列头像至多占28%，优先给余额、属性和长反馈留出结算卡空间。
        local stageHeight = h * 0.28
        stage:SetStyle({width = portrait and "100%" or "auto", height = portrait and stageHeight or "auto",
            flexGrow = portrait and 0 or 1, flexBasis = portrait and "auto" or 0,
            flexShrink = portrait and 0 or 1, gap = 4 * unitNow})
        settlement:SetStyle({width = portrait and "100%" or "auto", padding = (portrait and 22 or (compact and 22 or 24)) * unitNow,
            gap = 5 * unitNow})
        local stageWidth = portrait and w - padding * 2
            or (math.min(w, 1480 * unitNow) - padding * 2 - columnGap) / 2
        local noticeWidth = math.min(stageWidth, (portrait and 66 or 90) * unitNow * 488 / 128)
        local notificationHeight = noticeWidth * 128 / 488
        notification:SetStyle({width = noticeWidth, height = notificationHeight, alignSelf = "center",
            paddingVertical = 3 * unitNow, paddingHorizontal = 8 * unitNow, overflow = "hidden"})
        local headlineSize = math.max(18, math.min(portrait and 24 or 32, noticeWidth / unitNow / 8))
        noticeText:SetFontSize(Art.FontSize(headlineSize))
        day:SetFontSize(Art.FontSize(12))
        portraits:SetStyle({gap = (portrait and 8 or (compact and 12 or 20)) * unitNow,
            marginTop = (portrait and 0 or (compact and 6 or 22)) * unitNow})
        local imageHeight = portrait and math.max(46 * unitNow, stageHeight - notificationHeight - 44 * unitNow)
            or math.max(86, math.min(280, h * 0.36))
        for _, person in ipairs({player, guest}) do
            person.card:SetStyle({flexDirection = portrait and "row" or "column", alignItems = "center",
                padding = (portrait and 7 or (compact and 8 or 12)) * unitNow,
                gap = (portrait and 4 or 7) * unitNow, borderWidth = 2 * unitNow})
            person.image:SetStyle({width = portrait and "52%" or "100%", height = imageHeight})
            person.label:SetStyle({width = portrait and "auto" or "100%", flexGrow = portrait and 1 or 0,
                flexBasis = portrait and 0 or "auto", flexShrink = 1, gap = 2 * unitNow})
            person.caption:SetFontSize(Art.FontSize(portrait and 14 or (compact and 14 or 17)))
        end
        tableForeground:SetVisible(not portrait)
        tableForeground:SetStyle({height = compact and 96 * unitNow or math.max(140 * unitNow, h * 0.22),
            bottom = -12 * unitNow})
        layoff:SetVisible(not portrait and result == "optimized" and state.opponent ~= nil)
        layoff:SetStyle({width = 118 * unitNow, height = 112 * unitNow, bottom = 18 * unitNow, left = 14 * unitNow})
        local cardWidth = portrait and (w - padding * 2) or (math.min(w, 1480 * unitNow) - padding * 2 - columnGap) / 2
        local rankWidth = math.min(cardWidth - 54 * unitNow, 180 * unitNow)
        rankStrip:SetStyle({width = rankWidth, height = rankWidth * 125 / 488})
        reasonHeading:SetStyle({width = 156 * unitNow, height = 156 * unitNow * 125 / 488})
        feedbackHeading:SetStyle({width = 156 * unitNow, height = 156 * unitNow * 125 / 488})
        rankHeading:SetStyle({gap = 7 * unitNow})
        badge:SetStyle({width = 36 * unitNow, height = 36 * unitNow})
        details:SetStyle({gap = 4 * unitNow, paddingRight = 5 * unitNow, paddingBottom = 8 * unitNow})
        roleTitle:SetFontSize(Art.FontSize(16))
        continueButton:SetStyle({minHeight = math.max(48 * unitNow, Art.TouchSize(48)), paddingVertical = 8 * unitNow})
    end)
end

return DayResult
