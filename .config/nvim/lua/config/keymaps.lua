-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Keymap to sync notes with Notion
vim.keymap.set("n", "<leader>ns", function()
  -- Run mk-notes sync as a shell command
  vim.fn.jobstart({
    "mk-notes",
    "sync",
    "--input",
    "/Users/hritish/notes",
    "--destination",
    "https://www.notion.so/hritish/quicknotes-27f2d0e68407806dbef5d350950dced3",
    "--notion-api-key",
    os.getenv("NOTION_API_KEY") or "",
  }, {
    stdout_buffered = true,
    on_stdout = function(_, data)
      if data then
        vim.notify(table.concat(data, "\n"), vim.log.levels.INFO, { title = "mk-notes" })
      end
    end,
    on_exit = function(_, code)
      if code == 0 then
        vim.notify("mk-notes sync done!", vim.log.levels.INFO, { title = "mk-notes" })
      else
        vim.notify("mk-notes sync failed (exit " .. code .. ")", vim.log.levels.ERROR, { title = "mk-notes" })
      end
    end,
  })
end, { desc = "Sync Notion notes" })
