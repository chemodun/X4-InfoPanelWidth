-- Adds an Options > Game Settings slider (right before "Menu Width Scale (Experts)")
-- that controls Helper.playerInfoConfig.width (as a percentage of Helper.viewWidth) -
-- primarily the Map screen's left/right Information Panels, and, since vanilla reuses the
-- same value, several other menus besides.
--
-- The old fixed one-liner was:
--   Helper.playerInfoConfig.width = math.min(0.3 * Helper.viewWidth, Helper.scaleX(960))
-- i.e. a ceiling: width grows with the view but never exceeds a ~960px-equivalent cap.
-- The slider's minimum goes through that same Helper.scaleX(x) / Helper.viewWidth
-- transform, at a 320px reference width - the point where the old cap itself used to
-- kick in, so it moves with resolution/UI Scale. The maximum is a flat MAX_PERCENT
-- (45%), not derived from the 960px reference at all - an explicit user choice.
--
-- Because only one bound is dynamic, min < max is NOT a mathematical guarantee: at high
-- enough UI Scale/resolution, the 320px floor's *percentage* can climb above a flat 45%
-- (this exact scenario, with the roles reversed, crashed the Options menu on this
-- user's own setup earlier this session - see claude/mod-info_panel_width.md for the
-- full trail). EffectiveMax() guards against it by raising the ceiling to match the
-- floor whenever that happens, so min <= max always holds; in that edge case the slider
-- just has no draggable range (a fixed single value) instead of crashing.
--
-- Confirm/Reset follows the same pattern vanilla's own "uiscale" row uses (see
-- menu.valueGameUIScale/menu.callbackGameUIScale/menu.callbackGameUIScaleConfirm/
-- menu.callbackGameUIScaleReset in gameoptions.xpl): dragging only updates a
-- *pending* value; nothing is applied/persisted until Confirm. Confirm triggers a
-- full UI reload (ScheduleReloadUI()), same as UI Scale's own Confirm does via its
-- own engine-side setter - see OnConfirm() below for why.
--
-- Reset is dual-purpose (a deliberate extension beyond vanilla's own uiscale/
-- menuwidthscale rows, which have no "restore factory default" concept at all): while
-- a drag is pending it discards it back to the last-applied value, same as vanilla;
-- once nothing is pending, it instead becomes a "Default" button (relabelled via
-- neg_name, reusing vanilla's own shared ReadText(1001, 3231) string) that's
-- selectable whenever the applied value isn't already DEFAULT_PERCENT, letting the
-- player get back to the vanilla 30% at any time without having to fight the slider
-- for an exact value. See OnReset()/IsWidthDefault() below.

local PAGE_ID = 1972092436
local DEFAULT_PERCENT = 30
local MAX_PERCENT = 45

__INFO_PANEL_WIDTH_DATA = __INFO_PANEL_WIDTH_DATA or {}

local widthPercent = __INFO_PANEL_WIDTH_DATA.widthPercent or DEFAULT_PERCENT
local pendingPercent = widthPercent
local optionsMenu = nil

local function ReferencePercent(referenceWidth)
  return Helper.round(100 * Helper.scaleX(referenceWidth) / Helper.viewWidth)
end

local function ClampPercent(percent, minPercent, maxPercent)
  if percent < minPercent then
    return minPercent
  elseif percent > maxPercent then
    return maxPercent
  end
  return percent
end

-- MAX_PERCENT (45%) is a flat value, while the minimum below is still derived from the
-- resolution/UI-Scale-dependent 320px reference - see the header comment for why that
-- means min<=max isn't automatic here, and why this raises the ceiling to match the
-- floor instead of letting them invert.
local function EffectiveMax(minPercent)
  return math.max(MAX_PERCENT, minPercent)
end

local function ApplyWidth()
  local minPercent = ReferencePercent(320)
  local maxPercent = EffectiveMax(minPercent)
  Helper.playerInfoConfig.width = (ClampPercent(widthPercent, minPercent, maxPercent) / 100) * Helper.viewWidth
end

ApplyWidth()

local function SaveWidthPercent()
  __INFO_PANEL_WIDTH_DATA.widthPercent = widthPercent
end

local function IsPending()
  return pendingPercent ~= widthPercent
end

local function IsWidthDefault()
  return widthPercent == DEFAULT_PERCENT
end

-- Mirrors menu.callbackGameUIScaleConfirm() (gameoptions.xpl) structurally: push
-- nav history, set the __CORE_GAMEOPTIONS_RESTORE flags so the Options menu reopens
-- to this same page after the reload, commit the value inside the delayed callback,
-- then show the "please wait" placeholder while the UI reloads. UI Scale's version
-- calls C.SetUIScaleFactor() there, whose reload is what dismisses the placeholder
-- (via init() checking __CORE_GAMEOPTIONS_RESTORE on the next load) - we have no
-- engine-side setter of our own, so ScheduleReloadUI() (helper.lua's own generic
-- "reload the UI now" call, used there as its view-creation-failure recovery path)
-- stands in for it.
local function OnConfirm()
  if IsPending() then
    table.insert(optionsMenu.history, 1, { optionParameter = optionsMenu.currentOption, topRow = GetTopRow(optionsMenu.optionTable), selectedOption = "info_panel_width_factor" })
    __CORE_GAMEOPTIONS_RESTORE = true
    __CORE_GAMEOPTIONS_RESTOREINFO.optionParameter = nil
    __CORE_GAMEOPTIONS_RESTOREINFO.history = optionsMenu.history
    Helper.addDelayedOneTimeCallbackOnUpdate(function()
      widthPercent = pendingPercent
      SaveWidthPercent()
      ScheduleReloadUI()
    end, true, getElapsedTime() + 0.1)
    optionsMenu.displayInit(ReadText(1001, 409))
  end
end

-- Dual-purpose, matching vanilla's own Confirm/Reset pending-value pattern: while a
-- drag is pending, Reset just discards it back to the last-applied widthPercent (as
-- before). Once nothing is pending, Reset (now relabelled "Default") becomes usable
-- again as long as the applied value isn't already the vanilla default, letting the
-- player get back to it without having to fight the slider for an exact 30%. Either
-- way this only sets *pendingPercent* - the player still has to hit Confirm to
-- actually apply/save/reload, same as a drag.
local function OnReset()
  if IsPending() then
    pendingPercent = widthPercent
  else
    pendingPercent = DEFAULT_PERCENT
  end
  if optionsMenu then
    optionsMenu.refresh()
  end
end

local function OnDisplayOptions(options, config)
  if not (optionsMenu and (optionsMenu.currentOption == "game")) then
    return options
  end
  if type(options) ~= "table" then
    return options
  end

  for _, row in ipairs(options) do
    if (type(row) == "table") and (row.id == "info_panel_width_factor") then
      return options -- already inserted on a previous render
    end
  end

  local insertAt = nil
  for i, row in ipairs(options) do
    if (type(row) == "table") and (row.id == "menuwidthscale") then
      insertAt = i
      break
    end
  end

  table.insert(options, insertAt or (#options + 1), {
    id = "info_panel_width_factor",
    name = function() return ReadText(PAGE_ID, 100) end,
    mouseOverText = function() return ReadText(PAGE_ID, 101) end,
    valuetype = "slidercell",
    value = function()
      local minPercent = ReferencePercent(320)
      local maxPercent = EffectiveMax(minPercent)
      -- Clamp the *existing* pendingPercent (drag in progress, or a pending Reset-to-
      -- Default), not widthPercent - this function reruns on every optionsMenu.refresh(),
      -- and re-deriving from widthPercent here would silently discard whatever Reset/drag
      -- just set before the player gets to click Confirm.
      pendingPercent = ClampPercent(pendingPercent, minPercent, maxPercent)
      return {
        min = minPercent,
        max = maxPercent,
        start = pendingPercent,
        step = 1,
        suffix = "%",
      }
    end,
    callback = function(value)
      if value then
        pendingPercent = value
      end
    end,
    confirmline = {
      positive = function() return OnConfirm() end,
      pos_name = ReadText(1001, 2821),
      pos_selectable = function() return IsPending() end,
      negative = function() return OnReset() end,
      neg_name = function() return IsPending() and ReadText(1001, 3318) or ReadText(1001, 3231) end,
      neg_selectable = function() return IsPending() or (not IsWidthDefault()) end,
    },
  })

  return options
end

local optionsMenuHooked = false

local function EnsureOptionsMenuHooked()
  if optionsMenuHooked then
    return true
  end
  optionsMenu = Helper.getMenu("OptionsMenu")
  if not (optionsMenu and (type(optionsMenu.registerCallback) == "function")) then
    return false
  end
  optionsMenu.registerCallback("displayOptions_modifyOptions", OnDisplayOptions)
  optionsMenuHooked = true
  return true
end

if not EnsureOptionsMenuHooked() then
  Helper.addDelayedOneTimeCallbackOnUpdate(EnsureOptionsMenuHooked, false, getElapsedTime() + 1)
end
