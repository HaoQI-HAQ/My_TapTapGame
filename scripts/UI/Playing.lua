-- 饭局手记：角色舞台、骰桌与交谈独立排版；点数只由 GameLogic 决定。
-- 骰桌玩法为「猜骰·比大小」：对方先押并给预告，玩家选「我更大/我更小/一样大」，叫开亮骰分胜负。
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
---@field reroll SoundSource?
---@field win SoundSource?
---@field lose SoundSource?
---@type BanquetDiceAudio
local audio = {}

local SFX = {
    roll = "audio/sfx/dice_roll.mp3",
    land = "audio/sfx/dice_land.mp3",
    reroll = "audio/sfx/dice_reroll.mp3",
    win = "audio/sfx/guess_win.mp3",
    lose = "audio/sfx/guess_lose.mp3",
}

---@param key string
---@param volume number
local function PlaySfx(key, volume)
    if not audio.scene then
        audio.scene = Scene()
        local node = audio.scene:CreateChild("BanquetDiceAudio")
        audio.roll = node:CreateComponent("SoundSource")
        audio.land = node:CreateComponent("SoundSource")
        audio.reroll = node:CreateComponent("SoundSource")
        audio.win = node:CreateComponent("SoundSource")
        audio.lose = node:CreateComponent("SoundSource")
        for _, source in ipairs({audio.roll, audio.land, audio.reroll, audio.win, audio.lose}) do
            source.soundType = SOUND_EFFECT
        end
    end
    local source = audio[key]
    local path = SFX[key]
    if not source or not path then return end
    local sound = cache:GetResource("Sound", path)
    if sound then source:Play(sound, sound:GetFrequency(), volume) end
end

local function PlaySound(landing)
    PlaySfx(landing and "land" or "roll", landing and 0.75 or 0.6)
end

