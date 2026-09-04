-- Loaded directly by the engine before edict allocation.
-- This is not a requireable Lua module.

---@class quake_globals
---@field movedist number
---@field gameover number
---@field string_null string
---@field activator entity?
---@field damage_attacker entity?
---@field damage_inflictor entity?
---@field framecount number
---@field skill number
---@field sight_entity entity?
---@field sight_entity_time number
---@field le1 entity?
---@field le2 entity?
---@field lightning_end number
---@field modelindex_eyes number
---@field modelindex_player number
---@field intermission_running number
---@field intermission_exittime number
---@field nextmap string
---@field enemy_vis boolean
---@field enemy_infront boolean
---@field enemy_range number
---@field enemy_yaw number
---@field hknight_type number
---@field shub entity?
---@field lastspawn entity?
---@field bodyque_head entity?

---@type quake_defs
local globals = {
    movedist = "float",
    gameover = "float",
    string_null = "string",
    activator = "entity",
    damage_attacker = "entity",
    damage_inflictor = "entity",
    framecount = "float",
    skill = "float",

    -- ai
    sight_entity = "entity",
    sight_entity_time = "float",

    -- boss
    le1 = "entity",
    le2 = "entity",
    lightning_end = "float",

    -- client
    modelindex_eyes = "float",
    modelindex_player = "float",
    intermission_running = "float",
    intermission_exittime = "float",
    nextmap = "string",

    -- fight
    enemy_vis = "bool",
    enemy_infront = "bool",
    enemy_range = "float",
    enemy_yaw = "float",

    -- hknight
    hknight_type = "float",

    -- oldone
    shub = "entity",

    -- world
    lastspawn = "entity",
    bodyque_head = "entity",
}

---@class entity
---@field wad string
---@field map string
---@field worldtype number
---@field killtarget string
---@field light_lev number
---@field style number
---@field th_stand think_callback?
---@field th_walk think_callback?
---@field th_run think_callback?
---@field th_missile think_callback?
---@field th_melee think_callback?
---@field th_pain pain_callback?
---@field th_die die_callback?
---@field oldenemy entity?
---@field speed number
---@field lefty number
---@field search_time number
---@field attack_state number
---@field walkframe number
---@field attack_finished number
---@field pain_finished number
---@field invincible_finished number
---@field invisible_finished number
---@field super_damage_finished number
---@field radsuit_finished number
---@field invincible_time number
---@field invincible_sound number
---@field invisible_time number
---@field invisible_sound number
---@field super_time number
---@field super_sound number
---@field rad_time number
---@field fly_sound number
---@field axhitme number
---@field show_hostile number
---@field jump_flag number
---@field swim_flag number
---@field air_finished number
---@field bubble_count number
---@field deathtype string
---@field mdl string
---@field mangle vec3
---@field t_length number
---@field t_width number
---@field dest vec3
---@field dest1 vec3
---@field dest2 vec3
---@field wait number
---@field delay number
---@field trigger_field entity?
---@field noise4 string
---@field pausetime number
---@field movetarget entity?
---@field aflag number
---@field dmg number
---@field cnt number
---@field think1 think_callback?
---@field finaldest vec3
---@field finalangle vec3
---@field count number
---@field lip number
---@field state number
---@field pos1 vec3
---@field pos2 vec3
---@field height number
---@field waitmin number
---@field waitmax number
---@field distance number
---@field volume number
---@field dmgtime number
---@field healamount number
---@field healtype number
---@field inpain number

---@type quake_defs
local entity_fields = {
    wad = "string",
    map = "string",
    worldtype = "float",
    killtarget = "string",
    light_lev = "float",
    style = "float",
    th_stand = "function",
    th_walk = "function",
    th_run = "function",
    th_missile = "function",
    th_melee = "function",
    th_pain = "function",
    th_die = "function",
    oldenemy = "entity",
    speed = "float",
    lefty = "float",
    search_time = "float",
    attack_state = "float",
    walkframe = "float",
    attack_finished = "float",
    pain_finished = "float",
    invincible_finished = "float",
    invisible_finished = "float",
    super_damage_finished = "float",
    radsuit_finished = "float",
    invincible_time = "float",
    invincible_sound = "float",
    invisible_time = "float",
    invisible_sound = "float",
    super_time = "float",
    super_sound = "float",
    rad_time = "float",
    fly_sound = "float",
    axhitme = "float",
    show_hostile = "float",
    jump_flag = "float",
    swim_flag = "float",
    air_finished = "float",
    bubble_count = "float",
    deathtype = "string",
    mdl = "string",
    mangle = "vector",
    t_length = "float",
    t_width = "float",
    dest = "vector",
    dest1 = "vector",
    dest2 = "vector",
    wait = "float",
    delay = "float",
    trigger_field = "entity",
    noise4 = "string",
    pausetime = "float",
    movetarget = "entity",
    aflag = "float",
    dmg = "float",
    cnt = "float",
    think1 = "function",
    finaldest = "vector",
    finalangle = "vector",
    count = "float",
    lip = "float",
    state = "float",
    pos1 = "vector",
    pos2 = "vector",
    height = "float",
    waitmin = "float",
    waitmax = "float",
    distance = "float",
    volume = "float",

    -- client
    dmgtime = "float",

    -- items
    healamount = "float",
    healtype = "float",

    -- zombie
    inpain = "float",
}

return globals, entity_fields
