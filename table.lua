--[[
	X Enchanting. Adds Enchanting Mechanics and API.
	Copyright (C) 2023 SaKeL <juraj.vajda@gmail.com>

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Lesser General Public
	License as published by the Free Software Foundation; either
	version 3.0 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public
	License along with this library; if not, write to juraj.vajda@gmail.com
--]]

local S = XEnchanting.S

local random, pi = math.random, math.pi
local vdistance, vnew = vector.distance, vector.new

----
--- Table Node
----

minetest.register_node('x_enchanting:table', {
	description = S('Enchanting Table'),
	short_description = S('Enchanting Table'),
	drawtype = 'mesh',
	mesh = 'x_enchanting_table.b3d',
	tiles = { 'x_enchanting_table.png' },
	inventory_image = 'x_enchanting_inv.png',
	use_texture_alpha = 'clip',
	paramtype = 'light',
	paramtype2 = 'facedir',
	walkable = true,
	selection_box = {
		type = 'fixed',
		fixed = { -1 / 2 + 1 / 16, -1 / 2, -1 / 2 + 1 / 16, 1 / 2 - 1 / 16, 1 / 2 - 1 / 16, 1 / 2 - 1 / 16 }
	},
	collision_box = {
		type = 'fixed',
		fixed = { -1 / 2, -1 / 2, -1 / 2, 1 / 2, 1 / 2 - 1 / 16, 1 / 2 }
	},
	sounds = default.node_sound_stone_defaults(),
	is_ground_content = false,
	groups = { cracky = 1, level = 2 },
	stack_max = 1,
	mod_origin = 'x_enchanting',
	light_source = 6,
	node_placement_prediction = '',

	on_place = function(itemstack, player, pointed_thing)
		if minetest.find_node_near(pointed_thing.above, 3, 'x_enchanting:table') then
			return itemstack
		end

		return minetest.item_place(itemstack, player, pointed_thing)
	end,

	---@param pos Vector
	on_construct = function(pos)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()

		meta:set_string('infotext', S('Enchanting Table'))
		inv:set_size('item', 1)
		inv:set_size('trade', 1)

		minetest.add_entity({x = pos.x, y = pos.y + 0.85, z = pos.z}, 'x_enchanting:table_scroll')

		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		local def = minetest.registered_nodes[minetest.get_node(above).name]
		if def and def.buildable_to then
			minetest.set_node(above, {name = 'x_enchanting:sparkles'})
		end

		minetest.get_node_timer(pos):set(5, 5)
	end,
	---@param pos Vector
	---@param placer ObjectRef | nil
	---@param itemstack ItemStack
	---@param pointed_thing PointedThingDef
	---@diagnostic disable-next-line: unused-local
	after_place_node = function(pos, placer, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)

		if not placer then
			return
		end

		local player_name = placer:get_player_name()

		local formspec = XEnchanting:get_formspec(pos, player_name)
		meta:set_string('formspec', formspec)
	end,
	---@param pos Vector
	---@param node NodeDef
	---@param clicker ObjectRef
	---@param itemstack ItemStack
	---@param pointed_thing? PointedThingDef
	---@diagnostic disable-next-line: unused-local
	on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
		local meta = minetest.get_meta(pos)
		local p_name = clicker:get_player_name()

		if minetest.is_protected(pos, p_name) then
			return itemstack
		end

		--[[minetest.sound_play('x_enchanting_scroll', {
			gain = 0.3,
			pos = pos,
			max_hear_distance = 10
		}, true)]]

		local inv = minetest.get_meta(pos):get_inventory()

		if not inv:is_empty('item') and inv:get_stack('item', 1):get_meta():get_int('is_enchanted') ~= 1 then
			-- bookshelfs
			local bookshelfs = {} --[[minetest.find_nodes_in_area(
				{ x = pos.x - 2, y = pos.y, z = pos.z - 2 },
				{ x = pos.x + 2, y = pos.y + 2, z = pos.z + 2 },
				{ 'default:bookshelf', 'group:bookshelf' }
			)]]

			local item_stack = inv:get_stack('item', 1)
			local data = XEnchanting:get_enchantment_data(
				clicker,
				#bookshelfs,
				minetest.registered_tools[item_stack:get_name()]
			)
			local formspec = XEnchanting:get_formspec(pos, p_name, data)

			meta:set_string('formspec', formspec)
		else
			local formspec = XEnchanting:get_formspec(pos, p_name)

			meta:set_string('formspec', formspec)
		end

		return itemstack
	end,
	---@param pos Vector
	---@param intensity? number
	---@return table | nil
	---@diagnostic disable-next-line: unused-local
	on_blast = function(pos, intensity)
		if minetest.is_protected(pos, '') then
			return
		end

		local drops = {}
		local inv = minetest.get_meta(pos):get_inventory()
		local stack_item = inv:get_stack('item', 1)
		local stack_trade = inv:get_stack('trade', 1)

		if not stack_item:is_empty() then
			drops[#drops + 1] = stack_item:to_table()
		end

		if not stack_trade:is_empty() then
			drops[#drops + 1] = stack_trade:to_table()
		end

		drops[#drops + 1] = 'x_enchanting:table'
		minetest.remove_node(pos)
		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		if minetest.get_node(above).name == 'x_enchanting:sparkles' then
			minetest.remove_node(above)
		end

		return drops
	end,
	---@param pos Vector
	---@param player? ObjectRef
	can_dig = function(pos, player)
		if not player then
			return false
		end

		local inv = minetest.get_meta(pos):get_inventory()

		return inv:is_empty('item')
			and inv:is_empty('trade')
			and not minetest.is_protected(pos, player:get_player_name())
	end,
	on_rotate = function()
		return false
	end,
	---@param pos Vector
	---@param elapsed number
	---@diagnostic disable-next-line: unused-local
	on_timer = function(pos, elapsed)
		-- entity
		local table_scroll = minetest.get_objects_inside_radius(pos, 1)

		if #table_scroll == 0 then
			minetest.add_entity({ x = pos.x, y = pos.y + 0.85, z = pos.z }, 'x_enchanting:table_scroll')
		end

		local particlespawner_def = {
			amount = 50,
			time = 5,
			minpos = { x = pos.x - 0.25, y = pos.y + 0.45, z = pos.z - 0.25 },
			maxpos = { x = pos.x + 0.25, y = pos.y + 0.45, z = pos.z + 0.25 },
			minvel = { x = -0.15, y = 0.1, z = -0.15 },
			maxvel = { x = 0.15, y = 0.2, z = 0.15 },
			minacc = { x = -0.15, y = 0.1, z = -0.15 },
			maxacc = { x = 0.15, y = 0.2, z = 0.15 },
			minexptime = 1.5,
			maxexptime = 2.5,
			minsize = 0.2,
			maxsize = 0.4,
			texture = 'x_enchanting_scroll_particle.png',
			glow = 1
		}

--[[
		if minetest.has_feature({ dynamic_add_media_table = true, particlespawner_tweenable = true }) then
			-- new syntax, after v5.6.0
			particlespawner_def = {
				amount = 50,
				time = 5,
				size = {
					min = 0.1,
					max = 0.3,
				},
				exptime = 2,
				pos = {
					min = vector.new({ x = pos.x - 0.5, y = pos.y, z = pos.z - 0.5 }),
					max = vector.new({ x = pos.x + 0.5, y = pos.y, z = pos.z + 0.5 }),
				},
				attract = {
					kind = 'point',
					strength = 0.5,
					origin = vector.new({ x = pos.x, y = pos.y + 0.65, z = pos.z })
				},
				texture = {
					name = 'x_enchanting_scroll_particle.png',
					alpha_tween = {
						0, 1,
						style = 'fwd',
						reps = 1
					}
				},
				glow = 1
			}
		end
]]

		minetest.add_particlespawner(particlespawner_def)

		---bookshelfs
--[[
			local bookshelfs = minetest.find_nodes_in_area(
			{ x = pos.x - 2, y = pos.y, z = pos.z - 2 },
			{ x = pos.x + 2, y = pos.y + 2, z = pos.z + 2 },
			{ 'default:bookshelf', 'group:bookshelf' }
		)

		if #bookshelfs == 0 then
			return true
		end

		-- symbol particles
		---@diagnostic disable-next-line: unused-local
		for i = 1, 10, 1 do
			local pos_random = bookshelfs[random(1, #bookshelfs)]
			local x = pos.x - pos_random.x
			local y = pos_random.y - pos.y
			local z = pos.z - pos_random.z
			local rand1 = (random(150, 250) / 100) * -1
			local rand2 = random(10, 500) / 100
			local rand3 = random(50, 200) / 100

			minetest.after(rand2, function()
				minetest.add_particle({
					pos = pos_random,
					velocity = { x = x, y = 2 - y, z = z },
					acceleration = { x = 0, y = rand1, z = 0 },
					expirationtime = 1,
					size = rand3,
					texture = 'x_enchanting_symbol_' .. random(1, 26) .. '.png',
					glow = 6
				})
			end)
		end
]]

		return true
	end,
	---@param pos Vector
	on_destruct = function(pos)
		for _, obj in ipairs(minetest.get_objects_inside_radius(pos, 1)) do
			local ent = obj:get_luaentity()
			if ent and ent.name == 'x_enchanting:table_scroll' then
				obj:remove()
				break
			end
		end

		local above = {x = pos.x, y = pos.y + 1, z = pos.z}
		if minetest.get_node(above).name == 'x_enchanting:sparkles' then
			minetest.remove_node(above)
		end
	end,
	---@param pos Vector
	---@param listname string
	---@param index number
	---@param stack ItemStack
	---@param player ObjectRef
	---@diagnostic disable-next-line: unused-local
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then return 0 end

		local st_meta = stack:get_meta()
		local st_name = stack:get_name()
		local is_enchanted = st_meta:get_int('is_enchanted')

		if listname == 'item'
			and minetest.get_item_group(st_name, 'enchantability') > 0
			and is_enchanted ~= 1
		then
			return stack:get_count()
		elseif listname == 'trade'
			and (
				st_name == 'charoit:charoit'
				or minetest.get_item_group(st_name, 'enchanting_trade') > 0
			)
			and is_enchanted ~= 1
		then
			return stack:get_count()
		end

		return 0
	end,
	---@param pos Vector
	---@param listname string
	---@param index number
	---@param stack ItemStack
	---@param player ObjectRef
	---@diagnostic disable-next-line: unused-local
	allow_metadata_inventory_take = function(pos, listname, index, stack, player)
		if minetest.is_protected(pos, player:get_player_name()) then return 0 end

		local st_name = stack:get_name()

		if listname == 'item' then
			return stack:get_count()
		elseif listname == 'trade'
			and (
				st_name == 'charoit:charoit'
				or minetest.get_item_group(st_name, 'enchanting_trade') > 0
			)
		then
			return stack:get_count()
		end

		return 0
	end,
	---@param pos Vector
	---@param from_list string
	---@param from_index number
	---@param to_list string
	---@param to_index number
	---@param count number
	---@param player ObjectRef
	---@diagnostic disable-next-line: unused-local
	allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
		return 0
	end,
	---@param pos Vector
	---@param listname string
	---@param index number
	---@param stack ItemStack
	---@param player ObjectRef
	---@diagnostic disable-next-line: unused-local
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local p_name = player:get_player_name()
		local inv = meta:get_inventory()
		local item_stack = inv:get_stack('item', 1)
		local item_stack_meta = item_stack:get_meta()
		local is_enchanted = item_stack_meta:get_int('is_enchanted')

		if not inv:is_empty('item') and is_enchanted == 0 then
			-- bookshelfs
			local bookshelfs = {} --[[minetest.find_nodes_in_area(
				{ x = pos.x - 2, y = pos.y, z = pos.z - 2 },
				{ x = pos.x + 2, y = pos.y + 2, z = pos.z + 2 },
				{ 'default:bookshelf', 'group:bookshelf' }
			)]]

			local data = XEnchanting:get_enchantment_data(
				player,
				#bookshelfs,
				minetest.registered_tools[item_stack:get_name()]
			)
			local formspec = XEnchanting:get_formspec(pos, p_name, data)

			meta:set_string('formspec', formspec)
		else
			local formspec = XEnchanting:get_formspec(pos, p_name)

			meta:set_string('formspec', formspec)
		end
	end,
	---@param pos Vector
	---@param listname string
	---@param index number
	---@param stack ItemStack
	---@param player ObjectRef
	---@diagnostic disable-next-line: unused-local
	on_metadata_inventory_take = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local p_name = player:get_player_name()
		local inv = meta:get_inventory()
		local item_stack = inv:get_stack('item', 1)
		local item_stack_meta = item_stack:get_meta()
		local is_enchanted = item_stack_meta:get_int('is_enchanted')

		if not inv:is_empty('item') and is_enchanted == 0 then
			-- bookshelfs
			local bookshelfs = {} --[[minetest.find_nodes_in_area(
				{ x = pos.x - 2, y = pos.y, z = pos.z - 2 },
				{ x = pos.x + 2, y = pos.y + 2, z = pos.z + 2 },
				{ 'default:bookshelf', 'group:bookshelf' }
			)]]

			local data = XEnchanting:get_enchantment_data(
				player,
				#bookshelfs,
				minetest.registered_tools[item_stack:get_name()]
			)
			local formspec = XEnchanting:get_formspec(pos, p_name, data)

			meta:set_string('formspec', formspec)
		else
			local formspec = XEnchanting:get_formspec(pos, p_name)

			meta:set_string('formspec', formspec)
		end
	end,
	-- form receive fields
	---@param pos Vector
	---@param formname string
	---@param fields table
	---@param sender ObjectRef
	---@diagnostic disable-next-line: unused-local
	on_receive_fields = function(pos, formname, fields, sender)
		local p_name = sender:get_player_name()

		if minetest.is_protected(pos, p_name) then return end

		if fields.quit then
			XEnchanting.form_context[p_name] = nil
			return
		end

		local selected_slot

		if fields.slot_1 and fields.slot_1 ~= '' then
			selected_slot = 1
		elseif fields.slot_2 and fields.slot_2 ~= '' then
			selected_slot = 2
		elseif fields.slot_3 and fields.slot_3 ~= '' then
			selected_slot = 3
		end

		if not XEnchanting.form_context[p_name] or not selected_slot then
			return
		end

		local inv = minetest.get_meta(pos):get_inventory()

		if inv:is_empty('trade') or inv:is_empty('item') then
			return
		end

		local trade_stack = inv:get_stack('trade', 1)

		if (trade_stack:get_count()) < (selected_slot * 16) then -- 2
			return
		end

		local item_stack = inv:get_stack('item', 1)
		local is_enchanted = item_stack:get_meta():get_int('is_enchanted')

		if is_enchanted == 1 then
			return
		end

		-- Enchant item
		XEnchanting:set_enchanted_tool(
			pos,
			item_stack,
			selected_slot,
			p_name
		)
	end
})

----
--- Entity (Scroll)
----

minetest.register_entity('x_enchanting:table_scroll', {
	initial_properties = {
		visual = 'mesh',
		mesh = 'x_enchanting_stone.b3d',
		visual_size = {x = 1, y = 1, z = 1},
		textures = {'x_enchanting_stone.png', 'blank.png'},
		use_texture_alpha = true,
		collisionbox = { 0, 0, 0, 0, 0, 0 },
		selectionbox = { 0, 0, 0, 0, 0, 0 },
		physical = false,
		hp_max = 1,
		glow = 1,
		pointable = false,
		automatic_rotate = 2
	},
	---@param self table
	---@param killer ObjectRef
	---@diagnostic disable-next-line: unused-local
	on_death = function(self, killer)
		self.object:remove()
	end,
	---@param self table
	---@param staticdata StringAbstract
	---@param dtime_s number
	---@diagnostic disable-next-line: unused-local
	on_activate = function(self, staticdata, dtime_s)
		self._tablechecktimer = 5
		self._playerchecktimer = 1
		self._player = nil
		self._last_rotation = nil

		self.object:set_armor_groups({ immortal = 1 })
	--	self.object:set_animation({ x = 0, y = 0 }, 0, 0, false)
		self.object:set_animation({x = 0, y = 60})
	end,
	---@param self table
	---@param dtime number
	---@param moveresult? table
	---@diagnostic disable-next-line: unused-local
	on_step = function(self, dtime, moveresult)
		local pos = self.object:get_pos()

		self._last_rotation = self.object:get_rotation()
		self._tablechecktimer = self._tablechecktimer - dtime
		self._playerchecktimer = self._playerchecktimer - dtime

		-- table
		if self._tablechecktimer <= 0 then
			self._tablechecktimer = 5
			local node = minetest.get_node({ x = pos.x, y = pos.y - 0.85, z = pos.z })

			if node.name ~= 'x_enchanting:table' then
				-- remove entity when no table under it
				self.object:remove()
			end
		end

		-- player
		if self._playerchecktimer <= 0 then
			self._playerchecktimer = 1
			local objects = minetest.get_objects_inside_radius(pos, 5)

			-- inital value
			local shortest_distance = 10
			local found_player = false

			if #objects > 0 then
				---@diagnostic disable-next-line: unused-local
				for i, obj in ipairs(objects) do
					if obj:is_player() and obj:get_pos() then
						-- player
						found_player = true
						local distance = vdistance(pos, obj:get_pos())

						if distance < shortest_distance then
							shortest_distance = distance
							self._player = obj
						end
					end
				end
			else
				self._player = nil
			end

			if not found_player then
				self._player = nil
			end

			self.object:set_properties({automatic_rotate = found_player and 2 or 0})
		end
	end,
	on_punch = function()
		return true
	end
})

minetest.register_node('x_enchanting:sparkles', {
	drawtype = 'nodebox',
	node_box = {
		type = 'fixed',
		fixed = {-0.5, -0.5, 0, 0.5, 0.5, 0}
	},
	use_texture_alpha = 'clip',
	tiles = {
		'blank.png', 'blank.png', 'blank.png', 'blank.png',
		{
			name = 'x_enchanting_sparkles.png',
			animation = {
				type = 'sheet_2d',
				frames_w = 1,
				frames_h = 4,
				frame_length = 0.25
			}
		}
	},
	paramtype = 'light',
	paramtype2 = 'facedir',
	pointable = false,
	walkable = false,
	groups = {not_in_creative_inventory = 1},
	on_place = function(itemstack)
		return itemstack
	end,
})

-- MVPS stopper
if mesecon and mesecon.register_mvps_stopper then
	mesecon.register_mvps_stopper('x_enchanting:table')
	mesecon.register_mvps_stopper('x_enchanting:sparkles')
	mesecon.register_mvps_unmov('x_enchanting:table_scroll')
end

----
-- Recipe
---

minetest.register_craft({
	output = 'x_enchanting:table',
	recipe = {
		{ 'default:ruby', 'default:book', 'default:ruby' },
		{ 'default:diamond', 'default:obsidian', 'default:diamond' },
		{ 'default:obsidian', 'charoit:block', 'default:obsidian' }
	}
})
