package = "kong-plugin-custom-status-filter"
version = "0.1.0-1"
source = {
  url = "git://github.com/alwacer/custom-status-filter"
}
description = {
   license = "MIT"
}
dependencies = {
   "lua ~> 5.1"
}
build = {
   type = "builtin",
   modules = {
      ["kong.plugins.custom-status-filter.handler"] = "src/kong/plugins/custom-status-filter/handler.lua",
      ["kong.plugins.custom-status-filter.schema"] = "src/kong/plugins/custom-status-filter/schema.lua"
   }
}
