factions = {}

--utility function 
function table.contains(tbl, val)
    for _, v in ipairs(tbl) do
        if v == val then return true end
    end
    return false
end


factions.invite_queqe = {}
--factions.join_requests = {}

local storage = minetest.get_mod_storage()
--factions structure = {
    --faction_name = {
        --members = {},
        --owner = ""
    --},
--}
function factions.save_data(data)
    if type(data) == "table" then
        storage:set_string("faction_data", minetest.serialize(data))
    end
end

function factions.load_data()
    local faction_data = storage:get_string("faction_data")
    if faction_data then
        faction_data = minetest.deserialize(faction_data)
        --extra check needed
        if type(faction_data) ~= "table" then
            faction_data = {} 
        end
    else 
        faction_data = {}
    end
    return faction_data
end

--store data in ram
local faction_data = factions.load_data()

--return false if player is in no faction
function factions.is_player_in(name)
    local trigger = false
    local fname = nil
    --if not next()
    for faction, cat in pairs(faction_data) do  
        for catname, value in pairs(cat) do
            if catname == "members" then
                for _, member in pairs(value) do
                    if member == name then
                        fname = faction
                        trigger = true
                        break
                    end
                end
            end
        end
    end
    return trigger, fname
end

--helper func
function factions.is_faction_exist(fname)
    for k, _ in pairs(faction_data) do
        if k == fname then
            return true
        end
    end
    return false
end

-- faction create function
function factions.create_faction(name, fname) 
    if factions.is_player_in(name) == true then
        minetest.chat_send_player(name, "[Server] You are already in a faction")
        return
    end
    if factions.is_faction_exist(fname) == true then
        minetest.chat_send_player(name, "[Server] Sorry but this faction already exists")
        return
    end

    faction_data[fname] = {
        members = {name},
        owner = name,
        staffs = {}           
    }    

    minetest.chat_send_player(name, "[Server] Faction '" .. fname .. "' created successfully!")

end

-- faction leave function
function factions.leave_faction(name)
    local is_in, fname = factions.is_player_in(name) 
    if is_in == false then
        minetest.chat_send_player(name, "[Server] You are not in any faction")
        return
    end
    for i, mname in ipairs(faction_data[fname].members) do
        if mname == name then  
            table.remove(faction_data[fname].members, i)
        end
    end
    --are there any players left?
    if next(faction_data[fname].members) then
        if faction_data[fname].owner == name then
            minetest.chat_send_player(name, "[Server] You must transfer ownership before leaving. Use /faction_changeowner <playername>")
            return
        end
    else
        minetest.chat_send_player(name, "[Server] Deleted your faction")
        faction_data[fname] = nil
    end
    minetest.chat_send_player(name, "[Server] You left your faction "..fname)
end

-- faction invite function
function factions.invite_player(name, invited_person)
    local is_in, fname = factions.is_player_in(name)
    if is_in == false then
        minetest.chat_send_player(name, "[Server] You are not in any faction")
        return 
    end

    if #faction_data[fname].members >= 50 then
        minetest.chat_send_player(name, "[Server] Your faction has reached 50 member max limit.")
        return
    end
    
    if factions.is_player_in(invited_person) == true then
        minetest.chat_send_player(name, "[Server] This user is already in a faction")
        return
    end
    minetest.chat_send_player(name, "[Server] You have invited "..invited_person.." to join "..fname.." faction")
    minetest.chat_send_player(invited_person, "[Server] You have been invite by "..name.." to join "..fname.." to accept type /faction_accept")
    factions.invite_queqe[invited_person] = fname
end
   
-- faction invite_accept function
function factions.invite_accept(name) 
    if factions.is_player_in(name) == true then
        minetest.chat_send_player(name, "[Server] You are already in a faction")
        factions.invite_queqe[name] = nil 
        return
    end

    if factions.invite_queqe[name] == nil then
       minetest.chat_send_player(name, "[Server] There is no invite in you queue")
       return  
    end

    local fname = factions.invite_queqe[name]

    if #faction_data[fname].members >= 50 then
        minetest.chat_send_player(name, "[Server] Sorry, "..fname.." faction is full (50 members max).")
        return
    end

    table.insert(faction_data[factions.invite_queqe[name]].members, name)
    minetest.chat_send_player(name, "[Server] You have joined the faction "..factions.invite_queqe[name])
    factions.invite_queqe[name] = nil
