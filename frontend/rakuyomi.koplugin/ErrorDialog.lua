local InfoMessage = require("ui/widget/infomessage")
local InputDialog = require("ui/widget/inputdialog")
local UIManager = require("ui/uimanager")

local ErrorDialog = {}

function ErrorDialog:show(message)
  local dialog = InfoMessage:new({
    text = message,
    icon = "notice-warning",
  })

  UIManager:show(dialog)
end

return ErrorDialog