--- 胜负提示音：短促有力，一局只响一次。
---@param won boolean
local function PlayGuessOutcome(won)
    PlaySfx(won and "win" or "lose", 0.8)
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
    ---@type number
    local rerollDelay = 0
    local pendingDrunkSettle = false
    ---@type number
    local elapsed = 0
    local shownCharacters = 0
    local lineText = tostring(event.text or "")
    local lineLength = utf8.len(lineText) or #lineText
    local typing = false
    local focusDialogue = 0
    local OpenDialogue = function() end
    local RefreshActions = function() end
    local ShowRoll = function() end
    local Settle = function() end
    local RefreshLayout = function() end
    ---@type number
    local layoutW = 0
    ---@type number
    local layoutH = 0

    local playerArt = Art.Picture(Art.Character(character), {id = "playing_player",
        position = "absolute", left = "2%", bottom = 0, width = "44%", height = "100%"})
    local opponentArt = Art.Picture(opponentPath, {id = "playing_opponent",
        position = "absolute", right = "2%", bottom = 0, width = "44%", height = "100%"})
    local foreground = Art.Picture(Art.Pick(A.foreground), {id = "playing_foreground",
        position = "absolute", left = 0, bottom = 0, width = "100%", height = 160})
    local playerTag = Art.Text(character.name or "我方", 10, C.white,
        {backgroundColor = C.dark, padding = 6, borderRadius = 4, width = 156, flexShrink = 1})
    local opponentTag = Art.Text(opponentName, 10, C.white,
        {backgroundColor = C.dark, padding = 6, borderRadius = 4, width = 180, flexShrink = 1, textAlign = "right"})
    local stage = UI.Panel {id = "banquet_stage", width = "100%", height = 240, flexShrink = 0,
        overflow = "hidden", pointerEvents = "box-none", children = {playerArt, opponentArt, foreground,
            UI.Panel {position = "absolute", left = 10, right = 10, top = 8,
                flexDirection = "row", justifyContent = "space-between", pointerEvents = "none",
                children = {playerTag, opponentTag}}}}

    local playerDice = Dice3D.View {styleKey = "classic", width = 76, height = 84, pointerEvents = "none"}
    local opponentDice = Dice3D.View {styleKey = "classic", width = 76, height = 84, pointerEvents = "none"}
    playerDice:Hide()
    opponentDice:Hide()
    local ownCup = Art.Picture(Art.Pick(A.diceCup), {width = 76, height = 84, id = "player_cup"})
    local hiddenCup = Art.Picture(Art.Pick(A.diceCup), {width = 76, height = 84, id = "opponent_cup"})
    local playerResult = Art.Text("我方 · 待掷", 10, C.white, {width = "100%", textAlign = "center"})
    local opponentResult = Art.Text("对方 · 保密", 10, C.white, {width = "100%", textAlign = "center"})
    -- 中央：对方押了什么（用「他更大」这类同一参照系文案，避免和玩家的选择混淆）
    local tellIcon = Art.Title("—", 16, C.ink, {width = "100%", textAlign = "center", id = "guess_tell"})
    local tellCaption = Art.Text("他押的是", 10, C.ink, {width = "100%", textAlign = "center"})
    -- 顶部规则说明：第一眼就知道在赌什么
    local legend = Art.Text(GameData.GuessDice.legend, 12, C.white,
        {width = "100%", id = "guess_legend", lineHeight = 1.45})
    local status = Art.Text("先摇骰，再选你和他谁的点数大。", 12, C.white,
        {width = "100%", id = "guess_status"})
    local result = Art.Text("", 12, C.yellow, {width = "100%", id = "guess_result"})
    result:Hide()
    local tellPanel = UI.Panel {id = "guess_tell_panel", width = 130, height = 44,
        padding = 0, justifyContent = "center", backgroundImage = Art.Pick(A.brushGold),
        backgroundFit = "contain", children = {tellCaption, tellIcon}, pointerEvents = "none"}
    -- 复用原来的两颗真实骰子及回调：只是把骰桌挪到人物舞台前，不产生新点数。
    local diceRow = UI.Panel {id = "playing_dice_table", position = "absolute", bottom = 6,
        width = 360, left = 0, flexDirection = "row", justifyContent = "space-between",
        alignItems = "flex-end", gap = 8, pointerEvents = "none", children = {
            UI.Panel {width = "29%", alignItems = "center", gap = 2,
                children = {ownCup, playerDice, playerResult}},
            tellPanel,
            UI.Panel {width = "29%", alignItems = "center", gap = 2,
                children = {hiddenCup, opponentDice, opponentResult}},
        }}
    stage:AddChild(diceRow)
    local rollButton = Art.Button("摇骰 · 开始本轮", nil, false,
        {id = "roll_dice", width = "100%", minHeight = math.max(48 * Art.Unit(), Art.TouchSize()), fontSize = 12})
    -- 三个选择按钮：我更大 / 我更小 / 一样大
    ---@type table<string, Widget>
    local guessButtons = {}
    ---@type Widget[]
    local guessChildren = {}
    for _, choice in ipairs(GameData.GuessDice.choices) do
        local button = Art.Button(choice.label, function(button)
            if not alive or rolling or settled or chosen then return end
            local G = s.guess
            if not G or not G.active or G.winner then return end
            local ok, err = GameLogic.GuessPick(choice.id)
            if not ok then UI.Toast.Show(tostring(err), {variant = "warning"}); return end
            -- 仅选中纹理反馈，不禁用、不延迟、不改变原来的叫开/重摇时序。
            for _, other in pairs(guessButtons) do Art.SetSelected(other, other == button) end
            print("[BanquetUI] 玩家选 " .. choice.id)
            if G.winner then
                Settle()
            else
                -- 平手 → 亮出双方骰子让玩家看清，停留后再重摇。
                local info = G.rerollInfo or {}
                local mine = info.playerDie or G.playerDie
                local theirs = info.opponentDie or G.opponentDie
                local mineChoice = GameData.GuessChoiceLabel(info.playerChoice or choice.id)
                local hisChoice = GameData.GuessTellLabel(info.opponentChoice or G.opponentChoice)
                local why = info.reason == "both_hit" and "两人都押中了" or "两人都没押中"
                status:SetText(why .. " —— 平手，即将重摇…")
                result:SetText("刚才：你 " .. mine .. " 点（" .. mineChoice ..
                    "） · 他 " .. theirs .. " 点（" .. hisChoice .. "）" ..
                    "\n" .. why .. "，本局平手作废。")
                result:Show()
                -- 平手也要亮骰：对手的骰盅打开、点数亮出，让玩家有反应时间。
                tellIcon:SetText(GameData.GuessTellLabel(info.opponentChoice or G.opponentChoice))
                hiddenCup:Hide()
                opponentDice:Show()
                opponentResult:SetText("对方 · " .. theirs .. " 点")
                opponentDice:Roll(theirs)
                PlaySfx("reroll", 0.75)
                -- 展示 2 秒再重摇，避免结果一闪而过。
                rerollDelay = 2.0
                RefreshActions()
            end
        end, true,
            {id = "guess_" .. choice.id, option = true, flexGrow = 1, flexBasis = 0, flexShrink = 1,
                minWidth = 0, minHeight = math.max(48 * Art.Unit(), Art.TouchSize()), paddingHorizontal = 8, paddingVertical = 10, fontSize = 12})
        guessButtons[choice.id] = button
        guessChildren[#guessChildren + 1] = button
    end
    local actionHint = Art.Text("选一个：你觉得谁的点数更大？", 12, C.white, {width = "100%", id = "guess_hint"})
    local guessRow = UI.Panel {width = "100%", flexDirection = "row", gap = 8,
        justifyContent = "center", children = guessChildren}
    local actionPanel = UI.Panel {id = "guess_actions", width = "100%", gap = 10,
        children = {actionHint, guessRow}}
    actionPanel:Hide()
    local resultContinue = Art.Button("继续本轮交谈", function()
        if not alive or not settled or opponentDice:IsRolling() then return end
        OpenDialogue()
    end, false, {id = "guess_continue", width = "100%", minHeight = math.max(48 * Art.Unit(), Art.TouchSize()), fontSize = 12})
    resultContinue:Hide()
    local diceHeading = Art.Title("猜骰 · 比大小", 16, C.yellow, {width = "62%"})
    local roundLabel = Art.Text("ROUND " .. s.round .. " / " .. s.maxRounds, 10, C.white,
        {width = "38%", textAlign = "right"})
    local diceCard = Art.Paper({
        UI.Panel {width = "100%", flexDirection = "row", justifyContent = "space-between",
            children = {diceHeading, roundLabel}},
        legend, status, rollButton, actionPanel, result, resultContinue,
    }, {id = "dice_stage", gap = 10, minWidth = 0, width = "100%", flexShrink = 0}, true)
    -- 交谈时保留原揭晓原文；只复制已经显示的结果，不重新读取隐藏点数/押注。
    local rollSummary = Art.Text("", 12, C.yellow,
        {id = "playing_roll_summary", width = "100%", lineHeight = 1.4})
    rollSummary:Hide()

    local speaker = Art.Text("本轮交谈尚未开始", 12, C.yellow, {width = "100%"})
    local dialogue = Art.Text("先在骰桌争取话语权。赢下这一手猜骰，可以打听一条明日情报。", 12, C.white,
        {width = "100%", id = "dialogue_text", lineHeight = 1.5, minHeight = math.max(48 * Art.Unit(), Art.TouchSize())})
    local expression = Art.Picture(nil, {width = 44, height = 44, id = "opponent_expression"})
    expression:Hide()
    local feedback = Art.Text(tostring(s.lastChoiceFeedback or ""), 12, C.paper,
        {width = "100%", id = "last_choice_feedback", lineHeight = 1.4})
    if not s.lastChoiceFeedback or s.lastChoiceFeedback == "" then feedback:Hide() end
    local bubble = UI.Panel {id = "dialogue_bubble", width = "100%", gap = 6,
        onClick = function() if typing then dialogue:SetText(lineText); typing = false end end,
        children = {feedback,
            UI.Panel {width = "100%", flexDirection = "row", gap = 6, alignItems = "center",
                children = {speaker, expression}},
            dialogue}}
    speaker:SetStyle({width = "auto", flexGrow = 1, flexShrink = 1, flexBasis = 0})
    ---@type Widget[]
    local choices = {}
    for i, choice in ipairs(event.choices or {}) do
        choices[#choices + 1] = Art.Button(string.char(64 + i) .. "  " .. choice.text, function(button)
            if not alive or not ready or chosen then return end
            chosen = true
            local accepted, err = GameLogic.MakeChoice(i, eventToken, roundToken)
            if not accepted then
                chosen = false
                UI.Toast.Show(tostring(err or "选择未生效，请重试。"), {variant = "warning"})
                return
            end
            Art.SetSelected(button, true)
            print("[BanquetUI] 对话选择 " .. i .. " / Round " .. roundToken)
            navigate(s.phase)
        end, true, {id = "choice_" .. i, option = true, width = "100%", textAlign = "left",
            minHeight = math.max(48 * Art.Unit(), Art.TouchSize()), fontSize = 12, flexShrink = 0})
    end
    -- 通宽答案区独立于对白底板；横屏两列、竖屏单列，长句由滚动区兜底。
    local choiceWrap = UI.Panel {id = "dialogue_choices", width = "100%", gap = 8,
        flexDirection = "row", flexWrap = "wrap", alignItems = "stretch", children = choices}
    choiceWrap:Hide()
    local intelAnswer = Art.Text("", 12, C.white, {width = "100%", id = "intel_answer"})
    local intelTag = Art.Text("", 12, C.purple, {width = "100%", id = "intel_tag"})
    local intelContinue = Art.Button("记下了 · 继续交谈", function() OpenDialogue() end, false,
        {id = "intel_continue", width = "100%", minHeight = math.max(48 * Art.Unit(), Art.TouchSize()), fontSize = 12})
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
            if info.useless then
                -- 问了闲聊问题：明确告诉玩家这次机会浪费了，避免误以为拿到了情报。
                intelTag:SetText("无关信息 / 这次白问了")
                intelTag:SetStyle({fontColor = C.red})
                intelAnswer:SetText(tostring(info.answer) .. "\n（这个问题问不出什么，明日无从参考。）")
                PlaySfx("lose", 0.5)
            else
                intelTag:SetText("明日情报 / " .. tostring(info.tag))
                intelTag:SetStyle({fontColor = C.purple})
                intelAnswer:SetText(tostring(info.answer))
            end
            intelResponse:Show()
            print("[BanquetUI] 情报提问 " .. question.id .. (info.useless and "（闲聊）" or ""))
        end, true, {width = "100%", textAlign = "left", id = "intel_" .. question.id,
            option = true, minHeight = math.max(48 * Art.Unit(), Art.TouchSize()), fontSize = 12}))
    end
    intelQuestions:Hide()
    local dialogueCard = Art.Paper({bubble, intelQuestions, intelResponse},
        {id = "playing_dialogue", width = "100%", minWidth = 0, gap = 12, flexShrink = 0}, true)
    dialogueCard:Hide()
    local workspace = UI.Panel {id = "banquet_workspace", width = "100%", gap = 10,
        flexDirection = "column", alignItems = "stretch", flexShrink = 0,
        children = {diceCard, dialogueCard, choiceWrap, rollSummary}}
    local content = UI.Panel {width = "100%", padding = 12, gap = 10, children = {workspace}}
    local scroll = UI.ScrollView {id = "banquet_scroll", width = "100%", flexGrow = 1, flexBasis = 0,
        minHeight = 0, flexShrink = 1, scrollY = true, showScrollbar = true,
        backgroundColor = C.dark, children = {content}}
    local location = Art.Text((restaurant.name or "今晚的饭局") .. "  ·  " ..
        ((s.drinkBrand and s.drinkBrand.name) or "酒水已备") ..
        (s.dish and ("  ·  " .. s.dish.name) or ""), 10, C.white,
        {width = "100%", backgroundColor = C.dark, paddingHorizontal = 14, paddingVertical = 5})
    local root = Art.Root({Art.Safe({Art.HUD(s, GameLogic.GetLevelData(s.currentLevel).name),
        location, stage, Art.Stats(s, true), scroll})}, Art.Background(restaurant))
    root:SetStyle({backgroundColor = C.dark})

    RefreshActions = function()
        local G = s.guess
        local canAct = alive and not rolling and not settled and G and G.active and not G.winner
        for _, choice in ipairs(GameData.GuessDice.choices) do
            Art.SetDisabled(guessButtons[choice.id], not canAct)
            if rolling then Art.SetSelected(guessButtons[choice.id], false) end
        end
        if canAct then
            actionHint:SetText("他押「" .. GameData.GuessTellLabel(G.tellChoice) ..
                "」" .. (G.tellTrue and "（看着挺真）" or "（八成在骗你）") ..
                " · 你觉得谁更大？")
        else
            actionHint:SetText(settled and "本轮已分出胜负。" or "等待摇骰…")
        end
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
        dialogueCard:Show()
        diceCard:Hide()
        rollSummary:SetText(result:GetText())
        rollSummary:SetVisible(result:IsVisible())
        RefreshLayout()
        focusDialogue = 2
        print("[BanquetUI] 交谈开放 / Round " .. roundToken)
    end
    local function AfterReveal()
        if not alive then return end
        PlaySound(true)
        if s.guess.winner == "player" and not s.intelUsedToday and #GameLogic.GetIntelQuestions() > 0 then
            speaker:SetText("赢得话语权 · 打听明日安排")
            dialogue:SetText("可以问一个问题。回答会保留在这里，读完后再继续交谈。")
            dialogueCard:Show()
            intelQuestions:Show()
            focusDialogue = 2
        else
            resultContinue:Show()
        end
    end
    Settle = function()
        if not alive or settled or not s.guess or not s.guess.winner then return end
        settled = true
        local G = s.guess
        GameLogic.GuessFinish()
        actionPanel:Hide()
        rollButton:Hide()
        local won = G.winner == "player"

        -- 喝醉分支：本轮无法行动，直接判负，不展示骰子。
        if G.drunkOut then
            tellCaption:SetText("你已喝醉")
            tellIcon:SetText("🍺")
            status:SetText("你已喝醉，本轮无法行动 —— 话语权归他")
            result:SetText("连着输了两手，酒劲上头，你连骰子都拿不稳了。" ..
                "\n本轮直接判负，下一轮清醒过来再战。")
            result:Show()
            PlaySfx("lose", 0.8)
            hiddenCup:Show()
            opponentDice:Hide()
            opponentResult:SetText("对方 · 未叫开")
            resultContinue:Show()
            print("[BanquetUI] 喝醉判负（下轮恢复）")
            return
        end

        local mine, theirs = G.playerDie, G.opponentDie
        local relation = mine > theirs and "你的点数更大" or (mine < theirs and "他的点数更大" or "双方点数相同")
        status:SetText(won and "你押中了，赢得本轮话语权" or "他没让你得逞，本轮话语权归他")
        -- 亮骰即真相公开：顶部「他押的是」从预告切换为真实选择，与揭晓行保持一致。
        tellIcon:SetText(GameData.GuessTellLabel(G.opponentChoice))
        tellCaption:SetText("他押的是")
        result:SetText("揭晓：你 " .. mine .. " 点 · 他 " .. theirs .. " 点" ..
            "\n你押「" .. GameData.GuessChoiceLabel(G.playerChoice) ..
            "」 · 他押「" .. GameData.GuessTellLabel(G.opponentChoice) .. "」" ..
            "\n" .. relation .. " —— " ..
            (won and "你押中了，这一手你赢。" or "他押中了，这一手你输。"))
        result:Show()
        PlayGuessOutcome(won)
        hiddenCup:Hide()
        opponentDice:Show()
        opponentResult:SetText("对方 · " .. theirs .. " 点")
        opponentDice.props.onComplete = AfterReveal
        opponentDice:Roll(theirs)
        print("[BanquetUI] 揭晓 玩家=" .. mine .. " 对手=" .. theirs .. " winner=" .. tostring(G.winner))
    end
    -- 平局后重摇：保持动作面板可见，玩家重新押一次。
    ShowRoll = function()
        if not alive or settled then return end
        local G = s.guess
        result:Hide()
        hiddenCup:Show()
        opponentDice:Hide()
        opponentResult:SetText("对方 · 保密")
        rolling = true
        RefreshActions()
        status:SetText("重新摇骰中…")
        playerResult:SetText("我方 · 摇骰中")
        PlaySound(false)
        ownCup:Hide()
        playerDice:Show()
        playerDice.props.onComplete = function()
            if not alive then return end
            rolling = false
            PlaySound(true)
            playerResult:SetText("我方 · " .. G.playerDie .. " 点")
            -- ⚠️ 只能引用预告 G.tellChoice，绝不能写 G.opponentChoice（真实选择），否则泄露答案。
            tellIcon:SetText(GameData.GuessTellLabel(G.tellChoice))
            status:SetText("摇好了。他押「" .. GameData.GuessTellLabel(G.tellChoice) .. "」，轮到你。")
            actionPanel:Show()
            RefreshActions()
        end
        playerDice:Roll(G.playerDie)
    end
    local function BeginRoll()
        if not alive or rolling or settled then return end
        local G = GameLogic.StartGuessRound()
        legend:Hide()
        rollButton:Hide()
        ownCup:Hide()
        -- 喝醉：本轮不摇骰，直接展示判负结果（等 1.5 秒让玩家看清）。
        if G.drunkOut then
            rolling = true
            status:SetText("你已喝醉，连骰子都拿不稳…")
            playerResult:SetText("我方 · 醉倒")
            hiddenCup:Show()
            opponentDice:Hide()
            RefreshActions()
            rerollDelay = 1.5
            pendingDrunkSettle = true
            return
        end
        rolling = true
        RefreshActions()
        playerDice:Show()
        PlaySound(false)
        status:SetText("骰子落定后，轮到你选。")
        playerResult:SetText("我方 · 摇骰中")
        playerDice.props.onComplete = function()
            if not alive then return end
            rolling = false
            PlaySound(true)
            playerResult:SetText("我方 · " .. G.playerDie .. " 点")
            if G.winner then Settle(); return end
            -- ⚠️ 状态行只能引用预告 G.tellChoice，绝不能写 G.opponentChoice（真实选择），否则泄露答案。
            tellIcon:SetText(GameData.GuessTellLabel(G.tellChoice))
            status:SetText("他押「" .. GameData.GuessTellLabel(G.tellChoice) ..
                "」。轮到你 —— 你和他，谁的点数更大？")
            actionPanel:Show()
            RefreshActions()
        end
        playerDice:Roll(G.playerDie)
    end
    rollButton.props.onClick = BeginRoll

    -- 只改已有控件的样式，不重抽事件、不重掷、不重复结算。
    RefreshLayout = function()
        if layoutW <= 0 or layoutH <= 0 then return end
        -- 用真实宽高而不是单一窄屏断点：手机横屏也必须是两列答案。
        local portrait = layoutH > layoutW
        local short = layoutH < 560
        local unit = Art.Unit()
        local touchHeight = math.max(48 * unit, Art.TouchSize())
        local pad = (short and 10 or (portrait and 12 or 18)) * unit
        local gap = (short and 8 or 10) * unit
        local stageRatio = ready and (portrait and 0.25 or 0.30) or (portrait and 0.27 or 0.28)
        local stageHeight = ready and short and not portrait and 40 * unit
            or math.max(96, math.min(layoutH * stageRatio, layoutH - 230))
        stage:SetStyle({height = stageHeight})
        -- 超短横屏交谈时只留人物条，已揭晓结果在答案下方保留。
        diceRow:SetVisible(not (ready and short and not portrait))
        -- 原画保持 contain；纵向半身裁图仅用于实习生，不把人像拉伸或换成大头像。
        local playerPath = (portrait or short) and character.id == "intern" and Art.Pick(A.characters.intern.half)
            or Art.Character(character)
        local background = Art.Background(restaurant, portrait)
        playerArt:SetStyle({backgroundImage = playerPath, left = "2%", width = "44%",
            height = short and "100%" or (portrait and "114%" or "186%"),
            bottom = short and 0 or (portrait and -stageHeight * 0.10 or -stageHeight * 0.85)})
        root:SetStyle({backgroundImage = background})
        opponentArt:SetStyle({right = "2%", width = "44%", height = "100%", bottom = 0})
        foreground:SetStyle({height = math.max(26, stageHeight * 0.22), backgroundFit = "cover"})
        local tagWidth = (portrait and 100 or 150) * unit
        playerTag:SetStyle({visible = not (short and not portrait),
            width = "auto", maxWidth = math.min(tagWidth, layoutW * 0.40),
            height = "auto", paddingVertical = (short and 3 or 6) * unit,
            paddingHorizontal = 8 * unit})
        opponentTag:SetStyle({visible = not (short and not portrait),
            width = "auto", maxWidth = math.min(tagWidth, layoutW * 0.40),
            height = "auto", paddingVertical = (short and 3 or 6) * unit,
            paddingHorizontal = 8 * unit})
        local diceWidth = math.min(layoutW * (portrait and 0.80 or 0.34), 440 * unit)
        local dieSize = math.min((ready and 40 or (short and 54 or 70)) * unit, stageHeight * 0.38)
        diceRow:SetStyle({left = (layoutW - diceWidth) / 2, width = diceWidth,
            bottom = (ready and 2 or 6) * unit, gap = 4 * unit})
        tellPanel:SetStyle({width = "38%", height = 48 * unit, padding = 0})
        tellCaption:SetStyle({lineHeight = 1.1})
        tellIcon:SetStyle({lineHeight = 1.1})
        tellCaption:SetFontSize(Art.FontSize(9))
        tellIcon:SetFontSize(Art.FontSize(12))
        playerResult:SetFontSize(Art.FontSize(10))
        opponentResult:SetFontSize(Art.FontSize(10))
        playerTag:SetFontSize(Art.FontSize(10))
        opponentTag:SetFontSize(Art.FontSize(10))
        for _, die in ipairs({playerDice, opponentDice, ownCup, hiddenCup}) do
            die:SetStyle({width = dieSize, height = dieSize + 8 * unit})
        end
        content:SetStyle({padding = pad, gap = gap})
        workspace:SetStyle({flexDirection = "column", gap = gap})
        diceCard:SetStyle({width = "100%", padding = (short and 16 or 22) * unit, gap = 8 * unit})
        dialogueCard:SetStyle({width = "100%", padding = (short and not portrait and 8 or 14) * unit,
            gap = 6 * unit})
        guessRow:SetStyle({gap = 8 * unit})
        actionPanel:SetStyle({gap = 10 * unit})
        intelQuestions:SetStyle({gap = 8 * unit})
        intelResponse:SetStyle({gap = 12 * unit})
        for _, label in ipairs({dialogue, legend, status, result, actionHint,
            speaker, feedback, intelAnswer, intelTag, rollSummary}) do
            label:SetFontSize(Art.FontSize(12))
        end
        diceHeading:SetFontSize(Art.FontSize(16))
        roundLabel:SetFontSize(Art.FontSize(10))
        location:SetFontSize(Art.FontSize(10))
        dialogue:SetStyle({minHeight = short and not portrait and 0 or touchHeight,
            lineHeight = short and not portrait and 1.25 or 1.5})
        expression:SetStyle({width = 44 * unit, height = 44 * unit})
        bubble:SetStyle({gap = 6 * unit})
        choiceWrap:SetStyle({flexDirection = "row", flexWrap = "wrap", gap = gap})
        local innerWidth = math.max(0, layoutW - pad * 2)
        local choiceWidth = portrait and innerWidth or math.max(0, (innerWidth - gap) / 2)
        for _, button in ipairs(choices) do
            button:SetStyle({width = choiceWidth, flexGrow = 0, flexShrink = 0,
                minHeight = touchHeight, paddingHorizontal = 20 * unit, paddingVertical = 12 * unit})
        end
        for _, button in ipairs({rollButton, resultContinue, intelContinue, table.unpack(choices)}) do
            button:SetStyle({minHeight = touchHeight, paddingHorizontal = 20 * unit, paddingVertical = 12 * unit})
            local label = button:GetChildAt(1) --[[@as Label?]]
            if label then label:SetFontSize(Art.FontSize(12)) end
        end
        for _, button in pairs(guessButtons) do
            button:SetStyle({minHeight = touchHeight, paddingHorizontal = 8 * unit, paddingVertical = 10 * unit})
            local label = button:GetChildAt(1) --[[@as Label?]]
            if label then label:SetFontSize(Art.FontSize(12)) end
        end
        for _, button in ipairs(intelQuestions:GetChildren()) do
            button:SetStyle({minHeight = touchHeight, paddingHorizontal = 20 * unit, paddingVertical = 12 * unit})
            local label = button:GetChildAt(1) --[[@as Label?]]
            if label then label:SetFontSize(Art.FontSize(12)) end
        end
    end
    Art.Responsive(root, function(w, h)
        layoutW, layoutH = w, h
        RefreshLayout()
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
        if rerollDelay > 0 then
            rerollDelay = rerollDelay - dt
            if rerollDelay <= 0 then
                if pendingDrunkSettle then
                    pendingDrunkSettle = false
                    Settle()
                else
                    ShowRoll()
                end
            end
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
        alive, typing, rerollDelay = false, false, 0
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
    if s.guess and s.guess.banquetToken == s.banquetId and s.guess.roundToken == roundToken
        and s.guess.eventToken == event then BeginRoll() end
    print("[BanquetUI] 饭局 Day " .. s.currentDay .. " / Round " .. s.round .. " / 猜骰三选一已挂载")
    return root
end

function Playing.Shutdown()
    for _, source in ipairs({audio.roll, audio.land, audio.reroll, audio.win, audio.lose}) do
        if source then source:StopImmediate() end
    end
    if audio.scene then audio.scene:Dispose() end
    audio = {}
end

return Playing
