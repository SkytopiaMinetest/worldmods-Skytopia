--[[

Skyblock for Minetest

Copyright (c) 2015 cornernote, Brett O'Donnell <cornernote@gmail.com>
Source Code: https://github.com/cornernote/minetest-skyblock
License: GPLv3

]]--

--[[
Level X - Farming & Cooking Challenge
Feats and rewards:

* plant_wheatseed x25        farming:tomato x2
* plant_cottonseed x30       farming:carrot_gold x2
* craft_woolcyan x10         farming:pumpkin_seed x2
* plant_tomato x20           farming:lettuce x2
* eat_pumpkinbread x20      farming:cucumber x2
* craft_flour x10            farming:onion x2
* plant_cucumber x20         default:pick_diamond x1
* place_pinesapling x10      default:axe_diamond x1
* dig_pinetree x50           default:dirt_with_dry_grass x1
* craft_burger x10           teleport_potion:potion x4
]]--

local level = 5

skyblock.levels[level] = {}

-- feats
skyblock.levels[level].feats = {
   {
      name = "Plant 25 wheat seeds",
      hint = "farming:seed_wheat",
      feat = "place_wheatseed",
      count = 25,
      reward = "farming:tomato 2",
      placenode = {"farming:seed_wheat"},
   },
   {
      name = "Plant 30 cotton seeds",
      hint = "farming:seed_cotton",
      feat = "place_cottonseed",
      count = 30,
      reward = "farming:carrot_gold 2",
      placenode = {"farming:seed_cotton"},
   },
   {
      name = "Craft 10 cyan wool blocks",
      hint = "wool:cyan",
      feat = "craft_woolcyan",
      count = 10,
      reward = "farming:pumpkin_seed",
      craft = {"wool:cyan"},
   },
   {
      name = "Plant 20 tomatoes",
      hint = "farming:tomato",
      feat = "place_tomato",
      count = 20,
      reward = "farming:lettuce 2",
      placenode = {"farming:tomato"},
   },
   {
      name = "Eat 20 pumpkin bread",
      hint = "farming:pumpkin_bread",
      feat = "eat_pumpkinbread",
      count = 20,
      reward = "farming:cucumber 2",
      item_eat = {"farming:pumpkin_bread"},
   },
   {
      name = "Craft 10 flour",
      hint = "farming:flour",
      feat = "craft_flour",
      count = 10,
      reward = "farming:onion 2",
      craft = {"farming:flour"},
   },
   {
      name = "Plant 20 cucumbers",
      hint = "farming:cucumber",
      feat = "place_cucumber",
      count = 20,
      reward = "default:pick_diamond",
      placenode = {"farming:cucumber"},
   },
   {
      name = "Place 10 pine saplings",
      hint = "default:pine_sapling",
      feat = "place_pinesapling",
      count = 10,
      reward = "default:axe_diamond",
      placenode = {"default:pine_sapling"},
   },
   {
      name = "Dig 50 pine tree blocks",
      hint = "default:pine_tree",
      feat = "dig_pinetree",
      count = 50,
      reward = "default:dirt_with_dry_grass",
      dignode = {"default:pine_tree"},
   },
   {
      name = "Craft 10 burgers",
      hint = "farming:burger",
      feat = "craft_burger",
      count = 10,
      reward = "teleport_potion:potion 4",
      craft = {"farming:burger"},
   },
}

-- init level
skyblock.levels[level].init = function(player_name)
end

-- get level information
skyblock.levels[level].get_info = function(player_name)
	local info = {
		level = level,
		total = #skyblock.levels[level].feats,
		count = 0,
		player_name = player_name,
		infotext = '',
		formspec = '',
		formspec_quest = '',
	}

	local text = 'label[0,2.7; --== Quests ==--]'
		.. 'label[0,0.5; Hello '..player_name..', welcome to your next farming journey!]'
		.. 'label[0,1.0; Plant, cook, and grow your future.]'
		.. 'label[0,1.5; This is the path of cultivation and crafting.]'

	info.formspec = skyblock.levels.get_inventory_formspec(level,info.player_name,true)..text
	info.formspec_quest = skyblock.levels.get_inventory_formspec(level,info.player_name)..text

	for k,v in ipairs(skyblock.levels[level].feats) do
		info.formspec = info.formspec..skyblock.levels.get_feat_formspec(info,k,v.feat,v.count,v.name,v.hint,true)
		info.formspec_quest = info.formspec_quest..skyblock.levels.get_feat_formspec(info,k,v.feat,v.count,v.name,v.hint)
	end
	if info.count>0 then
		info.count = info.count/2 -- only count once
	end

	info.infotext = 'LEVEL '..info.level..' for '..info.player_name..': '..info.count..' of '..info.total

	return info
end

-- Reward feats
skyblock.levels[level].reward_feat = function(player_name, feat)
   return skyblock.levels.reward_feat(level, player_name, feat)
end

-- Track node placement
skyblock.levels[level].on_placenode = function(pos, newnode, placer, oldnode)
   skyblock.levels.on_placenode(level, pos, newnode, placer, oldnode)
end

-- Track node digging
skyblock.levels[level].on_dignode = function(pos, oldnode, digger)
   skyblock.levels.on_dignode(level, pos, oldnode, digger)
end

-- track eating feats
skyblock.levels[level].on_item_eat = function(player_name, itemstack)
   skyblock.levels.on_item_eat(level, player_name, itemstack)
end

-- track crafting feats
skyblock.levels[level].on_craft = function(player_name, itemstack)
   skyblock.levels.on_craft(level, player_name, itemstack)
end

-- track hoe use
skyblock.levels[level].hoe_on_use = function(player_name, pointed_thing, wieldeditem)
   skyblock.levels.hoe_on_use(level, player_name, pointed_thing, wieldeditem)
end

skyblock.levels[level].bucket_on_use = function(player_name, pointed_thing) end
skyblock.levels[level].bucket_water_on_use = function(player_name, pointed_thing) end
skyblock.levels[level].bucket_lava_on_use = function(player_name, pointed_thing) end
