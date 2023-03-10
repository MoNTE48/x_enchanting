---@diagnostic disable: codestyle-check
---https://github.com/sumneko/lua-language-server/wiki

---@alias ObjectRef ObjectRefAbstract | ObjectRefLuaEntityRef

---Moving things in the game are generally these.
---This is basically a reference to a C++ `ServerActiveObject`.
---@class ObjectRefAbstract
---@field get_pos fun(): Vector Position of player
---@field get_inventory fun(): InvRef|nil Returns an `InvRef` for players, otherwise returns `nil`
---@field get_wield_index fun(): integer Returns the index of the wielded item
---@field get_wielded_item fun(): ItemStack Returns an `ItemStack`
---@field set_acceleration fun(self: ObjectRef, acc: Vector): nil
---@field set_yaw fun(self: ObjectRef, yaw: integer|number): nil Sets the yaw in radians (heading).
---@field get_player_name fun(self: ObjectRef): string Returns `""` if is not a player.
---@field set_fov fun(self: ObjectRef, fov: number|integer, is_multiplier: boolean, transition_time: number|integer): nil Sets player's FOV. `fov`: FOV value. `is_multiplier`: Set to `true` if the FOV value is a multiplier. Defaults to `false`. `transition_time`: If defined, enables smooth FOV transition. Interpreted as the time (in seconds) to reach target FOV. If set to 0, FOV change is instantaneous. Defaults to 0. Set `fov` to 0 to clear FOV override.
---@field get_hp fun(self: ObjectRef): number|integer Returns number of health points
---@field is_player fun(self: ObjectRef): boolean returns true for players, false otherwise
---@field get_luaentity fun(self: ObjectRef): table
---@field get_armor_groups fun(self: ObjectRef): ObjectRefArmorGroups returns a table with the armor group ratings
---@field punch fun(self: ObjectRef, puncher: ObjectRef, time_from_last_punch: integer|number, tool_capabilities: ToolCapabilitiesDef, direction: Vector|nil): nil
---@field add_velocity fun(self: ObjectRef, vel: Vector): nil `vel` is a vector, e.g. `{x=0.0, y=2.3, z=1.0}`. In comparison to using get_velocity, adding the velocity and then using set_velocity, add_velocity is supposed to avoid synchronization problems. Additionally, players also do not support set_velocity. If a player: Does not apply during free_move. Note that since the player speed is normalized at each move step, increasing e.g. Y velocity beyond what would usually be achieved (see: physics overrides) will cause existing X/Z velocity to be reduced. Example: `add_velocity({x=0, y=6.5, z=0})` is equivalent to pressing the jump key (assuming default settings)
---@field get_properties fun(self: ObjectRef): table Returns object property table
---@field get_children fun(self: ObjectRef): ObjectRef[] Returns a list of ObjectRefs that are attached to the object.
---@field set_properties fun(self: ObjectRef, object_properties: ObjectProperties): nil For entities; disables the regular damage mechanism for players punching it by hand or a non-tool item, so that it can do something else than take damage.
---@field get_look_dir fun(self: ObjectRef): Vector get camera direction as a unit vector
---@field get_meta fun(self: ObjectRef): MetaDataRef returns a PlayerMetaRef.
---@field hud_add fun(self: ObjectRef, hud_definition: table): number|integer|nil add a HUD element described by HUD def, returns ID number on success
---@field hud_remove fun(self: ObjectRef, id: number|integer): nil remove the HUD element of the specified id
---@field hud_change fun(self: ObjectRef, id: number|integer, stat: string, value: any): nil change a value of a previously added HUD element. `stat` supports the same keys as in the hud definition table except for `"hud_elem_type"`.
---@field set_wielded_item fun(self: ObjectRef, item: ItemStack): boolean replaces the wielded item, returns `true` if successful.
---@field move_to fun(self: ObjectRef, pos: Vector, continuous?: boolean): nil Does an interpolated move for Lua entities for visually smooth transitions. If `continuous` is true, the Lua entity will not be moved to the current position before starting the interpolated move. For players this does the same as `set_pos`,`continuous` is ignored.
---@field set_hp fun(self: ObjectRef, hp: number, reason: table): nil set number of health points See reason in register_on_player_hpchange Is limited to the range of 0 ... 65535 (2^16 - 1) For players: HP are also limited by `hp_max` specified in object properties
---@field set_animation fun(self: ObjectRef, frame_range?: {["x"]: number, ["y"]: number}, frame_speed?: number, frame_blend?: number, frame_loop?: boolean): nil `frame_range`: table {x=num, y=num}, default: `{x=1, y=1}`, `frame_speed`: number, default: `15.0`, `frame_blend`: number, default: `0.0`, `frame_loop`: boolean, default: `true`
---@field get_velocity fun(self: ObjectRef): Vector returns the velocity, a vector.
---@field set_rotation fun(self: ObjectRef, rot: Vector): nil `rot` is a vector (radians). X is pitch (elevation), Y is yaw (heading) and Z is roll (bank).
---@field set_pos fun(self: ObjectRef, pos: Vector): nil


