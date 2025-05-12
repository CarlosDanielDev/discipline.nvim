# discipline.nvim

The “discipline” plugin for Neovim — warns you when you’re over-using non-Vim motions.

## with packer.nvim

```lua
use {
  'CarlosDanielDev/discipline.nvim',
  config = function()
    require('discipline').setup {
      rules_url         = 'https://gist.githubusercontent.com/.../rules_discipline_nvim.json',
      use_default_rules = true,
    }
  end
}
```

## with lazy.nvim

```lua
{
  'CarlosDanielDev/discipline.nvim',
  opts = {
    rules_url         = 'https://gist.githubusercontent.com/.../rules_discipline_nvim.json',
    use_default_rules = true,
  }
}
```

> If you wants to customize the remote rules, just create a `.josn` file on your `gist` or a public file and replace on `rules_url` setup.
