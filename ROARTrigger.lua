-- RoarGuild v1.32-Epoch
-- Project Epoch / Wrath 3.3.5 client
-- SavedVariables: ROGUDB

-------------------------------------------------
-- [0] Constants
-------------------------------------------------
local ADDON_VERSION = "1.32-Epoch"

local ROAR_REMINDER_INTERVAL = 420
local ROAR_REMINDER_CD = 73

-- Independent global fallback defaults per profile
-- chancePermille: 5 => 0.5%
local FALLBACK_DEFAULT = { enabled = true, cd = 2, chancePermille = 5, last = 0, emoteIDs = { 1 } }

-------------------------------------------------
-- [1] Shared Utils
-------------------------------------------------
local U = {}

function U.trim(s)
  s = s or ""
  s = string.gsub(s, "^%s+", "")
  s = string.gsub(s, "%s+$", "")
  return s
end

function U.upper(s)
  return string.upper(U.trim(s or ""))
end

function U.split_cmd(raw)
  local s = U.trim(raw or "")
  local cmd, rest = string.match(s, "^(%S+)%s*(.*)$")
  if not cmd then return "", "" end
  return cmd, rest or ""
end

function U.count(t)
  if type(t) ~= "table" then return 0 end
  return #t
end

function U.pick(t)
  local n = U.count(t)
  if n < 1 then return nil end
  return t[math.random(1, n)]
end

function U.arrayHas(t, value)
  if type(t) ~= "table" then return false end
  for i = 1, #t do
    if t[i] == value then return true end
  end
  return false
end

-------------------------------------------------
-- [2] RoarGuild State
-------------------------------------------------
local ROGU = {
  profileKey = nil,
  profile = nil,
  slots = nil,
  fallback = nil,
  enabled = true,
  watchMode = false,
  stats = nil,

  lastRoar = 0,
  lastReminder = 0,

  _loaded = false,
}