---Moving things in the game are generally these.
---This is basically a reference to a C++ `ServerActiveObject`.
---@class ObjectRefLuaEntityRef
---@field set_velocity fun(self: ObjectRef, vel: Vector): nil `vel` is a vector, e.g. `{x=0.0, y=2.3, z=1.0}`
---@field remove fun(): nil remove object, The object is removed after returning from Lua. However the `ObjectRef` itself instantly becomes unusable with all further method calls having no effect and returning `nil`.
---@field get_rotation fun(self: ObjectRef): Vector returns the rotation, a vector (radians)
---@field get_attach fun(self: ObjectRef): any Returns parent, bone, position, rotation, forced_visible, or nil if it isn't attached.
---@field set_attach fun(self: ObjectRef, parent: ObjectRef, bone?: string, position?: Vector, rotation?: Vector, forced_visible?: boolean): any Returns parent, bone, position, rotation, forced_visible, or nil if it isn't attached.
---@field drops table Custom for mob drops

---`ObjectRef` armor groups
---@class ObjectRefArmorGroups
---@field immortal number|integer Skips all damage and breath handling for an object. This group will also hide the integrated HUD status bars for players. It is automatically set to all players when damage is disabled on the server and cannot be reset (subject to change).
---@field fall_damage_add_percent number|integer Modifies the fall damage suffered by players when they hit the ground. It is analog to the node group with the same name. See the node group above for the exact calculation.
---@field punch_operable number|integer For entities; disables the regular damage mechanism for players punching it by hand or a non-tool item, so that it can do something else than take damage.