end

-- faction kick_player function
function factions.kick_player(name, kicked_person)
    local is_in, fname = factions.is_player_in(name)
    if not is_in then
        return minetest.chat_send_player(name, "[Server] You are not in a faction.")
    end

    local faction = faction_data[fname]
    local is_owner = (faction.owner == name)
    local is_staff = table.contains(faction.staffs or {}, name)

    if not is_owner and not is_staff then
        return minetest.chat_send_player(name, "[Server] Only the faction owner or staff can kick members.")
    end

    if kicked_person == faction.owner then
        return minetest.chat_send_player(name, "[Server] You cannot kick the owner of the faction.")
    end

    if table.contains(faction.staffs or {}, kicked_person) and not is_owner then
        return minetest.chat_send_player(name, "[Server] You cannot kick another staff member.")
    end

    local found = false
    for i, mname in ipairs(faction.members) do
        if mname == kicked_person then
            table.remove(faction.members, i)
            found = true
            break
        end
    end

    if found then
        for i, sname in ipairs(faction.staffs or {}) do
            if sname == kicked_person then
                table.remove(faction.staffs, i)
                break
            end
        end
        minetest.chat_send_player(name, "[Server] Kicked "..kicked_person.." from the faction.")
        minetest.chat_send_player(kicked_person, "[Server] You were kicked from the faction "..fname)
    else
        minetest.chat_send_player(name, "[Server] Player is not in your faction.")
    end
end

-- faction change_owner function
function factions.change_owner(name, new_owner)
    local is_in, fname = factions.is_player_in(name)
    if not is_in then
        return minetest.chat_send_player(name, "[Server] You are not in any faction")
    end

    if faction_data[fname].owner ~= name then
        return minetest.chat_send_player(name, "[Server] Only the owner can transfer ownership")
    end

    if name == new_owner then
        return minetest.chat_send_player(name, "[Server] You are already the owner.")
    end

    local is_target_in_faction = false
    for _, member in pairs(faction_data[fname].members) do
        if member == new_owner then
            is_target_in_faction = true
            break
        end
    end

    if not is_target_in_faction then
        return minetest.chat_send_player(name, "[Server] That player is not in your faction")
    end

    faction_data[fname].owner = new_owner
    minetest.chat_send_player(name, "[Server] Ownership transferred to "..new_owner)
    minetest.chat_send_player(new_owner, "[Server] You are now the owner of faction "..fname)

    for _, mname in ipairs(faction_data[fname].members) do
        if mname ~= name and mname ~= new_owner then
            minetest.chat_send_player(mname, "[Server] "..name.." has transferred ownership to "..new_owner.." in faction "..fname)
        end
    end
end

-- faction disband function
function factions.disband_faction(name)
    local is_in, fname = factions.is_player_in(name)
    if not is_in then
        minetest.chat_send_player(name, "[Server] You are not in any faction.")
        return
    end

    if faction_data[fname].owner ~= name then
        minetest.chat_send_player(name, "[Server] Only the faction owner can disband the faction.")
        return
    end

    for _, member in ipairs(faction_data[fname].members) do
        minetest.chat_send_player(member, "[Server] Faction '"..fname.."' has been disbanded by the owner.")
    end

    faction_data[fname] = nil
    minetest.chat_send_player(name, "[Server] You have disbanded the faction.")
end

-- helper func
function factions.is_staff(fname, player)
    local faction = faction_data[fname]
    if not faction or not faction.staffs then return false end
    return table.contains(faction.staffs, player)
end

