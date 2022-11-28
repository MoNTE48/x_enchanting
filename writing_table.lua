screwdriver = minetest.global_exists('screwdriver') and screwdriver --[[@as MtgScrewdriver]]

local S = minetest.get_translator(minetest.get_current_modname())

----
--- Table Node
----

minetest.register_node('x_enchanting:writing_table', {
    description = S('Writing Table'),
    short_description = S('Writing Table'),
    ---top, bottom, sides...front
    tiles = {
        'x_enchanting_writing_table_top.png',
        'x_enchanting_writing_table_bottom.png',
        'x_enchanting_writing_table_side.png',
        'x_enchanting_writing_table_side.png',
        'x_enchanting_writing_table_side.png',
        'x_enchanting_writing_table_front.png'
    },
    paramtype = 'light',
    paramtype2 = 'facedir',
    walkable = true,
    wield_scale = { x = 2, y = 2, z = 2 },
    sounds = {
        footstep = {
            name = 'x_enchanting_scroll',
            gain = 0.2
        },
        dug = {
            name = 'x_enchanting_scroll',
            gain = 1.0
        },
        place = {
            name = 'x_enchanting_scroll',
            gain = 1.0
        }
    },
    is_ground_content = false,
    groups = { choppy = 2, oddly_breakable_by_hand = 2, flammable = 2 },
    mod_origin = 'x_enchanting',
    ---@param pos Vector
    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        meta:set_string('infotext', S('Writing Table'))
        meta:set_string('owner', '')
        inv:set_size('item', 1)
        inv:set_size('sacrifice', 1)
        inv:set_size('result', 1)
        inv:set_size('trade', 1)
    end,
    ---@param pos Vector
    ---@param placer ObjectRef | nil
    ---@param itemstack ItemStack
    ---@param pointed_thing PointedThingDef
    after_place_node = function(pos, placer, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)

        if not placer then
            return
        end

        local player_name = placer:get_player_name()

        local props = {
            player_name = player_name
        }

        meta:set_string('owner', player_name)
        meta:set_string('infotext', S('Writing Table') .. ' (' .. S('owned by') .. ' ' .. player_name .. ')')

        local formspec = XEnchanting:get_formspec_writing_table(pos, props)
        meta:set_string('formspec', formspec)
    end,
    ---@param pos Vector
    ---@param node NodeDef
    ---@param clicker ObjectRef
    ---@param itemstack ItemStack
    ---@param pointed_thing? PointedThingDef
    on_rightclick = function(pos, node, clicker, itemstack, pointed_thing)
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local p_name = clicker:get_player_name()
        local props = {
            player_name = p_name,
            inv = inv
        }

        if minetest.is_protected(pos, p_name) then
            return itemstack
        end

        minetest.sound_play('x_enchanting_scroll', {
            gain = 0.3,
            pos = pos,
            max_hear_distance = 10
        }, true)

        local data = XEnchanting:get_writing_table_total_data(props)

        props.data = data

        local formspec = XEnchanting:get_formspec_writing_table(pos, props)
        meta:set_string('formspec', formspec)

        return itemstack
    end,
    ---@param pos Vector
    ---@param intensity? number
    ---@return table | nil
    on_blast = function(pos, intensity)
        if minetest.is_protected(pos, '') then
            return
        end

        local drops = {}
        local inv = minetest.get_meta(pos):get_inventory()
        local stack_item = inv:get_stack('item', 1)
        local stack_sacrifice = inv:get_stack('sacrifice', 1)
        local stack_result = inv:get_stack('result', 1)
        local stack_trade = inv:get_stack('trade', 1)

        if not stack_item:is_empty() then
            drops[#drops + 1] = stack_item:to_table()
        end

        if not stack_sacrifice:is_empty() then
            drops[#drops + 1] = stack_sacrifice:to_table()
        end

        if not stack_result:is_empty() then
            drops[#drops + 1] = stack_result:to_table()
        end

        if not stack_trade:is_empty() then
            drops[#drops + 1] = stack_trade:to_table()
        end

        drops[#drops + 1] = 'x_enchanting:writing_table'
        minetest.remove_node(pos)

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
            and inv:is_empty('sacrifice')
            and inv:is_empty('result')
            and inv:is_empty('trade')
            and not minetest.is_protected(pos, player:get_player_name())
    end,
    on_rotate = function(pos, node, user, mode, new_param2)
        return false
    end,
    ---@param pos Vector
    ---@param listname string
    ---@param index number
    ---@param stack ItemStack
    ---@param player ObjectRef
    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        print('allow_metadata_inventory_put')
        local st_name = stack:get_name()
        local st_meta = stack:get_meta()

        if listname == 'result' then
            return 0
        end

        if listname == 'item'
            and (st_meta:get_int('is_enchanted') > 0 or minetest.get_item_group(st_name, 'scroll') > 0)
        then
            return stack:get_count()
        elseif listname == 'sacrifice'
            and st_meta:get_int('is_enchanted') > 0
            and minetest.get_item_group(st_name, 'scroll') > 0
        then
            return stack:get_count()
        elseif listname == 'trade'
            and (
                st_name == 'default:mese_crystal'
                or minetest.get_item_group(st_name, 'enchanting_trade') > 0
            )
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
    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        print('allow_metadata_inventory_take')
        local st_name = stack:get_name()

        if listname == 'item' then
            return stack:get_count()
        elseif listname == 'sacrifice' then
            return stack:get_count()
        elseif listname == 'result' then
            return stack:get_count()
        elseif listname == 'trade'
            and (
                st_name == 'default:mese_crystal'
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
    allow_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        print('allow_metadata_inventory_move')
        print('allow_metadata_inventory_move')
        print('from_list', from_index, from_list)
        print('to_list', to_index, to_list)

        if (to_list == 'item' or to_list == 'sacrifice')
            and (from_list == 'item' or from_list == 'sacrifice')
        then
            return count
        end

        return 0
    end,
    ---@param pos Vector
    ---@param listname string
    ---@param index number
    ---@param stack ItemStack
    ---@param player ObjectRef
    on_metadata_inventory_put = function(pos, listname, index, stack, player)
        print('on_metadata_inventory_put')
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local props = {
            player_name = player:get_player_name(),
            inv = inv
        }

        local data = XEnchanting:get_writing_table_total_data(props)

        props.data = data

        local formspec = XEnchanting:get_formspec_writing_table(pos, props)
        meta:set_string('formspec', formspec)
    end,
    ---@param pos Vector
    ---@param listname string
    ---@param index number
    ---@param stack ItemStack
    ---@param player ObjectRef
    on_metadata_inventory_take = function(pos, listname, index, stack, player)
        print('on_metadata_inventory_take')
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()

        if listname == 'result' then
            inv:set_stack('item', 1, ItemStack(''))
            inv:set_stack('sacrifice', 1, ItemStack(''))
            inv:set_stack('result', 1, ItemStack(''))
            return
        end

        local props = {
            player_name = player:get_player_name(),
            inv = inv
        }

        local data = XEnchanting:get_writing_table_total_data(props)

        props.data = data

        local formspec = XEnchanting:get_formspec_writing_table(pos, props)
        meta:set_string('formspec', formspec)
    end,
    on_metadata_inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
        print('on_metadata_inventory_move')
        local meta = minetest.get_meta(pos)
        local inv = meta:get_inventory()
        local props = {
            player_name = player:get_player_name(),
            inv = inv
        }

        local data = XEnchanting:get_writing_table_total_data(props)

        props.data = data

        local formspec = XEnchanting:get_formspec_writing_table(pos, props)
        meta:set_string('formspec', formspec)
    end,
    -- form receive fields
    ---@param pos Vector
    ---@param formname string
    ---@param fields table
    ---@param sender ObjectRef
    on_receive_fields = function(pos, formname, fields, sender)

    end
})

-- Scroll Item
minetest.register_craftitem('x_enchanting:scroll_item', {
    description = S('Scroll'),
    short_description = S('Scroll'),
    inventory_image = 'x_enchanting_scroll_item.png^[colorize:#8F00FF:60',
    wield_image = 'x_enchanting_scroll_item.png^[transformFXR90^[colorize:#8F00FF:60',
    groups = { scroll = 1, flammable = 3 },
    stack_max = 1
})
