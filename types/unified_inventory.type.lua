---@diagnostic disable: codestyle-check
---Base class Unified Inventory
---@class UnifiedInventory
---@field set_inventory_formspec fun(player: ObjectRef, formspecname: string): nil
---@field register_button fun(name: string, def: table): nil
---@field single_slot fun(x: number, y: number): nil
---@field register_page fun(name: string, def: table): nil
---@field style_full table