-- faction rankup function
function factions.rank_up_player(name, target)
    local is_in, fname = factions.is_player_in(name)
    if not is_in then return minetest.chat_send_player(name, "[Server] You are not in a faction") end

    local faction = faction_data[fname]
    if faction.owner ~= name then
        return minetest.chat_send_player(name, "[Server] Only the owner can promote staff")
    end

    if not table.contains(faction.members, target) then
        return minetest.chat_send_player(name, "[Server] That player is not in your faction")
    end

    if factions.is_staff(fname, target) then
        return minetest.chat_send_player(name, "[Server] This player is already a staff member")
    end

    if not faction.staffs then
        faction.staffs = {}
    end

    table.insert(faction.staffs, target)
    minetest.chat_send_player(name, "[Server] Promoted "..target.." to staff.")
    minetest.chat_send_player(target, "[Server] You have been promoted to staff of "..fname)
end

-- faction rankdown function
function factions.rank_down_player(name, target)
    local is_in, fname = factions.is_player_in(name)
    if not is_in then return minetest.chat_send_player(name, "[Server] You are not in a faction") end

    local faction = faction_data[fname]
    if faction.owner ~= name then
        return minetest.chat_send_player(name, "[Server] Only the owner can demote staff")
    end

    for i, staff in ipairs(faction.staffs) do
        if staff == target then
            table.remove(faction.staffs, i)
            minetest.chat_send_player(name, "[Server] Demoted "..target.." from staff.")
            minetest.chat_send_player(target, "[Server] You have been removed from staff of "..fname)
            return
        end
    end

    minetest.chat_send_player(name, "[Server] That player is not a staff member")
end

-- Auto save_data
minetest.register_on_shutdown(function() 
    factions.save_data(faction_data)
end)
local timer = 0
minetest.register_globalstep(function(dtime)
    timer = timer +dtime 
    if timer == 3600 then
       factions.save_data(faction_data)
       timer = 0
    end
end)

-- CHAT COMMANDS AND MORE

minetest.register_chatcommand("faction_create", {
    description = "/faction_create <faction_name> creates a faction",
    params = "<faction_name>",
    privs = {interact=true},
    func = function(name, param)
        if param == "" then
            minetest.chat_send_player(name, "Usage: /faction_create <faction_name>")
            return true
        end
        factions.create_faction(name, param)
    end
})

minetest.register_chatcommand("faction_leave", {
    description = "/faction_leave leave a faction",
    privs = {interact=true},
    func = function(name, param)
        factions.leave_faction(name)
    end
})


minetest.register_chatcommand("faction_invite", {
    description = "/faction_invite <playername> invite others to your faction",
    params = "<playername>",
    privs = {interact=true},
    func = function(name, param)
        if minetest.get_player_by_name(param) == nil then
           minetest.chat_send_player(name, "[Server] Player has to be online")
           return 
        end
        factions.invite_player(name, param)
    end
})

minetest.register_chatcommand("faction_accept", {
    description = "/faction_accept accept a faction invite",
    privs = {interact=true},
    func = function(name, param)
        factions.invite_accept(name) 
    end
})

minetest.register_chatcommand("faction_kick", {
    description = "/faction_kick <playername> kicks a player from your faction",
    params = "<playername>",
    privs = {interact=true},
    func = function(name, param)
        if param == "" then
            minetest.chat_send_player(name, "Usage: /faction_kick <playername>")
            return true
        end
        factions.kick_player(name, param)
    end
})

local function format_player_status(name)
    if minetest.get_player_by_name(name) then
        return name .. " (Online)"
    else
        return name .. " (Offline)"
    end
end

local function get_owner_and_staff_list(param)
    local faction = faction_data[param]
    if not faction then return {} end

    local function status_label(name, role)
        local label = name .. " (" .. role .. ")"
        if minetest.get_player_by_name(name) then
            label = label .. " (Online)"
        else
            label = label .. " (Offline)"
        end
        return label
    end

    local list = {}
    table.insert(list, status_label(faction.owner, "Owner"))

    if faction.staffs then
        for _, staff in ipairs(faction.staffs) do
            if staff ~= faction.owner then
                table.insert(list, status_label(staff, "Staff"))
            end
        end
    end

    return list