---Used by `ObjectRef` methods. Part of an Entity definition. These properties are not persistent, but are applied automatically to the corresponding Lua entity using the given registration fields. Player properties need to be saved manually.
---@class ObjectProperties
---@field hp_max integer Defines the maximum and default HP of the entity. For Lua entities the maximum is not enforced. For players this defaults to `minetest.PLAYER_MAX_HP_DEFAULT`.
---@field breath_max integer For players only. Defaults to `minetest.PLAYER_MAX_BREATH_DEFAULT`.
---@field zoom_fov number For players only. Zoom FOV in degrees. Note that zoom loads and/or generates world beyond the server's maximum send and generate distances, so acts like a telescope. Smaller zoom_fov values increase the distance loaded/generated. Defaults to 15 in creative mode, 0 in survival mode. zoom_fov = 0 disables zooming for the player.
---@field eye_height number For players only. Camera height above feet position in nodes.
---@field physical boolean Collide with `walkable` nodes.
---@field collide_with_objects boolean Collide with other objects if physical = true
---@field collisionbox number[]|integer[]
---@field selectionbox number[]|integer[] Selection box uses collision box dimensions when not set. For both boxes: {xmin, ymin, zmin, xmax, ymax, zmax} in nodes from object position.
---@field pointable boolean Whether the object can be pointed at
---@field visual 'cube'|'sprite'|'upright_sprite'|'mesh'|'wielditem'|'item' "cube" is a node-sized cube. "sprite" is a flat texture always facing the player. "upright_sprite" is a vertical flat texture. "mesh" uses the defined mesh model. "wielditem" is used for dropped items. (see builtin/game/item_entity.lua). For this use 'wield_item = itemname' (Deprecated: 'textures = {itemname}'). If the item has a 'wield_image' the object will be an extrusion of that, otherwise: If 'itemname' is a cubic node or nodebox the object will appear identical to 'itemname'. If 'itemname' is a plantlike node the object will be an extrusion of its texture. Otherwise for non-node items, the object will be an extrusion of 'inventory_image'. If 'itemname' contains a ColorString or palette index (e.g. from `minetest.itemstring_with_palette()`), the entity will inherit the color. "item" is similar to "wielditem" but ignores the 'wield_image' parameter.
---@field visual_size {['x']: integer|number, ['y']: integer|number, ['z']: integer|number} Multipliers for the visual size. If `z` is not specified, `x` will be used to scale the entity along both horizontal axes.
---@field mesh string File name of mesh when using "mesh" visual
---@field textures table Number of required textures depends on visual. "cube" uses 6 textures just like a node, but all 6 must be defined. "sprite" uses 1 texture. "upright_sprite" uses 2 textures: {front, back}. "wielditem" expects 'textures = {itemname}'. "mesh" requires one texture for each mesh buffer/material (in order)
---@field colors table Number of required colors depends on visual
---@field use_texture_alpha boolean Use texture's alpha channel. Excludes "upright_sprite" and "wielditem". Note: currently causes visual issues when viewed through other semi-transparent materials such as water.
---@field spritediv {['x']: integer|number, ['y']: integer|number} Used with spritesheet textures for animation and/or frame selection according to position relative to player. Defines the number of columns and rows in the spritesheet: {columns, rows}.
---@field initial_sprite_basepos {['x']: integer|number, ['y']: integer|number} Used with spritesheet textures. Defines the {column, row} position of the initially used frame in the spritesheet.
---@field is_visible boolean If false, object is invisible and can't be pointed.
---@field makes_footstep_sound boolean If true, is able to make footstep sounds of nodes
---@field automatic_rotate number|integer Set constant rotation in radians per second, positive or negative. Object rotates along the local Y-axis, and works with set_rotation. Set to 0 to disable constant rotation.
---@field stepheight number|integer If positive number, object will climb upwards when it moves horizontally against a `walkable` node, if the height difference is within `stepheight`.
---@field automatic_face_movement_dir number|integer Automatically set yaw to movement direction, offset in degrees. 'false' to disable.
---@field automatic_face_movement_max_rotation_per_sec number|integer Limit automatic rotation to this value in degrees per second. No limit if value <= 0.
---@field backface_culling boolean Set to false to disable backface_culling for model
---@field glow number|integer Add this much extra lighting when calculating texture color. Value < 0 disables light's effect on texture color. For faking self-lighting, UI style entities, or programmatic coloring in mods.
---@field nametag string The name to display on the head of the object. By default empty. If the object is a player, a nil or empty nametag is replaced by the player's name. For all other objects, a nil or empty string removes the nametag. To hide a nametag, set its color alpha to zero. That will disable it entirely.
---@field nametag_color ColorSpec Sets text color of nametag
---@field nametag_bgcolor ColorSpec Sets background color of nametag `false` will cause the background to be set automatically based on user settings. Default: false
---@field infotext string Same as infotext for nodes. Empty by default
---@field static_save boolean If false, never save this object statically. It will simply be deleted when the block gets unloaded. The get_staticdata() callback is never called then. Defaults to 'true'.
---@field damage_texture_modifier string Texture modifier to be applied for a short duration when object is hit
---@field shaded boolean Setting this to 'false' disables diffuse lighting of entity
---@field show_on_minimap boolean Defaults to true for players, false for other entities. If set to true the entity will show as a marker on the minimap.
