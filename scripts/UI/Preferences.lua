-- 客户端 UI 偏好与模态弹层；不初始化 UI、不替换 root、不依赖 Game.State。
-- 主界面初始化后可调用 Load()；Get()/ShowSettings() 也会惰性加载。
local UI = require("urhox-libs/UI")
local Art = require("UI.ArtTheme")
local C = Art.C
local Preferences = {}
local SAVE_PATH = "ui_preferences.json"
-- 网页预览的文件系统在内存里，刷新即丢；云变量按账号持久，是跨刷新保留偏好的通道。
local CLOUD_KEY = "jiuzhuo_ui_preferences"
local SPEEDS = {slow = true, normal = true, fast = true, instant = true}
local values = {sfxVolume = 80, dialogueSpeed = "normal"}
local loaded, dirty = false, false
-- 云变量回包是异步的：未回来前用文件或默认值，回来后只在用户没改过时才覆盖。
local cloudSettled, cloudFailed = false, false
---@type Modal?
local activeModal = nil
---@type Label?
local statusLabel = nil
---@type table<number, fun()>
local listeners = {}

local function Snapshot()
    return {sfxVolume = values.sfxVolume, dialogueSpeed = values.dialogueSpeed}
end

local function ApplyAudio()
    -- 骰子 SoundSource 使用 SOUND_EFFECT；保留每个素材原本的相对 gain。
    if audio then audio:SetMasterGain(SOUND_EFFECT, values.sfxVolume / 100) end
end

local function SetStatus(saved)
    if statusLabel then
        statusLabel:SetText(saved and "偏好已自动保存" or "本次已生效，暂无法保存到本机")
        statusLabel:SetFontColor(saved and C.muted or C.red)
    end
end

-- 校验来自文件或云变量的存档；非法字段独立回退，不把坏数据交给游戏层。
---@param data any
---@return boolean applied
local function Apply(data)
    if type(data) ~= "table" then return false end
    local volume = data.sfxVolume
    if type(volume) == "number" and volume == volume and volume >= 0 and volume <= 100 then
        values.sfxVolume = math.floor(volume + 0.5)
    end
    if type(data.dialogueSpeed) == "string" and SPEEDS[data.dialogueSpeed] then
        values.dialogueSpeed = data.dialogueSpeed
    end
    ApplyAudio()
    return true
end

-- 本机文件写入：网页预览下只存在于内存文件系统，作为云变量不可用时的降级。
---@return boolean written
local function SaveLocal()
    ---@type File?
    local file = nil
    local ok, written = pcall(function()
        local encoded = cjson.encode(Snapshot())
        file = File(SAVE_PATH, FILE_WRITE)
        if not file or not file:IsOpen() then return false end
        return file:WriteString(encoded)
    end)
    if file then file:Dispose() end
    return ok and written == true
end

-- 云变量失败只提示一次，避免每次拖动滑杆都刷日志。
local function SaveCloud()
    if cloudFailed or not clientCloud then return end
    pcall(function()
        clientCloud:Set(CLOUD_KEY, Snapshot(), {
            error = function(code, reason)
                cloudFailed = true
                print("[Preferences] 云偏好保存失败 " .. tostring(code) .. " " .. tostring(reason))
            end,
        })
    end)
end

---@return boolean saved
local function Save()
    if not dirty then return true end
    local saved = SaveLocal()
    SaveCloud()
    if saved then
        dirty = false
    else
        print("[Preferences] 无法写入本机偏好文件，已提交云偏好")
    end
    SetStatus(saved)
    return saved
end

local function Notify()
    for index = #listeners, 1, -1 do
        local callback = listeners[index]
        listeners[index] = nil
        pcall(callback)
    end
end

-- 先读本机文件立即生效，再异步取云偏好；用户已改动则不让回包覆盖。
local function LoadCloud()
    if not clientCloud then cloudSettled = true; return end
    local ok = pcall(function()
        clientCloud:Get(CLOUD_KEY, {
            ok = function(values_, iscores)
                cloudSettled = true
                local data = type(values_) == "table" and values_[CLOUD_KEY] or nil
                if dirty or type(data) ~= "table" then Notify(); return end
                if Apply(data) then
                    print("[Preferences] 已应用云偏好，骰子音量=" .. values.sfxVolume
                        .. "，对话速度=" .. values.dialogueSpeed)
                end
                Notify()
            end,
            error = function(code, reason)
                cloudSettled, cloudFailed = true, true
                print("[Preferences] 云偏好读取失败 " .. tostring(code) .. " " .. tostring(reason))
                Notify()
            end,
        })
    end)
    if not ok then cloudSettled = true end
