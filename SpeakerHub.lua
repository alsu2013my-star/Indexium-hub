-- Speaker Tower Defense Macro Hub
-- Prototype for Roblox executors that support VirtualInputManager.
-- Record/Replay captures mouse clicks and keyboard presses while this UI is hidden.
-- Auto Replay is intentionally manual-cycle only until the game's end-screen UI
-- and the executor's input API are verified. Do not run unattended.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer

local events, recording, playing, stopRequested = {}, false, false, false
local startedAt = 0

local gui = Instance.new("ScreenGui")
gui.Name = "SpeakerMacroHub"
gui.ResetOnSpawn = false
gui.Parent = game:GetService("CoreGui")

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(220, 220)
panel.Position = UDim2.new(0, 24, 0.35, 0)
panel.BackgroundColor3 = Color3.fromRGB(28, 30, 40)
panel.Active, panel.Draggable = true, true
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)

local status = Instance.new("TextLabel")
status.Size = UDim2.new(1, -12, 0, 30)
status.Position = UDim2.fromOffset(6, 4)
status.BackgroundTransparency = 1
status.TextColor3 = Color3.new(1, 1, 1)
status.Text = "READY | 0 actions"
status.Parent = panel

local function setStatus(s)
    status.Text = s .. " | " .. #events .. " actions"
end

local function makeButton(text, y, fn)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, -20, 0, 32)
    b.Position = UDim2.fromOffset(10, y)
    b.Text = text
    b.TextColor3 = Color3.new(1, 1, 1)
    b.BackgroundColor3 = Color3.fromRGB(55, 65, 90)
    b.Parent = panel
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(fn)
end

-- Ignore input while the macro panel itself is clicked.
local function panelHasFocus()
    local focused = UIS:GetFocusedTextBox()
    return focused ~= nil
end

UIS.InputBegan:Connect(function(input, processed)
    if not recording or processed or panelHasFocus() then return end
    local t = os.clock() - startedAt

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        local p = UIS:GetMouseLocation()
        table.insert(events, {kind = "mouse", x = p.X, y = p.Y, t = t})
    elseif input.UserInputType == Enum.UserInputType.Keyboard then
        table.insert(events, {kind = "key", key = input.KeyCode, t = t})
    end
end)

local function replayOnce()
    if playing or #events == 0 then return end
    playing, stopRequested = true, false
    setStatus("REPLAYING")

    task.spawn(function()
        local previous = 0
        for _, e in ipairs(events) do
            if stopRequested then break end
            task.wait(math.max(0, e.t - previous))
            previous = e.t

            local ok, err = pcall(function()
                if e.kind == "mouse" then
                    VIM:SendMouseButtonEvent(e.x, e.y, 0, true, game, 0)
                    VIM:SendMouseButtonEvent(e.x, e.y, 0, false, game, 0)
                elseif e.kind == "key" then
                    VIM:SendKeyEvent(true, e.key, false, game)
                    VIM:SendKeyEvent(false, e.key, false, game)
                end
            end)
            if not ok then
                warn("Replay input failed: " .. tostring(err))
                break
            end
        end
        playing = false
        setStatus(stopRequested and "STOPPED" or "READY")
    end)
end

makeButton("RECORD", 42, function()
    if playing then return end
    events = {}
    recording = true
    startedAt = os.clock()
    setStatus("RECORDING")
end)

makeButton("STOP RECORD", 80, function()
    recording = false
    setStatus("RECORDED")
end)

makeButton("REPLAY", 118, replayOnce)

makeButton("AUTO REPLAY (manual)", 156, function()
    setStatus("AUTO REPLAY NOT CONFIGURED")
    warn("Automatic match detection / Hard voting is not configured for this game UI.")
end)

makeButton("STOP ALL", 194, function()
    recording = false
    stopRequested = true
    setStatus("STOP REQUESTED")
end)

print("Speaker Macro Hub loaded. Test with a short, harmless macro first.")
