local BasePlugin = require "kong.plugins.base_plugin"
local uuid = require 'resty.jit-uuid'

local kong = kong

local CustomStatusFilterHandler = BasePlugin:extend()

local DEFAULT_RESPONSE = {
  
  [400] = "RWS-ERR-4XX",
  [401] = "Unauthorized",
  [500] = "RWS-ERR-5XX",
}

function CustomStatusFilterHandler:new()
  CustomStatusFilterHandler.super.new(self, "CustomStatusFilter")
end


function CustomStatusFilterHandler:header_filter(conf)
   CustomStatusFilterHandler.super.header_filter(self)
   -- remove content length to prevent client from waiting for the original content length to download
   kong.response.clear_header("Content-Length")
   kong.response.set_header("X-RWS-SOURCE", kong.response.get_source())
   
   --setup a uuid for error log correlation
   local uuid = "RWS-"..uuid()
   self.log_uuid = uuid
   
   kong.response.set_header("X-RWS-LOGREFID", uuid)
 
end  

local function transform_custom_status_codes(status_code)
  -- Non-standard 4XX HTTP codes will be returned as 400 Bad Request
  if status_code > 401 then
    status_code = 400
  elseif status_code >= 500 then
    status_code = 500
  end  

  return status_code
end

function CustomStatusFilterHandler:body_filter(conf)
  CustomStatusFilterHandler.super.body_filter(self)
  local status  = transform_custom_status_codes(kong.response.get_status())

  if status > 200 then
     local ctx = ngx.ctx
     local chunk, eof = ngx.arg[1], ngx.arg[2]

     ctx.rt_body_chunks = ctx.rt_body_chunks or {}
     ctx.rt_body_chunk_number = ctx.rt_body_chunk_number or 1

     if eof then
        local chunks = table.concat(ctx.rt_body_chunks)
        local logRefStr = '"LOG_REF_ID" : "'..self.log_uuid..'"'
        local body = '{"Exception" : "'.. DEFAULT_RESPONSE[status] ..'"}'
        kong.log.err('['..self.log_uuid..'],'..chunks)
        ngx.arg[1] = body 

     else
        ctx.rt_body_chunks[ctx.rt_body_chunk_number] = chunk
        ctx.rt_body_chunk_number = ctx.rt_body_chunk_number + 1
        ngx.arg[1] = nil
     end --eof
  end
end -- func


CustomStatusFilterHandler.PRIORITY = 800
CustomStatusFilterHandler.VERSION = "0.1.0"

return CustomStatusFilterHandler