end

--[[
local function get_member_list(param)
    local faction = faction_data[param]
    if not faction then return {} end
    return faction.members
end 
--]]

local function get_member_list(param)
    local faction = faction_data[param]
    if not faction then return {} end

    local clean_members = {}
    for _, member in ipairs(faction.members) do
        if member ~= faction.owner and not table.contains(faction.staffs or {}, member) then
            local label = format_player_status(member)
            table.insert(clean_members, label)
        end
    end
    return clean_members
end

local function escape_list(list)
    local t = {}
    for _, v in ipairs(list) do
        table.insert(t, minetest.formspec_escape(v))
    end
    return table.concat(t, ",")
end

local function show_faction_info_formspec(player, param)
    if not player then return end
    local name = player:get_player_name()
    local total_max_players = 50

    local owner_list  = get_owner_and_staff_list(param)
    local member_list = get_member_list(param)

    local owner_opts  = escape_list(owner_list)
    local member_opts = escape_list(member_list)

    local total_players = #owner_list + #member_list
    local player_count_text = ("Number of players in the faction: %d / %d"):format(total_players, total_max_players)

    local formspec = {
        "formspec_version[4]",
        "size[12,9]",
        "background[0,0;0,0;3.png;true]",
        "tabheader[0,0;faction;Faction Info;1;true;true]",

        "label[0.3,0.5;Owner(s) & Staff(s):]",
        ("textlist[0.3,0.8;4.5,1.5;owner_list;%s;1]"):format(owner_opts),

        "label[0.3,2.7;Member(s):]",
        ("textlist[0.3,3.0;4.5,5.65;member_list;%s;1]"):format(member_opts),

        ("hypertext[6.25,1.0;11.5,3;faction_title;<style size=26><b>Faction: %s</b></style>]"):format(minetest.formspec_escape(param)),
        ("textarea[6.3,8.4;11.5,1.0;;;%s]"):format(minetest.formspec_escape(player_count_text)),
    }
    minetest.show_formspec(name, "faction_info:main", table.concat(formspec, ""))
end

minetest.register_chatcommand("faction_info", {
    description = "/faction_info <faction> returns a list of all members + the owner",
    params = "<faction>",
    privs = {interact=true},
    func = function(name, param)
        if param == "" then
            minetest.chat_send_player(name, "Usage: /faction_info <faction>")
            return 
        end
        local player = minetest.get_player_by_name(name)
        if factions.is_faction_exist(param) then
            show_faction_info_formspec(player, param)
        else
            minetest.chat_send_player(name, "Faction named " .. param .. " not found.")
        end
    end
})

local function show_faction_pinfo_formspec(player, fname)
    if not player then return end
    local faction = faction_data[fname]
    if not faction then return end

    local name = player:get_player_name()
    local total_max_players = 50

    local owner_list = { format_player_status(faction.owner) }

    local member_list = {}
    for _, member in ipairs(faction.members or {}) do
        if member ~= faction.owner then
            local label = format_player_status(member)
            if faction.staffs and table.contains(faction.staffs, member) then
                label = label .. " (Staff)"
            end
            table.insert(member_list, label)
        end
    end

    local function escape_list(list)
        local t = {}
        for _, v in ipairs(list) do
            table.insert(t, minetest.formspec_escape(v))
        end
        return table.concat(t, ",")
    end

    local total_players = #owner_list + #member_list
    local player_count_text = ("Number of players in the faction: %d / %d"):format(total_players, total_max_players)

    local formspec = {
        "formspec_version[4]",
        "size[12,9]",
        "tabheader[0,0;faction;Faction PInfo;1;true;true]",

        "label[0.3,0.5;Owner:]",
        ("textlist[0.3,0.8;3.5,1.5;owner_list;%s;1]"):format(escape_list(owner_list)),

        "label[0.3,2.7;Member(s):]",
        ("textlist[0.3,3.0;3.5,5.65;member_list;%s;1]"):format(escape_list(member_list)),

        ("hypertext[6.25,1.0;11.5,3;faction_title;<style size=26><b>Faction: %s</b></style>]"):format(minetest.formspec_escape(fname)),
        ("textarea[6.3,8.4;11.5,1.0;;;%s]"):format(minetest.formspec_escape(player_count_text)),
    }
    minetest.show_formspec(name, "faction_pinfo:main", table.concat(formspec, ""))