end

-- 非法/缺失字段独立回退默认值；不把坏档内容交给游戏层。
---@return table preferences Copy of current preferences; loading is idempotent.
function Preferences.Load()
    if loaded then return Snapshot() end
    loaded = true
    ---@type File?
    local file = nil
    local ok, data = pcall(function()
        if not fileSystem:FileExists(SAVE_PATH) then return nil end
        file = File(SAVE_PATH, FILE_READ)
        if not file or not file:IsOpen() then return nil end
        if file:GetSize() > 16384 then error("偏好文件过大") end
        return cjson.decode(file:ReadString())
    end)
    if file then file:Dispose() end
    if ok and type(data) == "table" then
        Apply(data)
    elseif not ok or data ~= nil then
        print("[Preferences] UI 偏好文件损坏，已使用默认设置")
    end
    ApplyAudio()
    LoadCloud()
    print("[Preferences] 已加载，骰子音量=" .. values.sfxVolume .. "，对话速度=" .. values.dialogueSpeed)
    return Snapshot()
end

-- 打开设置前调用：等云偏好回来再画控件，避免面板数值和实际生效值不一致。
---@param callback fun()
function Preferences.WhenReady(callback)
    Preferences.Load()
    if cloudSettled then callback(); return end
    listeners[#listeners + 1] = callback
end

---@param key string "sfxVolume" | "dialogueSpeed"
---@return number|string|nil
function Preferences.Get(key)
    Preferences.Load()
    if key == "sfxVolume" then return values.sfxVolume end
    if key == "dialogueSpeed" then return values.dialogueSpeed end
    return nil
end

---@param key string
---@param value any
---@return boolean accepted
local function UpdateValue(key, value)
    Preferences.Load()
    if key == "sfxVolume" then
        if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
            return false
        end
        local volume = math.floor(math.max(0, math.min(100, value)) + 0.5)
        if values.sfxVolume ~= volume then
            values.sfxVolume, dirty = volume, true
        end
        ApplyAudio()
        return true
    elseif key == "dialogueSpeed" and type(value) == "string" and SPEEDS[value] then
        if values.dialogueSpeed ~= value then
            values.dialogueSpeed, dirty = value, true
        end
        return true
    end
    return false
end

-- 设置即时生效；返回 accepted, saved。磁盘失败不撤销本次会话设置。
---@param key string "sfxVolume" | "dialogueSpeed"
---@param value any
---@return boolean accepted
---@return boolean saved
function Preferences.Set(key, value)
    if not UpdateValue(key, value) then return false, false end
    return true, Save()
end

-- 官方 Modal 的内容与 footer 是独立 Yoga 子树，不在普通 children 中。
-- 在用户模块中补齐 id 查询和销毁，避免改引擎库或反复开关泄漏 Yoga 节点。
---@class PreferencesModal : Modal
---@field body_ Widget?
local PreferencesModal = UI.Modal:Extend("PreferencesModal")

function PreferencesModal:Init(props)
    UI.Modal.Init(self, props)
    self.disposed_ = false
    self.body_ = nil
    self.idealHeight_ = 0
    self.lastWidth_, self.lastHeight_ = -1, -1
end

function PreferencesModal:Update(dt)
    if self.body_ then
        local insets = UI.GetSafeAreaInsets()
        local w = UI.GetWidth() - insets.left - insets.right
        local h = UI.GetHeight() - insets.top - insets.bottom
        if w ~= self.lastWidth_ or h ~= self.lastHeight_ then
            self.lastWidth_, self.lastHeight_ = w, h
            self:SetSize((w < 540 or h < 500) and "fullscreen" or "md")
            self.body_:SetStyle({height = math.min(self.idealHeight_, math.max(64, h * 0.9 - 122))})
        end
    end
    UI.Modal.Update(self, dt)
end

function PreferencesModal:FindById(id)
    local found = UI.Widget.FindById(self, id)
    if found then return found end
    found = self.contentContainer_:FindById(id)
    if found then return found end
    if self.footerWidget_ then return self.footerWidget_:FindById(id) end
    return nil
end

function PreferencesModal:Destroy()
    if self.disposed_ then return end
    self.disposed_ = true
    self:Close()
    if activeModal == self then activeModal, statusLabel = nil, nil end
    self.contentContainer_.parent = nil
    self.contentContainer_:Destroy()
    if self.footerWidget_ then
        self.footerWidget_.parent = nil
        self.footerWidget_:Destroy()
        self.footerWidget_ = nil
    end
    UI.Widget.Destroy(self)
end

-- main 切屏或 Stop 时调用；不会执行 ConfirmReturn 的确认回调。
function Preferences.CloseAll()
    Save()
    local modal = activeModal
    if modal then modal:Close(); modal:Destroy() end
    activeModal, statusLabel = nil, nil
end

---@param id string
---@return PreferencesModal?
local function CreateModal(id)
    Preferences.CloseAll()
    if not UI.GetRoot() then
        print("[Preferences] 请先初始化 UI 并挂载页面，再打开设置/确认框")
        return nil
    end
    local modal = PreferencesModal:new({
        id = id, size = "md", fontFamily = "sans",
        showCloseButton = false, closeOnOverlay = false, closeOnEscape = true,
        backgroundColor = C.paper, borderColor = C.yellow, borderWidth = 1,
        borderRadius = 14, contentPadding = 20, footerPadding = {8, 20, 16, 20},
        onClose = function(self)
            Save()
            self:Destroy()
        end,
    })
    activeModal = modal
    return modal
end

-- 内容区固定高度 + ScrollView；小屏/转屏仅重新布局，不重建游戏或设置树。
---@param modal PreferencesModal
---@param body Widget
---@param idealHeight number
local function ResponsiveModal(modal, body, idealHeight)
    modal.body_, modal.idealHeight_ = body, idealHeight
    modal:Update(0)
end

---@return Modal? modal Close/CloseAll dismisses and destroys it; do not reuse after close.
function Preferences.ShowSettings()
    if activeModal and activeModal.id == "settings_modal" then return activeModal end
    -- 等云偏好回来再画，避免面板显示默认值却已按云端值生效。
    Preferences.WhenReady(function()
        if activeModal and activeModal.id == "settings_modal" then return end
        Preferences.ShowSettings_()
    end)
    return activeModal
end

---@return Modal?
function Preferences.ShowSettings_()
    local modal = CreateModal("settings_modal")
    if not modal then return nil end
    local volumeLabel = Art.Text(tostring(values.sfxVolume) .. "%", 13, C.purple,
        {id = "settings_sfx_value", textAlign = "right", width = 72})
    statusLabel = Art.Text("修改即时生效，偏好自动保存", 10, C.muted,
        {id = "settings_save_status", width = "100%", fontFamily = "sans"})
    local volumeSlider = UI.Slider {
        id = "settings_sfx_volume", width = "100%", height = 36,
        min = 0, max = 100, step = 1, value = values.sfxVolume,
        trackBgColor = C.line, trackFillColor = C.purple, thumbColor = C.yellow,
        thumbSize = 22, trackHeight = 5, borderWidth = 0,
        onChange = function(_, value)
            UpdateValue("sfxVolume", value)
            volumeLabel:SetText(tostring(values.sfxVolume) .. "%")
        end,
        onChangeEnd = function() Save() end,
    }
    local speedOptions = {
        {key = "slow", text = "慢速"}, {key = "normal", text = "标准"},
        {key = "fast", text = "快速"}, {key = "instant", text = "即刻"},
    }
    ---@type Widget[]
    local speedButtons = {}
    local function RefreshSpeed()
        for index, option in ipairs(speedOptions) do
            local selected = values.dialogueSpeed == option.key
            speedButtons[index]:SetStyle({borderColor = selected and C.purple or C.line,
                backgroundColor = selected and C.lilac or C.white, borderWidth = selected and 2 or 1})
        end
    end
    for index, option in ipairs(speedOptions) do
        speedButtons[index] = Art.Button(option.text, function()
            Preferences.Set("dialogueSpeed", option.key)
            RefreshSpeed()
        end, true, {id = "settings_dialogue_" .. option.key, flat = true,
            flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 60, paddingHorizontal = 8,
            fontSize = 12, minHeight = 44})
    end
    RefreshSpeed()
    local unit = Art.Unit()
    local content = UI.Panel {width = "100%", paddingRight = 16, gap = 14 * unit, children = {
        Art.Title("桌边偏好", 23, C.purple, {id = "settings_title", width = "100%"}),
        Art.Text("按自己的节奏入席。偏好按账号保存，换设备也会保留。", 11, C.muted, {width = "100%", fontFamily = "sans"}),
        UI.Panel {width = "100%", gap = 4, children = {
            UI.Panel {width = "100%", flexDirection = "row", alignItems = "center", children = {
                Art.Text("骰子音效音量", 14, C.ink,
                    {flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0, fontFamily = "sans"}), volumeLabel,
            }},
            volumeSlider,
            Art.Text("0 为静音，仅调整骰子等音效，不影响其他音轨。", 10, C.muted,
                {width = "100%", fontFamily = "sans"}),
        }},
        UI.Panel {width = "100%", gap = 10, children = {
            Art.Text("对话显示速度", 14, C.ink, {fontFamily = "sans", width = "100%"}),
            UI.Panel {id = "settings_dialogue_speed", width = "100%", flexDirection = "row",
                gap = 8, children = speedButtons},
            Art.Text("随时点击对话可直接显示整句。", 10, C.muted,
                {width = "100%", fontFamily = "sans"}),
        }},
        statusLabel,
    }}
    local body = UI.Panel {width = "100%", height = 400, flexShrink = 1, minHeight = 0, children = {
        UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, minHeight = 0,
            flexShrink = 1, scrollY = true, children = {content}},
    }}
    modal:AddContent(body)
    modal:SetFooter(UI.Panel {width = "100%", children = {
        Art.Button("完成", function() modal:Close() end, false,
            {id = "settings_close", width = "100%"}),
    }})
    ResponsiveModal(modal, body, 400 * unit)
    modal:Open()
    print("[Preferences] 设置弹层已打开")
    return modal