-------------------------------------------------
-- [2.1] Data Pools
-------------------------------------------------
local inviteText = {
"<ROAR> Friendly hearts and muddy boots, campfire songs and tangled routes, no racing clocks no joyless chore, just wandering roads and one more roar.",

"<ROAR> Across the hills the laughter rolls through dungeon halls and snowy knolls, not thundercloud nor battle cry, just friends beneath an open sky.",

"<ROAR> We hunt for stories not for speed, for strange mishaps and reckless deed, for roadside fires and ale poured warm, and roaring loud through every storm.",

"<ROAR> Tankards high and embers bright, clumsy pulls deep in the night, dusty boots and spirits sure, all are welcome to the roar.",

"<ROAR> Slow old roads and thunder cheer, familiar voices drawing near, if noisy hearts make you feel warm, then step beside the roaring storm.",

"<ROAR> Quests and caverns blades and lore, laughter shaking tavern floor, we play for moments rich and true, not hollow praise or numbers blue.",

"<ROAR> Sit awhile for sky and song, for winding roads that drift along, no score to chase no race to win, just firelight glow and wandering kin.",

"<ROAR> Inspire first and boast no more, lift each other from the floor, steady souls in ember light, roaring proudly through the night.",

"<ROAR> Wanderers wide and dreamers strange, crafters with inventions deranged, bring your story scar and snore, let Azeroth resound with ROAR.",

"<ROAR> Curiosity hand in hand, steady feet on living land, stories carried mile by mile, roaring loud all the while.",

"<ROAR> No frantic pace no joyless grind, just wandering roads and open mind, good company and spirits bright, roaring warm into the night.",

"<ROAR> For those who lose themselves with grace in forest path or desert space, who read the lines and hear the lore, there is always room for more.",

"<ROAR> We chase the spark in fleeting glance, in roadside joke and dungeon chance, not numbers stacked in lifeless score, but moments worth a mighty roar.",

"<ROAR> Azeroth is living ground not trophies stacked nor meters crowned, so walk it slow and hearts ignite, then roar beneath the stars tonight.",

"<ROAR> From quiet dusk to battle cry, from tavern cheer to storming sky, every voice both rough and true adds another flame to you.",

"<ROAR> Explorers dreamers blades held fast, storytellers future and past, all find warmth beside the door, all find welcome in the roar.",

"<ROAR> At your own pace the long roads bend with steady kin and honest friend, share the burden share the view, let the wild world open through.",

"<ROAR> Small triumphs grand victories, muddy wipes and memories, if it stirs the soul at all we answer with a thunder call.",

"<ROAR> Shared adventures deep and bright, long earned rest by firelight, wander wide where wild winds soar, then raise your mug and join the roar.",

"<ROAR> We roam we laugh we quest once more, getting lost from shore to shore, not in haste but full of cheer, roaring loud for all to hear.",

"<ROAR> No need to rush no need to race, just find your boots a steady pace, the road is long the fire is warm, come join the loud and laughing storm.",

"<ROAR> Through valleys deep and ruins old, through battle smoke and tavern gold, we wander far with spirits bright, then roar together through the night.",

"<ROAR> Warning friend before you stay: strange adventures may come your way, side effects include loud cheer, battle cries and too much beer.",

"<ROAR> Through hill and shore we seek the lore, then somehow pull three packs more, we wipe we laugh we charge once more, and roar again like before.",

"<ROAR> We take it slow let stories grow, through snowfall path and ember glow, no perfect plan no polished score, just living loud within the roar.",

"<ROAR> Ask the question cross the span, build strange bridges while you can, curiosity lights the door, step inside and join the roar.",

"<ROAR> Strength with respect rings clear and wide, steady thunder side by side, bring your voice both fierce and warm, and join the loud unbroken storm.",

"<ROAR> Bonds in trial bonds in flame, outlast glory outlast fame, walk together thick and thin, and let the roaring laughter in.",

"<ROAR> Tell your story by the flame, let it wander let it change, stories shared grow rich and strong, carried by the roaring song.",

"<ROAR> Old traditions breathe and grow when fresh new voices join the flow, bring your tale and let it soar, add your thunder to the roar.",

"<ROAR> Gold may fade and crowns may fall, but roaring laughter outlives all, build your tale with steady core, and let it echo evermore.",

"<ROAR> Shared feast and open door, muddy boots upon the floor, sit and stay and rest awhile, roaring loud through grief and smile.",

"<ROAR> The sky moves slow yet never strays, so shape your life in wandering ways, no race to win no clock to fear, just steady hearts and roaring cheer."
}

-------------------------------------------------
-- [2.2] Chat + Emote
-------------------------------------------------
local function roarChat(text)
  if DEFAULT_CHAT_FRAME then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff4444RoarGuild:|r " .. tostring(text or ""))
  end
end

local function performEmote(token)
  token = U.upper(token or "ROAR")
  if token == "" then token = "ROAR" end

  if DoEmote then
    DoEmote(token)
  else
    SendChatMessage("makes a battle cry!", "EMOTE")
  end
end

-------------------------------------------------
-- [2.3] Profiles
-------------------------------------------------
local function ROGU_ProfileKey()
  local name = UnitName("player") or "Unknown"
  local realm = (GetRealmName and GetRealmName()) or ""
  if realm == "" then return name end
  return name .. "-" .. realm
end

local function ROGU_EnsureEmoteDefaults(db)
  if type(db.emotes) ~= "table" then db.emotes = {} end

  if #db.emotes < 1 then
    db.emotes[1] = { emote = "ROAR" }
    return
  end

  if type(db.emotes[1]) ~= "table" or type(db.emotes[1].emote) ~= "string" or db.emotes[1].emote == "" then
    db.emotes[1] = { emote = "ROAR" }
  else
    db.emotes[1].emote = U.upper(db.emotes[1].emote)
    if db.emotes[1].emote == "" then db.emotes[1].emote = "ROAR" end
  end
end