end

minetest.register_chatcommand("faction_pinfo", {
    description = "/faction_pinfo <playername> Shows the faction the player is in",
    params = "<playername>",
    privs = {interact=true},
    func = function(name, param)
        if param == "" then
            minetest.chat_send_player(name, "Usage: /faction_pinfo <playername>")
            return
        end
        local player = minetest.get_player_by_name(name)
        local is_in, fname = factions.is_player_in(param)
        if is_in and fname then
            show_faction_pinfo_formspec(player, fname)
        else
            minetest.chat_send_player(name, "[Server] Player '"..param.."' is not in any faction.")
        end
    end
})

minetest.register_chatcommand("f_chat", {
	description = "Send a message only to your faction members",
	params = "<message>",
	privs = {shout = true},
	func = function(name, param)
		if param == "" then
			minetest.chat_send_player(name, "Usage: /f_chat <message>")
            return true
		end

		local is_in, fname = factions.is_player_in(name)
		if not is_in then
			minetest.chat_send_player(name, "[Server] You are not in a faction.")
            return true
        end

        for i, mname in ipairs(faction_data[fname].members) do
            minetest.chat_send_player(mname, minetest.colorize("#00d9ff", "[Faction Chat] ")..name.. ": " .. param)
        end
    end,
})

minetest.register_chatcommand("faction_setbase", {
    description = "Set faction base only owner of faction can set",
    privs = {interact = true},
    func = function(name, param)
        if param ~= "" then
            minetest.chat_send_player(name, "Usage: /faction_setbase")
            return true
        end

        local is_in, fname = factions.is_player_in(name)
        if not is_in then
            minetest.chat_send_player(name, "[Server] You are not in any faction")
            return true
        end

        if faction_data[fname].owner ~= name then
            minetest.chat_send_player(name, "[Server] Only the owner can setbase")
            return true
        end
        
        local pos = minetest.get_player_by_name(name):get_pos()
        faction_data[fname].base = vector.round(pos)
        minetest.chat_send_player(name, "[Server] Faction base set at " .. minetest.pos_to_string(faction_data[fname].base))
        return true
    end,
})

minetest.register_chatcommand("faction_base", {
    description = "Teleport faction member into faction base",
    privs = {interact = true},
    func = function(name, param)
        if param ~= "" then 
            minetest.chat_send_player(name, "Usage: /faction_base")
            return true
        end

        local is_in, fname = factions.is_player_in(name)
        if not is_in then
            minetest.chat_send_player(name, "[Server] You are not in any faction")
            return true
        end

        local faction = faction_data[fname]
        if not faction or not faction_data[fname].base then
            minetest.chat_send_player(name, "[Server] Your faction has no base setted yet")
            return true
        end

        local player = minetest.get_player_by_name(name)
        if player then
            player:set_pos(faction_data[fname].base)
            minetest.chat_send_player(name, "[Server] You have teleported to your faction base")
        end
    end,
})

minetest.register_chatcommand("faction_changeowner", {
    description = "/faction_changeowner <playername> transfers faction ownership",
    params = "<playername>",
    privs = {interact=true},
    func = function(name, param)
        if param == "" then
            minetest.chat_send_player(name, "Usage: /faction_changeowner <player>")
            return
        end
        factions.change_owner(name, param)
    end
})

minetest.register_chatcommand("faction_disband", {
    description = "/faction_disband removes your faction (owner only)",
    privs = {interact = true},
    func = function(name, param)
        factions.disband_faction(name)
    end
})

