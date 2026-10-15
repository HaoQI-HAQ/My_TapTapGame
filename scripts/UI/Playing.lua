-- 饭局视觉小说舞台。骰子结果由 GameLogic 决定，Dice3D 只播放动画。
local UI = require("urhox-libs/UI")
local GameLogic = require("Game.GameLogic")
local Dice3D = require("UI.Dice3D")
local Art = require("UI.ArtTheme")
local Playing = {}
local C, A = Art.C, Art.Assets

---@class BanquetDiceAudio
---@field scene Scene?
---@field roll SoundSource?
---@field land SoundSource?
---@type BanquetDiceAudio
local audio = {}
local function PlaySound(landing)
    if not audio.scene then
        audio.scene = Scene()
        local node = audio.scene:CreateChild("BanquetDiceAudio")
        audio.roll = node:CreateComponent("SoundSource")
        audio.land = node:CreateComponent("SoundSource")
    end
    local source = landing and audio.land or audio.roll
    local path = landing and "audio/sfx/dice_land.mp3" or "audio/sfx/dice_roll.mp3"
    local sound = cache:GetResource("Sound", path)
    if source and sound then source:Play(sound, sound:GetFrequency(), landing and 0.75 or 0.6) end
end

-- ============================================================================
-- 普老板资源按需加载
-- 隐藏角色默认不在预下载组（resources.json 的 hidden 组），未解锁时零内存占用。
-- 仅在确实遭遇普老板时（hiddenBossTriggered）才拉取她的立绘与表情。
-- ============================================================================
local hiddenBossReady = false
local function EnsureHiddenBossAssets(onReady)
    if hiddenBossReady then
        if onReady then onReady() end
        return
    end
    local paths = {}
    local npc = A.npc.pu_rui_si or {}
    paths[#paths + 1] = npc.normal
    paths[#paths + 1] = npc.final
    paths[#paths + 1] = npc.legacy
    for _, p in pairs(A.bossExpressions or {}) do paths[#paths + 1] = p end
    -- 过滤空值，去重
    local seen, refs = {}, {}
    for _, p in ipairs(paths) do
        if p and not seen[p] then
            seen[p] = true
            refs[#refs + 1] = p
        end
    end
    if #refs == 0 then
        hiddenBossReady = true
        if onReady then onReady() end
        return
    end
    print(string.format("[Hidden] 按需加载普老板资源 %d 项", #refs))
    cache:DownloadResources(refs, function(success)
        hiddenBossReady = success
        print(string.format("[Hidden] 普老板资源就绪=%s", tostring(success)))
        if onReady then onReady() end
    end)
end

function Playing.Create(navigate)
    local s = GameLogic.State --[[@as table]]
    local playerRoll, opponentRoll = GameLogic.RollDice()
    local event = GameLogic.GetNextEvent()
    if not event then
        -- 避免构建函数内递归切屏后被 main 的外层 SetRoot 覆盖。
        local empty = Art.Root({Art.Safe({Art.Button("饭局已结束 · 查看结算", function()
            s.phase = "day_result"
            navigate("day_result")
        end)}, {justifyContent = "center", alignItems = "center"})})
        return empty
    end
    local roundToken, eventToken = s.round, event.id
    -- 隐藏 Boss 惰性加载：仅真正遭遇普老板时才拉取她的立绘资源。
    if s.opponent and s.opponent.isBoss then
        EnsureHiddenBossAssets()
    end
    local opponentName, opponentPath = Art.Opponent(s)
    local character = s.character or {}
    local restaurant = s.restaurant or {}
    local levelName = GameLogic.GetLevelData(s.currentLevel).name
    local alive, rolling, ready, chosen = true, false, false, false
    local completed = 0
    ---@type number
    local elapsed = 0
    local shownCharacters = 0
    local lineText = tostring(event.text or "")
    local lineLength = utf8.len(lineText) or #lineText
    local typing = false

    local playerArt = Art.Picture(Art.Character(character), {
        id = "playing_player", position = "absolute", left = 0, bottom = 0,
        width = "34%", height = "100%", backgroundFit = "contain"})
    local opponentArt = Art.Picture(opponentPath, {
        id = "playing_opponent", position = "absolute", right = 0, bottom = 0,
        width = "34%", height = "100%", backgroundFit = "contain"})
    local playerDice = Dice3D.View {styleKey = "classic", width = 105, height = 112, pointerEvents = "none"}
    local opponentDice = Dice3D.View {styleKey = "classic", width = 105, height = 112, pointerEvents = "none"}
    local resultLabel = Art.Text("话语权，由这一掷开始。", 12, C.paper,
        {width = "100%", textAlign = "center"})
    local playerResult = Art.Text("我方  ?", 11, C.yellow, {textAlign = "center"})
    local opponentResult = Art.Text("对方  ?", 11, C.paper, {textAlign = "center"})
    local rollButton = Art.Button("摇骰子", nil, false, {width = "100%", id = "roll_dice"})
    local rollLabel = rollButton:GetChildAt(1) --[[@as Label]]
    local diceRow = UI.Panel {flexDirection = "row", justifyContent = "center", alignItems = "center", children = {
        UI.Panel {alignItems = "center", children = {playerDice, playerResult}},
        Art.Text("VS", 13, C.yellow, {marginHorizontal = 2}),
        UI.Panel {alignItems = "center", children = {opponentDice, opponentResult}},
    }}
    local center = Art.Paper({
        Art.Text("ROUND " .. s.round .. " / " .. s.maxRounds, 11, C.yellow, {textAlign = "center"}),
        diceRow, resultLabel, rollButton,
    }, {id = "dice_stage", width = 260, padding = 10, gap = 5, alignSelf = "center"}, true)
    local playerTag = Art.Text(character.name or "我方", 12, C.ink, {
        position = "absolute", bottom = 5, left = 8, backgroundColor = C.yellow,
        paddingHorizontal = 8, paddingVertical = 3, width = 130, maxWidth = "40%", borderWidth = 1, borderColor = C.ink})
    local opponentTag = Art.Text(opponentName, 12, C.paper, {
        position = "absolute", bottom = 5, right = 8, backgroundColor = C.purple,
        paddingHorizontal = 8, paddingVertical = 3, width = 180, maxWidth = "46%", borderWidth = 1, borderColor = C.ink})
    local stage = UI.Panel {id = "banquet_stage", width = "100%", flexGrow = 1, flexBasis = 0,
        minHeight = 205, justifyContent = "center", overflow = "hidden",
        children = {playerArt, opponentArt, center, playerTag, opponentTag}}

    local speaker = Art.Text("饭局旁白", 12, C.paper, {backgroundColor = C.purple,
        alignSelf = "flex-start", width = "75%", maxWidth = 300, flexShrink = 1, paddingHorizontal = 10, paddingVertical = 4})
    local dialogue = Art.Text("先摇骰，看看谁掌握这一回合的话语权。", 16, C.ink, {width = "100%", id = "dialogue_text"})
    local feedback = tostring(s.lastChoiceFeedback or "")
    local dialogueChildren = {}
    if feedback ~= "" then
        dialogueChildren[#dialogueChildren + 1] = Art.Text("上一回合 / " .. feedback, 12, C.purple,
            {width = "100%", paddingBottom = 6, id = "last_choice_feedback"})
    end
    ---@type Widget[]
    local speakerChildren = {speaker}
    if s.opponent and s.opponent.isBoss then
        local expression = s.sober < 40 and A.bossExpressions.drunk
            or (s.favor >= 65 and A.bossExpressions.smile or A.bossExpressions.skeptical)
        local facePath = event.type == "final" and Art.Pick(s.opponent.finalPortrait, A.npc.pu_rui_si.final)
            or Art.Pick(expression, s.opponent.portrait)
        speakerChildren[#speakerChildren + 1] = Art.Picture(facePath,
            {width = 48, height = 48, id = "opponent_expression"})
    end
    dialogueChildren[#dialogueChildren + 1] = UI.Panel {width = "100%", flexDirection = "row",
        justifyContent = "space-between", alignItems = "center", gap = 10, children = speakerChildren}
    dialogueChildren[#dialogueChildren + 1] = dialogue
    local bubble = Art.Paper(dialogueChildren, {
        width = "100%", backgroundImage = Art.Pick(A.bubble), backgroundFit = "sliced",
        backgroundSlice = {42, 28, 28, 28},
        paddingTop = 24, paddingBottom = 20, paddingHorizontal = 28, gap = 8, id = "dialogue_bubble",
        onClick = function()
            if typing then dialogue:SetText(lineText); typing = false end
        end,
    })
    local choices = {}
    for i, choice in ipairs(event.choices or {}) do
        choices[#choices + 1] = Art.Button(string.char(64 + i) .. "  " .. choice.text, function()
            if not alive or not ready or chosen then return end
            chosen = true
            print("[ArtUI] 回合 " .. s.round .. " 选择 " .. i)
            local accepted, err = GameLogic.MakeChoice(i, eventToken, roundToken)
            if not accepted then
                chosen = false
                UI.Toast.Show(tostring(err or "本次选择未生效，请重新选择。"), {variant = "warning", duration = 3})
                return
            end
            navigate(s.phase)
        end, i % 2 == 0, {id = "choice_" .. i, minHeight = 48, paddingVertical = 10,
            paddingHorizontal = 12, alignItems = "stretch"})
    end
    local choiceGrid = UI.Panel {width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 8, children = choices}
    local choiceWrap = UI.Panel {width = "100%", children = {choiceGrid}}
    choiceWrap:Hide()
    local content = UI.Panel {width = "100%", gap = 10, padding = 12, children = {bubble, choiceWrap}}
    local scroll = UI.ScrollView {id = "dialogue_scroll", width = "100%", flexGrow = 1,
        flexBasis = 0, flexShrink = 1, scrollY = true, showScrollbar = true, children = {content}}
    local location = Art.Text((restaurant.name or "今晚的饭局") .. "  /  " ..
        ((s.drinkBrand and s.drinkBrand.name) or "酒水已备") ..
        ((s.dish and ("  /  " .. s.dish.name)) or ""), 11, C.paper,
        {paddingHorizontal = 12, paddingVertical = 5, width = "100%", backgroundColor = C.purple})
    local bottom = UI.Panel {id = "playing_dialogue", width = "100%", flexGrow = 1,
        flexBasis = 0, minHeight = 175, backgroundColor = C.paper,
        borderTopWidth = 3, borderTopColor = C.ink, children = {scroll}}
    local root = Art.Root({Art.Safe({Art.HUD(s, levelName), Art.Stats(s, true), location, stage, bottom})}, Art.Background(restaurant))

    local function FinishRoll()
        if not alive or ready then return end
        ready = true
        local result = GameLogic.GetDiceResult()
        if result == "tie" then
            resultLabel:SetText("平局 · 干杯事件触发")
            resultLabel:SetFontColor(C.yellow)
        elseif result == "advantage" then
            resultLabel:SetText("本回合你占优势")
            resultLabel:SetFontColor(C.yellow)
        else
            resultLabel:SetText("对方占优势 · 小心应对")
            resultLabel:SetFontColor(C.lilac)
        end
        playerResult:SetText("我方  " .. playerRoll)
        opponentResult:SetText("对方  " .. opponentRoll)
        rollButton:Hide()
        speaker:SetText(opponentName .. " · " .. (event.type == "final" and "最后一轮" or "正在交谈"))
        dialogue:SetText("")
        elapsed, shownCharacters, typing = 0, 0, true
        choiceWrap:Show()
        bubble:Animate({keyframes = {[0] = {opacity = 0.3, translateY = 6}, [1] = {opacity = 1, translateY = 0}},
            duration = 0.22, easing = "easeOut"})
        scroll:ScrollToTop()
        print("[ArtUI] 双骰落定，对话选项已开放")
    end
    local function DiceComplete()
        if not alive then return end
        completed = completed + 1
        if completed == 2 then FinishRoll() end
    end
    playerDice.props.onLand = function() if alive then PlaySound(true) end end
    opponentDice.props.onLand = function() if alive then PlaySound(true) end end
    playerDice.props.onComplete = DiceComplete
    opponentDice.props.onComplete = DiceComplete
    rollButton.props.onClick = function()
        if not alive or rolling then return end
        rolling = true
        rollButton.props.disabled = true
        rollLabel:SetText("翻滚中…")
        resultLabel:SetText("骰子翻滚中…")
        PlaySound(false)
        playerDice:Roll(playerRoll)
        opponentDice:Roll(opponentRoll)
    end

    -- 重排网格只移动已有选项，不重建骰子、不重新抽事件。
    Art.Responsive(root, function(w, h, narrow, short)
        local diceSize = short and 46 or (narrow and 78 or 105)
        playerDice:SetStyle({width = diceSize, height = diceSize + 8})
        opponentDice:SetStyle({width = diceSize, height = diceSize + 8})
        center:SetStyle({width = short and 220 or (narrow and 230 or 280), padding = short and 6 or 10, gap = short and 2 or 5})
        local compactHeight = h <= 760
        stage:SetStyle({minHeight = short and 160 or 180, flexGrow = compactHeight and 0.8 or 1.1})
        bottom:SetStyle({flexGrow = compactHeight and 1.5 or 1,
            minHeight = short and math.max(90, math.min(160, h * 0.38)) or 300})
        local columns = narrow and 1 or 2
        -- 固定像素 basis 保留现有选项实例。
        local available = math.max(160, w - 28)
        for _, button in ipairs(choices) do
            button:SetStyle({flexBasis = math.floor((available - (columns - 1) * 8) / columns) - 2,
                flexGrow = 1, minWidth = 0})
        end
        choiceGrid:SetStyle({columnGap = 8, rowGap = 8})
        playerArt:SetStyle({width = narrow and "35%" or "36%"})
        opponentArt:SetStyle({width = narrow and "35%" or "36%"})
        dialogue:SetFontSize(short and 14 or 16)
    end)
    local responsiveUpdate = root.Update
    root.Update = function(self, dt)
        if responsiveUpdate then responsiveUpdate(self, dt) end
        if not alive or not typing then return end
        elapsed = elapsed + dt
        local count = math.min(lineLength, math.floor(elapsed * 42))
        if count ~= shownCharacters then
            shownCharacters = count
            local ending = utf8.offset(lineText, count + 1)
            dialogue:SetText(ending and lineText:sub(1, ending - 1) or lineText)
        end
        if count >= lineLength then typing = false end
    end
    local destroy = root.Destroy
    root.Destroy = function(self)
        alive, typing = false, false
        playerDice.props.onComplete, opponentDice.props.onComplete = nil, nil
        playerDice.props.onLand, opponentDice.props.onLand = nil, nil
        destroy(self)
    end
    print("[ArtUI] 饭局舞台 Day " .. s.currentDay .. " / Round " .. s.round)
    return root
end

function Playing.Shutdown()
    if audio.roll then audio.roll:StopImmediate() end
    if audio.land then audio.land:StopImmediate() end
    if audio.scene then audio.scene:Dispose() end
    audio = {}
end

return Playing
