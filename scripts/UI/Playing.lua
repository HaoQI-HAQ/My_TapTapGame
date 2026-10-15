-- 饭局手记：角色舞台、骰桌与交谈独立排版；点数只由 GameLogic 决定。
local UI = require("urhox-libs/UI")
local GameLogic = require("Game.GameLogic")
local GameData = require("Data.GameData")
local Dice3D = require("UI.Dice3D")
local Art = require("UI.ArtTheme")
local Preferences = require("UI.Preferences")
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
        audio.roll.soundType = SOUND_EFFECT
        audio.land.soundType = SOUND_EFFECT
    end
    local source = landing and audio.land or audio.roll
    local path = landing and "audio/sfx/dice_land.mp3" or "audio/sfx/dice_roll.mp3"
    local sound = cache:GetResource("Sound", path)
    if source and sound then source:Play(sound, sound:GetFrequency(), landing and 0.75 or 0.6) end
end

local hiddenAssetsReady = false
local function EnsureHiddenAssets(onReady)
    if hiddenAssetsReady then onReady(true); return end
    local refs = GameData.CollectHiddenBossAssets()
    if #refs == 0 then hiddenAssetsReady = true; onReady(true); return end
    print("[Hidden] 饭局按需加载 " .. #refs .. " 项资源")
    cache:DownloadResources(refs, function(success)
        hiddenAssetsReady = success
        print("[Hidden] 资源就绪=" .. tostring(success))
        onReady(success)
    end)
end

function Playing.Create(navigate)
    local s = GameLogic.State --[[@as table]]
    local event = GameLogic.GetNextEvent()
    if not event then
        return Art.Root({Art.Safe({Art.Button("饭局已结束 · 查看结算", function()
            s.phase = "day_result"
            navigate("day_result")
        end)}, {justifyContent = "center", alignItems = "center"})})
    end
    local roundToken, eventToken = s.round, event.id
    local opponentName, opponentPath = Art.Opponent(s)
    local character, restaurant = s.character or {}, s.restaurant or {}
    local alive, ready, chosen, rolling, settled = true, false, false, false, false
    local thinking = false
    ---@type number
    local thinkTime = 0
    ---@type number
    local elapsed = 0
    local shownCharacters = 0
    local lineText = tostring(event.text or "")
    local lineLength = utf8.len(lineText) or #lineText
    local typing = false
    local focusDialogue = 0
    local OpenDialogue = function() end
    local RefreshActions = function() end
    local Settle = function() end

    local playerArt = Art.Picture(Art.Character(character), {id = "playing_player",
        position = "absolute", left = "5%", bottom = 0, width = "37%", height = "100%"})
    local opponentArt = Art.Picture(opponentPath, {id = "playing_opponent",
        position = "absolute", right = "5%", bottom = 0, width = "37%", height = "100%"})
    local playerTag = Art.Text(character.name or "我方", 11, C.ink,
        {backgroundColor = C.paper, padding = 6, borderRadius = 6, width = 130, flexShrink = 1})
    local opponentTag = Art.Text(opponentName, 11, C.white,
        {backgroundColor = C.purple, padding = 6, borderRadius = 6, width = 160, flexShrink = 1, textAlign = "right"})
    local stage = UI.Panel {id = "banquet_stage", width = "100%", height = 150, flexShrink = 0,
        overflow = "hidden", children = {playerArt, opponentArt,
            UI.Panel {position = "absolute", left = 8, right = 8, bottom = 6,
                flexDirection = "row", justifyContent = "space-between", children = {playerTag, opponentTag}}}}

    local playerDice = Dice3D.View {styleKey = "classic", width = 76, height = 84, pointerEvents = "none"}
    local opponentDice = Dice3D.View {styleKey = "classic", width = 76, height = 84, pointerEvents = "none"}
    playerDice:Hide()
    opponentDice:Hide()
    local ownCup = Art.Picture(Art.Pick(A.diceCup), {width = 76, height = 84, id = "player_cup"})
    local hiddenCup = Art.Picture(Art.Pick(A.diceCup), {width = 76, height = 84, id = "opponent_cup"})
    local playerResult = Art.Text("我方 · 待掷", 11, C.white, {width = 98, textAlign = "center", whiteSpace = "nowrap"})
    local opponentResult = Art.Text("对方 · 保密", 11, C.lilac, {width = 98, textAlign = "center", whiteSpace = "nowrap"})
    local bidValue = Art.Title("—", 30, C.yellow, {width = "100%", textAlign = "center", id = "current_bid"})
    local bidCaption = Art.Text("当前叫点", 10, C.lilac, {width = "100%", textAlign = "center"})
    local status = Art.Text("先摇骰，再叫双方骰子的总和。", 12, C.white,
        {width = "100%", id = "liar_status"})
    local rule = Art.Text("双方各一颗骰子 · 总和 2–12\n叫点必须递增。叫开时，叫点大于实际总和，叫开者获胜。", 10, C.lilac,
        {width = "100%"})
    local result = Art.Text("", 12, C.yellow, {width = "100%", id = "liar_result"})
    result:Hide()
    local diceRow = UI.Panel {width = "100%", flexDirection = "row", justifyContent = "space-around",
        alignItems = "center", gap = 8, children = {
            UI.Panel {alignItems = "center", gap = 3, children = {ownCup, playerDice, playerResult}},
            UI.Panel {alignItems = "center", width = 84, children = {bidCaption, bidValue}},
            UI.Panel {alignItems = "center", gap = 3, children = {hiddenCup, opponentDice, opponentResult}},
        }}
    local rollButton = Art.Button("摇骰 · 开始本轮", nil, false, {id = "roll_dice", width = "100%"})
    -- 控件列表必须连续；按点数查找另用 map，不能把 2..12 的稀疏表传给 children。
    ---@type table<number, Widget>
    local raiseButtons = {}
    ---@type Widget[]
    local raiseChildren = {}
    local function SubmitBid(value)
        if not alive or rolling or thinking or settled or chosen then return end
        local L = s.liar
        if not L or not L.active or L.turn ~= "player" then return end
        local ok, err = GameLogic.LiarRaise(value)
        if not ok then UI.Toast.Show(tostring(err), {variant = "warning"}); return end
        bidValue:SetText(tostring(value))
        status:SetText("你叫 " .. value .. " 点 · 对方正在考虑…")
        thinking, thinkTime = true, 0.65
        RefreshActions()
        print("[BanquetUI] 玩家叫总和 " .. value)
    end
    for value = 2, 12 do
        local button = Art.Button(tostring(value), function() SubmitBid(value) end, true,
            {id = "liar_raise_" .. value, width = 46, minHeight = 40, paddingHorizontal = 0,
                paddingVertical = 7, fontSize = 13, flat = true})
        raiseButtons[value] = button
        raiseChildren[#raiseChildren + 1] = button
    end
    local challenge = Art.Button("叫开 · 验证对方的叫点", function()
        if not alive or rolling or thinking or settled or chosen then return end
        local ok, err = GameLogic.LiarChallenge()
        if not ok then UI.Toast.Show(tostring(err), {variant = "warning"}); return end
        Settle()
    end, false, {id = "liar_challenge", width = "100%"})
    local actionHint = Art.Text("点击数字直接叫点", 10, C.lilac, {width = "100%", id = "liar_hint"})
    local actionPanel = UI.Panel {id = "liar_actions", width = "100%", gap = 10, children = {
        actionHint, UI.Panel {width = "100%", flexDirection = "row", flexWrap = "wrap", gap = 6,
            justifyContent = "center", children = raiseChildren}, challenge}}
    actionPanel:Hide()
    local resultContinue = Art.Button("继续本轮交谈", function()
        if not alive or not settled or opponentDice:IsRolling() then return end
        OpenDialogue()
    end, false, {id = "liar_continue", width = "100%"})
    resultContinue:Hide()
    local diceCard = Art.Paper({
        UI.Panel {width = "100%", flexDirection = "row", justifyContent = "space-between", children = {
            Art.Title("大话骰", 18, C.white, {width = "50%"}),
            Art.Text("ROUND " .. s.round .. " / " .. s.maxRounds, 10, C.yellow, {width = "50%", textAlign = "right"})}},
        diceRow, status, rule, rollButton, actionPanel, result, resultContinue,
    }, {id = "dice_stage", gap = 12, minWidth = 0, width = "100%"}, true)

    local speaker = Art.Text("本轮交谈尚未开始", 11, C.purple, {width = "100%"})
    local dialogue = Art.Text("先在骰桌争取话语权。赢下大话骰，可以打听一条明日情报。", 14, C.ink,
        {width = "100%", id = "dialogue_text"})
    local expression = Art.Picture(nil, {width = 50, height = 50, id = "opponent_expression"})
    expression:Hide()
    local feedback = Art.Text(tostring(s.lastChoiceFeedback or ""), 11, C.muted,
        {width = "100%", id = "last_choice_feedback"})
    if not s.lastChoiceFeedback or s.lastChoiceFeedback == "" then feedback:Hide() end
    local bubble = UI.Panel {id = "dialogue_bubble", width = "100%", gap = 12,
        onClick = function() if typing then dialogue:SetText(lineText); typing = false end end,
        children = {UI.Panel {width = "100%", flexDirection = "row", gap = 8, alignItems = "center",
            children = {Art.Title("酒桌交谈", 18, C.ink, {flexGrow = 1, flexShrink = 1}), expression}},
            feedback, speaker, dialogue}}
    ---@type Widget[]
    local choices = {}
    for i, choice in ipairs(event.choices or {}) do
        choices[#choices + 1] = Art.Button(string.char(64 + i) .. "  " .. choice.text, function()
            if not alive or not ready or chosen then return end
            chosen = true
            local accepted, err = GameLogic.MakeChoice(i, eventToken, roundToken)
            if not accepted then
                chosen = false
                UI.Toast.Show(tostring(err or "选择未生效，请重试。"), {variant = "warning"})
                return
            end
            print("[BanquetUI] 对话选择 " .. i .. " / Round " .. roundToken)
            navigate(s.phase)
        end, i % 2 == 0, {id = "choice_" .. i, width = "100%", textAlign = "left", minHeight = 48})
    end
    local choiceWrap = UI.Panel {id = "dialogue_choices", width = "100%", gap = 8, children = choices}
    choiceWrap:Hide()
    local intelAnswer = Art.Text("", 13, C.ink, {width = "100%", id = "intel_answer"})
    local intelTag = Art.Text("", 11, C.purple, {width = "100%", id = "intel_tag"})
    local intelContinue = Art.Button("记下了 · 继续交谈", function() OpenDialogue() end, false,
        {id = "intel_continue", width = "100%"})
    local intelResponse = UI.Panel {id = "intel_response", width = "100%", gap = 12,
        children = {intelTag, intelAnswer, intelContinue}}
    intelResponse:Hide()
    local intelQuestions = UI.Panel {id = "intel_questions", width = "100%", gap = 8}
    for _, question in ipairs(GameLogic.GetIntelQuestions()) do
        intelQuestions:AddChild(Art.Button(question.text, function()
            if not alive or not settled or ready or s.intelUsedToday then return end
            local info, err = GameLogic.AskIntel(question.id)
            if not info then UI.Toast.Show(tostring(err or "暂时无法打听情报"), {variant = "warning"}); return end
            intelQuestions:Hide()
            intelTag:SetText("明日情报 / " .. tostring(info.tag))
            intelAnswer:SetText(tostring(info.answer))
            intelResponse:Show()
            print("[BanquetUI] 明日情报 " .. question.id)
        end, true, {width = "100%", textAlign = "left", id = "intel_" .. question.id}))
    end
    intelQuestions:Hide()
    local dialogueCard = Art.Paper({bubble, intelQuestions, intelResponse, choiceWrap},
        {id = "playing_dialogue", width = "100%", minWidth = 0, gap = 16})
    local workspace = UI.Panel {id = "banquet_workspace", width = "100%", gap = 14,
        alignItems = "flex-start", children = {diceCard, dialogueCard}}
    local content = UI.Panel {width = "100%", padding = 14, gap = 12, children = {stage, workspace}}
    local scroll = UI.ScrollView {id = "banquet_scroll", width = "100%", flexGrow = 1, flexBasis = 0,
        minHeight = 0, flexShrink = 1, scrollY = true, showScrollbar = true, children = {content}}
    local location = Art.Text((restaurant.name or "今晚的饭局") .. "  ·  " ..
        ((s.drinkBrand and s.drinkBrand.name) or "酒水已备") ..
        (s.dish and ("  ·  " .. s.dish.name) or ""), 10, C.white,
        {width = "100%", backgroundColor = C.purple, paddingHorizontal = 14, paddingVertical = 6})
    local root = Art.Root({Art.Safe({Art.HUD(s, GameLogic.GetLevelData(s.currentLevel).name),
        Art.Stats(s, true), location, scroll})}, Art.Background(restaurant))

    RefreshActions = function()
        local L = s.liar
        local current = L and L.currentBid or 0
        local canAct = alive and not rolling and not thinking and not settled and L and L.active and L.turn == "player"
        for value = 2, 12 do Art.SetDisabled(raiseButtons[value], not canAct or value <= current) end
        Art.SetDisabled(challenge, not canAct or current == 0)
        actionHint:SetText(thinking and "对方正在考虑，请稍候…" or
            (current >= 12 and "已经叫到 12 点，不能再加码，请选择叫开。" or
            (current == 0 and "首叫：点击 2–12 中任意数字；尚不能叫开。" or
            "点击大于 " .. current .. " 的数字加码，或叫开。")))
    end
    OpenDialogue = function()
        if not alive or ready or not settled then return end
        ready = true
        intelQuestions:Hide()
        intelResponse:Hide()
        resultContinue:Hide()
        speaker:SetText(opponentName .. " · " .. (event.type == "final" and "最后一轮" or "正在交谈"))
        dialogue:SetText("")
        elapsed, shownCharacters, typing = 0, 0, true
        choiceWrap:Show()
        focusDialogue = 2
        print("[BanquetUI] 交谈开放 / Round " .. roundToken)
    end
    local function AfterReveal()
        if not alive then return end
        PlaySound(true)
        if s.liar.winner == "player" and not s.intelUsedToday and #GameLogic.GetIntelQuestions() > 0 then
            speaker:SetText("赢得话语权 · 打听明日安排")
            dialogue:SetText("可以问一个问题。回答会保留在这里，读完后再继续交谈。")
            intelQuestions:Show()
            focusDialogue = 2
        else
            resultContinue:Show()
        end
    end
    Settle = function()
        if not alive or settled or not s.liar or not s.liar.winner then return end
        settled, thinking = true, false
        local L = s.liar
        GameLogic.LiarFinish()
        actionPanel:Hide()
        rollButton:Hide()
        local sum = GameLogic.LiarActualSum()
        local won = L.winner == "player"
        status:SetText(won and "你赢得了本轮话语权" or "对方赢得了本轮话语权")
        result:SetText("揭晓：你 " .. L.playerDie .. " + 对方 " .. L.opponentDie .. " = " .. sum ..
            "\n叫点 " .. L.currentBid .. (L.currentBid > sum and " > " or " ≤ ") .. sum ..
            (L.currentBid > sum and "，叫开者获胜。" or "，叫开者失利。"))
        result:Show()
        hiddenCup:Hide()
        opponentDice:Show()
        opponentResult:SetText("对方 · " .. L.opponentDie .. " 点")
        opponentDice.props.onComplete = AfterReveal
        opponentDice:Roll(L.opponentDie)
        print("[BanquetUI] 揭晓总和=" .. sum .. " winner=" .. tostring(L.winner))
    end
    local function RunOpponentTurn()
        if not alive or settled then return end
        thinking = false
        local action, bid = GameLogic.LiarOpponentTurn()
        if action == "raise" then
            bidValue:SetText(tostring(bid))
            status:SetText("对方叫 " .. bid .. " 点 · 轮到你了")
            RefreshActions()
        elseif action == "challenge" then
            status:SetText("对方叫开！")
            Settle()
        end
    end
    local function BeginRoll()
        if not alive or rolling or settled then return end
        local L = GameLogic.StartLiarRound()
        rolling = true
        rule:Hide()
        RefreshActions()
        rollButton:Hide()
        ownCup:Hide()
        playerDice:Show()
        PlaySound(false)
        status:SetText("骰子落定后，由你先叫点。")
        playerResult:SetText("我方 · 摇骰中")
        playerDice.props.onComplete = function()
            if not alive then return end
            rolling = false
            PlaySound(true)
            playerResult:SetText("我方 · " .. L.playerDie .. " 点")
            if L.winner then Settle(); return end
            actionPanel:Show()
            if L.turn == "opponent" then
                thinking, thinkTime = true, 0.65
            else
                status:SetText(L.currentBid > 0 and ("对方叫 " .. L.currentBid .. " 点 · 轮到你了") or "由你首叫双方骰子的总和")
            end
            RefreshActions()
        end
        playerDice:Roll(L.playerDie)
    end
    rollButton.props.onClick = BeginRoll

    -- 只改已有控件的样式，不重抽事件、不重掷、不重复结算。
    Art.Responsive(root, function(w, h, narrow, short)
        content:SetStyle({padding = short and 10 or 14, gap = short and 8 or 12})
        stage:SetStyle({height = short and 72 or (narrow and 100 or 100)})
        local pad = short and 12 or 16
        local diceWidth = narrow and (w - (short and 20 or 28)) or (w - (short and 20 or 28)) * 0.4
        local numberWidth = math.floor((diceWidth - pad * 2 - 30) / 6)
        for value = 2, 12 do raiseButtons[value]:SetStyle({width = numberWidth, minHeight = 44}) end
        for _, die in ipairs({playerDice, opponentDice, ownCup, hiddenCup}) do
            die:SetStyle({width = 64, height = 70})
        end
        workspace:SetStyle({flexDirection = narrow and "column" or "row", gap = 14})
        diceCard:SetStyle({width = narrow and "100%" or "40%", flexShrink = 0, padding = pad, gap = 8})
        dialogueCard:SetStyle({width = narrow and "100%" or "auto", flexGrow = 1,
            flexShrink = 1, flexBasis = narrow and "auto" or 0, padding = short and 14 or 20})
        dialogue:SetFontSize(short and 12 or 14)
    end)
    local update = root.Update
    root.Update = function(self, dt)
        if update then update(self, dt) end
        if not alive then return end
        if focusDialogue > 0 then
            focusDialogue = focusDialogue - 1
            if focusDialogue == 0 then
                scroll:SetScroll(0, workspace:GetLayout().y + dialogueCard:GetLayout().y)
            end
        end
        if thinking then
            thinkTime = thinkTime - dt
            if thinkTime <= 0 then RunOpponentTurn() end
        end
        if typing then
            elapsed = elapsed + dt
            local speed = Preferences.Get("dialogueSpeed")
            local rate = speed == "slow" and 24 or (speed == "fast" and 72 or 42)
            local count = speed == "instant" and lineLength or
                math.min(lineLength, shownCharacters + math.floor(elapsed * rate))
            if count > shownCharacters then elapsed = 0 end
            if count ~= shownCharacters then
                shownCharacters = count
                local ending = utf8.offset(lineText, count + 1)
                dialogue:SetText(ending and lineText:sub(1, ending - 1) or lineText)
            end
            if count >= lineLength then typing = false end
        end
    end
    local destroy = root.Destroy
    root.Destroy = function(self)
        alive, typing, thinking = false, false, false
        playerDice.props.onComplete, opponentDice.props.onComplete = nil, nil
        destroy(self)
    end
    if s.opponent and s.opponent.isBoss then
        opponentTag:SetText(opponentName .. " · 立绘加载中")
        EnsureHiddenAssets(function(success)
            if not alive then return end
            local _, path = Art.Opponent(s)
            if path then opponentArt:SetBackgroundImage(path) end
            opponentTag:SetText(opponentName .. (success and "" or " · 立绘暂未加载"))
            local face = s.sober < 40 and A.bossExpressions.drunk or
                (s.favor >= 65 and A.bossExpressions.smile or A.bossExpressions.skeptical)
            local facePath = event.type == "final" and Art.Pick(s.opponent.finalPortrait, A.npc.pu_rui_si.final)
                or Art.Pick(face, s.opponent.portrait)
            if facePath then expression:SetBackgroundImage(facePath); expression:Show() end
        end)
    end
    -- 同一回合的界面重新挂载沿用现有结果；窗口重排本身不会走这里。
    if s.liar and s.liar.banquetToken == s.banquetId and s.liar.roundToken == roundToken
        and s.liar.eventToken == event then BeginRoll() end
    print("[BanquetUI] 饭局 Day " .. s.currentDay .. " / Round " .. s.round .. " / 11 个叫点按钮已挂载")
    return root
end

function Playing.Shutdown()
    if audio.roll then audio.roll:StopImmediate() end
    if audio.land then audio.land:StopImmediate() end
    if audio.scene then audio.scene:Dispose() end
    audio = {}
end

return Playing