minetest.register_chatcommand("faction_rankup", {
    description = "/faction_rankup <playername> Promote to staff",
    params = "<playername>",
    privs = {interact=true},
    func = function(name, param)
        if param == "" then 
            return minetest.chat_send_player(name, "Usage: /faction_rankup <playername>") end
        factions.rank_up_player(name, param)
    end
})

minetest.register_chatcommand("faction_rankdown", {
    description = "/faction_rankdown <playername> Demote staff",
    params = "<playername>",
    privs = {interact=true},
    func = function(name, param)
        if param == "" then 
            return minetest.chat_send_player(name, "Usage: /faction_rankdown <playername>") end
        factions.rank_down_player(name, param)
    end
})

minetest.register_chatcommand("f", {
    description = "Faction system, use /f <subcommand>",
    privs = {interact = true},
    params = "<subcommand> [args]",
    func = function(name, param)
        local args = param:split(" ")
        local subcommand = args[1]
        local target = args[2]

        if subcommand == "create" then
            if not target or target == "" then
                return minetest.chat_send_player(name, "Usage: /f create <faction_name>")
            end
            return minetest.chatcommands["faction_create"].func(name, target)

        elseif subcommand == "invite" then
            if not target or target == "" then
                return minetest.chat_send_player(name, "Usage: /f invite <playername>")
            end
            return minetest.chatcommands["faction_invite"].func(name, target)

        elseif subcommand == "accept" then
--            if target ~= "" then
--                return true, minetest.chat_send_player(name, "Usage: /f accept")
--            end
            return minetest.chatcommands["faction_accept"].func(name, "")

        elseif subcommand == "kick" then
            if not target or target == "" then
                return minetest.chat_send_player(name, "Usage: /f kick <playername>")
            end
            return minetest.chatcommands["faction_kick"].func(name, target)

        elseif subcommand == "leave" then
--            if target ~= "" then
--                return true, minetest.chat_send_player(name, "Usage: /f leave")
--            end
            return minetest.chatcommands["faction_leave"].func(name, "")

        elseif subcommand == "setbase" then
--            if target ~= "" then
--               return minetest.chat_send_player(name, "Usage: /f setbase")
--            end
            return minetest.chatcommands["faction_setbase"].func(name, "")

        elseif subcommand == "base" then
--            if target ~= "" then
--                return minetest.chat_send_player(name, "Usage: /f base")
--            end
            return minetest.chatcommands["faction_base"].func(name, "")

        elseif subcommand == "info" then
            if not target or target == "" then
                return minetest.chat_send_player(name, "Usage: /f info <faction_name>")
            end
            return minetest.chatcommands["faction_info"].func(name, target)

        elseif subcommand == "pinfo" then
            if not target or target == "" then
                return minetest.chat_send_player(name, "Usage: /f pinfo <playername>")
            end
            return minetest.chatcommands["faction_pinfo"].func(name, target)

        elseif subcommand == "disband" then
--            if param ~= "" then
--                return true, minetest.chat_send_player(name, "Usage: /f disband")
--            end
            return minetest.chatcommands["faction_disband"].func(name, "")

        elseif subcommand == "changeowner" then
            if not target or target == "" then
                return minetest.chat_send_player(name, "Usage: /f changeowner <playername>")
            end
            return minetest.chatcommands["faction_changeowner"].func(name, target)

        elseif subcommand == "rankup" then
            if not target or target == "" then
                return minetest.chat_send_player(name, "Usage: /f rankup <playername>")
            end
            return minetest.chatcommands["faction_rankup"].func(name, target)
        
        elseif subcommand == "rankdown" then
            if not target or targtet == "" then
                return minetest.chat_send_player(name, "Usage: /f rankdown <playername")
            end
            return minetest.chatcommands["faction_rankdown"].func(name, target)

        else
            minetest.chat_send_player(name,"[Server] Unknown subcommand. Available: create, invite, accept, kick, leave, setbase, base, info, pinfo, disband, changeowner, request, acceptrequest, rankup, rankdown")
        end
    end
})