local function ROGU_EnsureFallbackDefaultsOn(tbl)
  if type(tbl) ~= "table" then return end
  if tbl.enabled == nil then tbl.enabled = FALLBACK_DEFAULT.enabled end
  if tbl.cd == nil then tbl.cd = FALLBACK_DEFAULT.cd end
  if tbl.chancePermille == nil then tbl.chancePermille = FALLBACK_DEFAULT.chancePermille end
  if tbl.last == nil then tbl.last = 0 end
  if type(tbl.emoteIDs) ~= "table" or #tbl.emoteIDs < 1 then tbl.emoteIDs = { 1 } end
end

local function ROGU_EnsureDB()
  if type(ROGUDB) ~= "table" then ROGUDB = {} end
  if type(ROGUDB.profiles) ~= "table" then ROGUDB.profiles = {} end
  ROGU_EnsureEmoteDefaults(ROGUDB)
  return ROGUDB
end

local function ROGU_MigrateLegacyRootToProfile(db, p)
  if p._migrated == true then return end

  if type(db.slots) == "table" and type(p.slots) == "table" and next(p.slots) == nil then
    p.slots = db.slots
  end

  if db.enabled ~= nil and p.enabled == true then
    p.enabled = db.enabled
  end

  if type(db.fallback) == "table" then
    p.fallback = db.fallback
    ROGU_EnsureFallbackDefaultsOn(p.fallback)
  end

  db.slots = nil
  db.enabled = nil
  db.fallback = nil

  p._migrated = true
end

local function ROGU_EnsureProfile(db)
  local key = ROGU_ProfileKey()
  local p = db.profiles[key]

  if type(p) ~= "table" then
    p = {}
    db.profiles[key] = p
  end

  if p.enabled == nil then p.enabled = true end
  if type(p.slots) ~= "table" then p.slots = {} end
  if type(p.fallback) ~= "table" then p.fallback = {} end
  ROGU_EnsureFallbackDefaultsOn(p.fallback)

  if type(p.stats) ~= "table" then p.stats = {} end
  if p.stats.total == nil then p.stats.total = 0 end
  if type(p.stats.stamps) ~= "table" then p.stats.stamps = {} end
  if p.stats.head == nil then p.stats.head = 1 end
  if p.stats.lastReport == nil then p.stats.lastReport = 0 end

  ROGU_MigrateLegacyRootToProfile(db, p)

  return p, key
end

-------------------------------------------------
-- [2.4] Emote IDs sanitize + pick
-------------------------------------------------
local function ROGU_FindEmoteID(db, token)
  token = U.upper(token)
  if token == "" then return nil end

  for i = 1, #(db.emotes or {}) do
    local e = db.emotes[i]
    if type(e) == "table" and type(e.emote) == "string" and U.upper(e.emote) == token then
      return i
    end
  end

  return nil
end

local function ROGU_SanitizeEmoteIDs(cfg, db)
  if type(cfg) ~= "table" then return end
  if type(cfg.emoteIDs) ~= "table" then cfg.emoteIDs = {} end

  local maxID = #(db.emotes or {})
  if maxID < 1 then
    ROGU_EnsureEmoteDefaults(db)
    maxID = #db.emotes
  end

  local out, seen = {}, {}

  for i = 1, #cfg.emoteIDs do
    local id = tonumber(cfg.emoteIDs[i])
    if id and id >= 1 and id <= maxID and not seen[id] then
      table.insert(out, id)
      seen[id] = true
    end
  end

  if #out < 1 then out[1] = 1 end
  cfg.emoteIDs = out
end