end

---@param onConfirm fun() Only called once after explicit confirmation; modal is already removed.
---@return Modal?
function Preferences.ConfirmReturn(onConfirm)
    local modal = CreateModal("return_confirmation_modal")
    if not modal then return nil end
    local confirmed = false
    local body = UI.Panel {width = "100%", height = 180, flexShrink = 1, minHeight = 0, children = {
        UI.ScrollView {width = "100%", flexGrow = 1, flexBasis = 0, minHeight = 0, flexShrink = 1,
            children = {
                UI.Panel {width = "100%", gap = 14, children = {
                    Art.Title("现在离席？", 23, C.purple, {width = "100%"}),
                    Art.Text("返回主菜单后，当前局将结束。未保存的本局进度将丢失，且不会自动保存。", 14, C.ink,
                        {id = "confirm_return_warning", width = "100%", fontFamily = "sans"}),
                    Art.Text("选择「继续入席」可回到原来的游戏。", 11, C.muted,
                        {width = "100%", fontFamily = "sans"}),
                }},
            }},
    }}
    modal:AddContent(body)
    modal:SetFooter(UI.Panel {width = "100%", flexDirection = "row", gap = 12, children = {
        Art.Button("继续入席", function() modal:Close() end, true,
            {id = "cancel_return", flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0}),
        Art.Button("确认返回", function()
            if confirmed or not modal:IsOpen() then return end
            confirmed = true
            modal:Close()
            if onConfirm then onConfirm() end
        end, false, {id = "confirm_return", flexGrow = 1, flexBasis = 0, flexShrink = 1, minWidth = 0}),
    }})
    ResponsiveModal(modal, body, 180)
    modal:Open()
    print("[Preferences] 返回确认弹层已打开；取消不改变本局状态")
    return modal
end

return Preferences