local function ROGU_PickEmoteForCfg(cfg)
  local db = ROGU_EnsureDB()
  local ids = cfg and cfg.emoteIDs

  if type(ids) ~= "table" or #ids < 1 then ids = { 1 } end

  local id = tonumber(ids[math.random(1, #ids)]) or 1
  local entry = db.emotes and db.emotes[id]
  local token = entry and entry.emote or "ROAR"

  token = U.upper(token)
  if token == "" then token = "ROAR" end
  return token
end

-------------------------------------------------
-- [2.4.9] Forward declarations for stats
-------------------------------------------------
local ROGU_StatsRecordEmote
local ROGU_StatsPerMinuteLastHour
local ROGU_StatsMaybeHourlyReport_OnActivity

-------------------------------------------------
-- [2.5] Load Once
-------------------------------------------------
local function ROGU_LoadOnce()
  if ROGU._loaded then return end

  local db = ROGU_EnsureDB()
  local profile, key = ROGU_EnsureProfile(db)

  ROGU.profileKey = key
  ROGU.profile = profile
  ROGU.slots = profile.slots
  ROGU.fallback = profile.fallback
  ROGU.enabled = profile.enabled
  ROGU.stats = profile.stats

  for _, cfg in pairs(ROGU.slots) do
    if type(cfg) == "table" then
      if cfg.chance == nil then cfg.chance = 100 end
      if cfg.cd == nil then cfg.cd = 6 end
      if cfg.last == nil then cfg.last = 0 end
      if type(cfg.emoteIDs) ~= "table" or #cfg.emoteIDs < 1 then cfg.emoteIDs = { 1 } end
      ROGU_SanitizeEmoteIDs(cfg, db)
    end
  end

  ROGU_SanitizeEmoteIDs(ROGU.fallback, db)
  ROGU._loaded = true
end

local function ROGU_SyncToProfile()
  if not ROGU.profile then return end
  ROGU.profile.enabled = ROGU.enabled
  ROGU.profile.slots = ROGU.slots
  ROGU.profile.fallback = ROGU.fallback
  ROGU.profile.stats = ROGU.stats
end

-------------------------------------------------
-- [2.6] Features
-------------------------------------------------
local function ROGU_SendInvite(channelNum)
  local msg = U.pick(inviteText)
  if not msg or msg == "" then return end

  local ch = tonumber(channelNum) or 1
  if ch < 1 then ch = 1 end
  if ch > 10 then ch = 10 end

  SendChatMessage(msg, "CHANNEL", nil, ch)
end

local function ROGU_DoBattleEmoteForCfg(cfg, now)
  if not ROGU.enabled or type(cfg) ~= "table" then return end

  cfg.last = cfg.last or 0
  if now - cfg.last < (cfg.cd or 0) then return end
  cfg.last = now

  if math.random(1, 100) <= (cfg.chance or 0) then
    local token = ROGU_PickEmoteForCfg(cfg)
    performEmote(token)
    ROGU.lastRoar = now

    if ROGU_StatsRecordEmote then
      ROGU_StatsRecordEmote()
    end
  end
end

local function ROGU_TryFallback(now, slot)
  if not ROGU.enabled then return end

  local fb = ROGU.fallback
  if type(fb) ~= "table" then return end
  if fb.enabled == false then return end
  if not slot or slot < 1 or slot > 200 then return end

  fb.last = fb.last or 0
  if now - fb.last < (fb.cd or 0) then return end

  local perm = tonumber(fb.chancePermille) or 0
  if perm < 0 then perm = 0 end
  if perm > 1000 then perm = 1000 end

  if math.random(1, 1000) <= perm then
    local token = ROGU_PickEmoteForCfg(fb)
    performEmote(token)
    ROGU.lastRoar = now
    fb.last = now

    if ROGU_StatsRecordEmote then
      ROGU_StatsRecordEmote()
    end
  end
end

local function ROGU_MaybeReminder(now)
  if not ROGU.enabled then return end

  if ROGU.lastRoar > 0 then
    if now - ROGU.lastRoar >= ROAR_REMINDER_INTERVAL and now - (ROGU.lastReminder or 0) >= ROAR_REMINDER_CD then
      roarChat("You have not roared in a while.")
      ROGU.lastReminder = now
    end
  end
end

local function ROGU_ReportRestedXP()
  local r = GetXPExhaustion and GetXPExhaustion()
  if not r then
    roarChat("No rest.")
    return
  end

  local m = UnitXPMax("player")
  if not m or m == 0 then
    roarChat("No XP data.")
    return
  end

  local bubbles = math.floor((r * 20) / m + 0.5)
  if bubbles > 30 then bubbles = 30 end

  roarChat("Rest: " .. bubbles .. " bubbles (" .. r .. " XP)")
end

-------------------------------------------------
-- [2.7] Stats
-------------------------------------------------
local STATS_WINDOW = 3600
local STATS_REPORT_INTERVAL = 3600

local function ROGU_Now()
  if time then return time() end
  return math.floor(GetTime())
end

local function ROGU_StatsPrune(now)
  local s = ROGU.stats
  if type(s) ~= "table" or type(s.stamps) ~= "table" then return end

  local cutoff = now - STATS_WINDOW
  local stamps = s.stamps
  local head = tonumber(s.head) or 1
  if head < 1 then head = 1 end

  while stamps[head] and stamps[head] <= cutoff do
    head = head + 1
  end

  s.head = head

  local n = #stamps
  if head > 50 and head > math.floor(n / 2) then
    local out = {}
    local j = 1

    for i = head, n do
      out[j] = stamps[i]
      j = j + 1
    end

    s.stamps = out
    s.head = 1
  end
end

local function ROGU_StatsCountLastHour()
  local s = ROGU.stats
  if type(s) ~= "table" or type(s.stamps) ~= "table" then return 0 end

  local n = #s.stamps
  local head = tonumber(s.head) or 1
  if head < 1 then head = 1 end

  local c = n - head + 1
  if c < 0 then c = 0 end
  return c
end

ROGU_StatsRecordEmote = function()
  local s = ROGU.stats
  if type(s) ~= "table" then return end

  local now = ROGU_Now()

  if type(s.stamps) ~= "table" then s.stamps = {} end
  if s.head == nil then s.head = 1 end
  if s.total == nil then s.total = 0 end

  s.total = s.total + 1
  table.insert(s.stamps, now)

  ROGU_StatsPrune(now)
end

ROGU_StatsPerMinuteLastHour = function()
  local now = ROGU_Now()
  ROGU_StatsPrune(now)
  return ROGU_StatsCountLastHour() / 60
end

ROGU_StatsMaybeHourlyReport_OnActivity = function()
  local s = ROGU.stats
  if type(s) ~= "table" then return end

  local now = ROGU_Now()
  ROGU_StatsPrune(now)

  s.lastReport = tonumber(s.lastReport) or 0
  if s.lastReport == 0 then
    s.lastReport = now
    return
  end

  if now - s.lastReport < STATS_REPORT_INTERVAL then return end

  local count = ROGU_StatsCountLastHour()
  local perMin = count / 60
  local total = tonumber(s.total) or 0

  roarChat("total roars: " .. tostring(total) .. " | last hour: " .. tostring(count) .. " (" .. string.format("%.1f", perMin) .. " per minute)")
  s.lastReport = now
end

-------------------------------------------------
-- [3] UseAction Hook
-------------------------------------------------
local function ROGU_OnUseAction(slot, checkCursor, onSelf)
  ROGU_LoadOnce()

  local now = GetTime()
  slot = tonumber(slot)

  if ROGU.watchMode then
    roarChat("pressed slot " .. tostring(slot))
  end

  for _, cfg in pairs(ROGU.slots or {}) do
    if type(cfg) == "table" and cfg.slot == slot then
      ROGU_DoBattleEmoteForCfg(cfg, now)
    end
  end

  ROGU_TryFallback(now, slot)
  ROGU_MaybeReminder(now)

  if ROGU_StatsMaybeHourlyReport_OnActivity then
    ROGU_StatsMaybeHourlyReport_OnActivity()
  end
end

if hooksecurefunc then
  hooksecurefunc("UseAction", ROGU_OnUseAction)
else
  local _Orig_UseAction = UseAction
  function UseAction(slot, checkCursor, onSelf)
    local result = _Orig_UseAction(slot, checkCursor, onSelf)
    ROGU_OnUseAction(slot, checkCursor, onSelf)
    return result
  end
end

-------------------------------------------------
-- [4] Slash Commands: /rogu
-------------------------------------------------
SLASH_ROGU1 = "/rogu"
SlashCmdList["ROGU"] = function(raw)
  ROGU_LoadOnce()
  local db = ROGU_EnsureDB()

  local cmd, rest = U.split_cmd(raw)
  cmd = U.upper(cmd)

  if cmd == "" or cmd == "HELP" then
    roarChat("invite <1-10> | slotX <n> | chanceX <0-100> | timerX <sec> | fallback chance <0-1000> | fallback timer <sec> | emote <TOKEN> | emote list | emoteX <id|-id|clear|list> | watch | info | reset | resetcd | on | off | rexp | roar")
    return
  end

  if cmd == "INFO" then
    roarChat("version: " .. ADDON_VERSION)
    roarChat("profile: " .. tostring(ROGU.profileKey or "?"))
    roarChat("enabled: " .. tostring(ROGU.enabled))
    roarChat("emotes in DB: " .. tostring(#db.emotes))

    local s = ROGU.stats
    if type(s) ~= "table" then
      roarChat("stats: not initialized")
    else
      local total = tonumber(s.total) or 0
      local perMin = 0
      if ROGU_StatsPerMinuteLastHour then
        perMin = ROGU_StatsPerMinuteLastHour()
      end
      roarChat("total roars: " .. tostring(total))
      roarChat("last hour: " .. string.format("%.1f", perMin) .. " per minute")
    end

    if type(ROGU.fallback) == "table" then
      local fb = ROGU.fallback
      ROGU_SanitizeEmoteIDs(fb, db)

      local fbids = table.concat(fb.emoteIDs or { 1 }, ",")
      if fbids == "" then fbids = "1" end

      roarChat("fallback: enabled " .. tostring(fb.enabled) .. " | cd " .. tostring(fb.cd) .. "s | chance " .. tostring(fb.chancePermille) .. "/1000 | emotes [" .. fbids .. "]")
    end

    for i, cfg in pairs(ROGU.slots or {}) do
      if type(cfg) == "table" then
        ROGU_SanitizeEmoteIDs(cfg, db)
        local ids = table.concat(cfg.emoteIDs or { 1 }, ",")
        if ids == "" then ids = "1" end
        roarChat("instance" .. tostring(i) .. ": slot " .. tostring(cfg.slot) .. " | chance " .. tostring(cfg.chance) .. "% | cd " .. tostring(cfg.cd) .. "s | emotes [" .. ids .. "]")
      end
    end

    return
  end

  if cmd == "ON" then
    ROGU.enabled = true
    ROGU_SyncToProfile()
    roarChat("enabled")
    return
  end

  if cmd == "OFF" then
    ROGU.enabled = false
    ROGU_SyncToProfile()
    roarChat("disabled")
    return
  end

  if cmd == "INVITE" then
    local ch = U.trim(rest or "")
    if ch == "" then ch = "1" end
    ROGU_SendInvite(ch)
    return
  end

  if cmd == "ROAR" then
    performEmote("ROAR")
    if ROGU_StatsRecordEmote then
      ROGU_StatsRecordEmote()
    end
    ROGU.lastRoar = GetTime()
    return
  end

  if cmd == "REXP" then
    ROGU_ReportRestedXP()
    return
  end

  if cmd == "WATCH" then
    ROGU.watchMode = not ROGU.watchMode
    roarChat("watch mode " .. (ROGU.watchMode and "ON" or "OFF"))
    return
  end

  if cmd == "FALLBACK" then
    local sub, subrest = U.split_cmd(rest or "")
    sub = U.upper(sub)

    local fb = ROGU.fallback
    if type(fb) ~= "table" then
      fb = {}
      ROGU.fallback = fb
      ROGU_EnsureFallbackDefaultsOn(fb)
    end

    if sub == "CHANCE" then
      local n = tonumber(subrest)
      if n and n >= 0 and n <= 1000 then
        fb.chancePermille = n
        ROGU_SyncToProfile()
        roarChat("fallback chance " .. tostring(n) .. "/1000")
      else
        roarChat("usage: /rogu fallback chance <0-1000>")
      end
      return
    end

    if sub == "TIMER" then
      local n = tonumber(subrest)
      if n and n >= 0 then
        fb.cd = n
        ROGU_SyncToProfile()
        roarChat("fallback cooldown " .. tostring(n) .. "s")
      else
        roarChat("usage: /rogu fallback timer <sec>")
      end
      return
    end

    roarChat("usage: /rogu fallback chance <0-1000> | /rogu fallback timer <sec>")
    return
  end

  local slotIndex = string.match(cmd, "^SLOT(%d+)$")
  if slotIndex then
    local instance = tonumber(slotIndex)
    local slot = tonumber(rest)

    if instance and slot then
      ROGU.slots[instance] = ROGU.slots[instance] or { emoteIDs = { 1 } }
      local cfg = ROGU.slots[instance]

      cfg.slot = slot
      cfg.chance = cfg.chance or 100
      cfg.cd = cfg.cd or 6
      cfg.last = 0

      ROGU_SanitizeEmoteIDs(cfg, db)
      ROGU_SyncToProfile()
      roarChat("instance" .. tostring(instance) .. " watching slot " .. tostring(slot))
    else
      roarChat("usage: /rogu slotX <slot>")
    end
    return
  end

  local chanceIndex = string.match(cmd, "^CHANCE(%d+)$")
  if chanceIndex then
    local instance = tonumber(chanceIndex)
    local n = tonumber(rest)

    if ROGU.slots[instance] and n and n >= 0 and n <= 100 then
      ROGU.slots[instance].chance = n
      ROGU_SyncToProfile()
      roarChat("instance" .. tostring(instance) .. " chance " .. tostring(n) .. "%")
    else
      roarChat("invalid instance or value")
    end
    return
  end

  local timerIndex = string.match(cmd, "^TIMER(%d+)$")
  if timerIndex then
    local instance = tonumber(timerIndex)
    local n = tonumber(rest)

    if ROGU.slots[instance] and n and n >= 0 then
      ROGU.slots[instance].cd = n
      ROGU_SyncToProfile()
      roarChat("instance" .. tostring(instance) .. " cooldown " .. tostring(n) .. "s")
    else
      roarChat("invalid instance or value")
    end
    return
  end

  if cmd == "EMOTE" then
    local sub = U.upper(rest)

    if sub == "LIST" then
      for i = 1, #(db.emotes or {}) do
        local token = type(db.emotes[i]) == "table" and db.emotes[i].emote or ""
        token = U.upper(token)
        if token == "" then token = "?" end
        roarChat(tostring(i) .. ": " .. token)
      end
      return
    end

    local token = U.upper(rest)
    if token == "" then
      roarChat("usage: /rogu emote <TOKEN> | /rogu emote list")
      return
    end

    local existing = ROGU_FindEmoteID(db, token)
    if existing then
      roarChat("emote exists: " .. tostring(existing) .. ": " .. token)
      return
    end

    local id = #db.emotes + 1
    db.emotes[id] = { emote = token }
    roarChat("added emote " .. tostring(id) .. ": " .. token)

    for _, cfg in pairs(ROGU.slots or {}) do
      ROGU_SanitizeEmoteIDs(cfg, db)
    end
    ROGU_SanitizeEmoteIDs(ROGU.fallback, db)
    ROGU_SyncToProfile()
    return
  end

  local emoteIndex = string.match(cmd, "^EMOTE(%d+)$")
  if emoteIndex then
    local instance = tonumber(emoteIndex)
    if not instance then
      roarChat("invalid instance")
      return
    end

    ROGU.slots[instance] = ROGU.slots[instance] or { slot = nil, chance = 100, cd = 6, last = 0, emoteIDs = { 1 } }
    local cfg = ROGU.slots[instance]
    local arg = U.trim(rest or "")

    if arg == "" then
      roarChat("usage: /rogu emote" .. tostring(instance) .. " <id|-id|clear|list>")
      return
    end

    local lowerArg = string.lower(arg)

    if lowerArg == "clear" then
      cfg.emoteIDs = { 1 }
      ROGU_SyncToProfile()
      roarChat("instance" .. tostring(instance) .. " emotes set to: 1")
      return
    end

    if lowerArg == "list" then
      ROGU_SanitizeEmoteIDs(cfg, db)
      local out = ""

      for i = 1, #(cfg.emoteIDs or {}) do
        local id = cfg.emoteIDs[i]
        local tok = db.emotes[id] and db.emotes[id].emote or "ROAR"
        if out ~= "" then out = out .. " | " end
        out = out .. tostring(id) .. ":" .. U.upper(tok)
      end

      roarChat("instance" .. tostring(instance) .. " emotes: " .. out)
      return
    end

    local remove = false
    if string.sub(arg, 1, 1) == "-" then
      remove = true
      arg = U.trim(string.sub(arg, 2))
    end

    local id = tonumber(arg)
    local maxID = #db.emotes

    if not id or id < 1 or id > maxID then
      roarChat("invalid emote id (1-" .. tostring(maxID) .. ")")
      return
    end

    ROGU_SanitizeEmoteIDs(cfg, db)

    if remove then
      local new = {}
      for i = 1, #cfg.emoteIDs do
        if cfg.emoteIDs[i] ~= id then
          table.insert(new, cfg.emoteIDs[i])
        end
      end
      if #new < 1 then new[1] = 1 end
      cfg.emoteIDs = new
      roarChat("instance" .. tostring(instance) .. " removed emote id " .. tostring(id))
    else
      if U.arrayHas(cfg.emoteIDs, id) then
        roarChat("instance" .. tostring(instance) .. " already has emote id " .. tostring(id))
      else
        table.insert(cfg.emoteIDs, id)
        roarChat("instance" .. tostring(instance) .. " added emote id " .. tostring(id))
      end
    end

    ROGU_SyncToProfile()
    return
  end

  if cmd == "RESET" then
    ROGU.slots = {}
    if ROGU.profile then
      ROGU.profile.slots = ROGU.slots
    end
    ROGU_SyncToProfile()
    roarChat("all instances cleared")
    return
  end

  if cmd == "RESETCD" then
    for _, cfg in pairs(ROGU.slots or {}) do
      if type(cfg) == "table" then
        cfg.last = 0
      end
    end

    if type(ROGU.fallback) == "table" then
      ROGU.fallback.last = 0
    end

    ROGU.lastRoar = 0
    ROGU.lastReminder = 0

    ROGU_SyncToProfile()
    roarChat("cooldowns reset")
    return
  end

  roarChat("invite <1-10> | slotX <n> | chanceX <0-100> | timerX <sec> | fallback chance <0-1000> | fallback timer <sec> | emote <TOKEN> | emote list | emoteX <id|-id|clear|list> | watch | info | reset | resetcd | on | off | rexp | roar")
end

-------------------------------------------------
-- [5] Init / Save
-------------------------------------------------
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_LOGOUT")

f:SetScript("OnEvent", function(self, event)
  if event == "PLAYER_LOGIN" then
    math.randomseed(math.floor(GetTime() * 1000))
    math.random()

    ROGU_LoadOnce()

    for _, cfg in pairs(ROGU.slots or {}) do
      if type(cfg) == "table" then
        cfg.last = 0
      end
    end

    if type(ROGU.fallback) == "table" then
      ROGU.fallback.last = 0
    end

    ROGU.lastRoar = 0
    ROGU.lastReminder = 0

    ROGU_SyncToProfile()
    roarChat("loaded v" .. ADDON_VERSION .. " for " .. tostring(ROGU.profileKey or "?"))
  elseif event == "PLAYER_LOGOUT" then
    ROGU_SyncToProfile()
  end
end)
