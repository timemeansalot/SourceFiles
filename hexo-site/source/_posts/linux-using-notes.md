---
title: Linux学习笔记
date: 2022-12-09 10:35:05
tags: Linux
---

本文档记录一些 Linux 相关的工具、命令的使用

<!--more-->

# neovim 笔记

## new neovim shortcut

| shortcut         | mode | usage                                                                             |
| ---------------- | ---- | --------------------------------------------------------------------------------- |
| jk               | n    | esc                                                                               |
| <Space>nh        | n    | cleaer search result                                                              |
| <Space>+         | n    | increase number                                                                   |
| <Space>-         | n    | decrease number                                                                   |
| <Space>sv, sh    | n    | Create splite window vertical or horizontal                                       |
| <Space>se, sx    | n    | Equal windows size, close window                                                  |
| <Space>sm        | n    | maximize split window, require plugin: vim-maximizer                              |
| <Space>to, tx    | n    | open newt tab, close tab                                                          |
| <Space>tn, tp    | n    | Go to next tab, previous tab                                                      |
| <Ctrl>h,j,k,l    | n    | go to different window, require plugin: tmux-navigator                            |
| ys+w+quote       | n    | add quote to a word, require plugin: vim-surround                                 |
| ds+quote         | n    | delete quote of a word, require plugin: vim-surround                              |
| cs+quote1 quote2 | n    | change quote1 to quote 2 of a word, require plugin: vim-surround                  |
| y w              | n    | copy a word, require plugin: replace-with register                                |
| g rw             | n    | paste and change a word: replace-with register                                    |
| gcc, gc9j        | n    | comment a line or comment 9 lines, require plugin: Comment                        |
| <Space>e         | n    | open explore, requrie plugin: nvim-tree                                           |
| a                | n    | in expoore, type a to add a file                                                  |
| <Space>ff        | n    | find file in current director, require plugin: telescope                          |
| <Space>fs        | n    | find text in current director, require plugin: telescope                          |
| <Space>fc        | n    | find current text under the cursor in current director, require plugin: telescope |
| <Space>fh        | n    | show help information                                                             |
| <Ctrl>k,j        | n    | in telescope output, go to up and down results                                    |
| <Space>ll        | n    | VimTex compile                                                                    |
| <Space>lk        | n    | VimTex compile stop                                                               |
| <Space>lv        | n    | VimTex forward search                                                             |
| <Space>lt        | n    | VimTex toc                                                                        |
| <Space>le        | n    | VimTex find error                                                                 |
| <Space>lc        | n    | VimTex clear aux file                                                             |

> 3 steps to add a plugin in neovim

1. add a plugin in the plugin-setup.lua
2. if the plugin need config, create a corresponding config file in plugin folder. **import the config file in the init.lua file.**
3. if need any shortcut for that plugin, add the corresponding keybinds in the keymaps.lua file

> For LSP, you can go to [mason website](https://github.com/williamboman/mason-lspconfig.nvim) to check all the available lsp server.

LSP shortcuts:

| shortcut | function  |
| -------- | --------- |
| i        | install   |
| X        | uninstall |
| u        | upgrade   |

## neovim shortcut

> `Space` is set to be the **header key**, we can just press Space to see the information table of our Neovim config.

| shortcut  | usage                                                |
| --------- | ---------------------------------------------------- |
| gl        | show error description                               |
| gD        | go to function declaration                           |
| gd        | go to function definition                            |
| gI        | go to implementation                                 |
| gr        | find all the referrences                             |
| K         | show info in popup window                            |
| Space+f   | search document by name                              |
| Space+F   | search text by name                                  |
| Space+lj  | go next                                              |
| Space+lk  | go prev                                              |
| Space+lf  | format document                                      |
| Space+li  | LspInfo                                              |
| Space+lI  | LspInstallInfo                                       |
| Space+la  | code action                                          |
| Space+e   | open explore                                         |
| Shift+l   | choose file on the right                             |
| Shift+h   | choose file on the left                              |
| Ctrl+\    | popup terminal                                       |
| jk        | press jk fast to back to normal mode from enter mode |
| < or >    | in visual mode, move code segment left or right      |
| Shift+j,k | in visual mode, move code segment up or down         |
| gc        | in visual mode, comment all codes                    |

## vim shortcut

| shortcut          | usage                                                |
| ----------------- | ---------------------------------------------------- |
| vsp               | vertical spite window                                |
| sp                | horizontal splite window                             |
| Ctrl+w, <h,j,k,l> | change between the windows                           |
| Ctrl, <h,j,k,l>   | change between the windows <- using keymap in neovim |
| `f,F` target      | find the target, use `;` to find next target         |
| Ctrl+o            | go to the previous location                          |
| Ctrl+i            | go to the next location                              |

1. set colorscheme in vim:
   - add the colorscheme in `plugin.lua` file
   - type `colorscheme darkblue` in vim command windows to use that colorscheme.
   - add `vim.cmd "colorscheme darkblue` in init.lua to use that colorscheme.
2. `"ap`: paste content in register a  
   `"ayaw`: copy current word into register a
3. 搜索替换

- 全文替换：`%s/source/goal/g`
- 替换一行所有匹配项：`s/source/goal/g`, the difference is that we change `%s` into `s`
- 替换某几行所有匹配项：`shift+v` choose some lines, `s/source/goal/g`
- 替换当前行及下面 n 行所有匹配项：`,+ns/source/goal/g`

## install plugin in neovim

1. plugin config file is `plugin.lua`
2. all installed plugins is under `~/.local/share/nvim/`

## add new LSP server in neovim

1. use `LspInstall` to install the corresponding server for your target file. The server will be installed by Packer to path `.local/share/nvim/site/pack/packer/start/`
2. add a config file under `lua/user/lsp/settings` for the language server. This [website](https://github.com/neovim/nvim-lspconfig/tree/master/lua/lspconfig/server_configurations) contains all the template config file for almost all languages.
3. turn on that language server in file `mason.lua`

For example, if I want to install LSP server for LaTex, I do the following things:

1. install language for LaTex, it's `texlab`.
2. create a config file `texlab.lua` under `lua/user/lsp/settings`, and type in the corresponding config codes.
3. I add `texlab` in the _local_servers_ field in `mason.lua`.

## convert init.vim to init.lua

### basic vim config

```vimscript
-- vimscript
set number
set tabstop=4
set shiftwidth=4
set softtabstop=0
set expandtab
set noswapfile
```

```lua
--lua
vim.opt.number = true
vim.opt.tabstop = 4
vim.opt.shiftwidth = 4
vim.opt.softtabstop = 0
vim.opt.expandtab = true
vim.opt.swapfile = false
```

```lua
local set = vim.opt

set.number = true
set.tabstop = 4
set.shiftwidth = 4
set.softtabstop = 0
set.expandtab = true
set.swapfile = false
```

### keymaps

Use `vim.keymap.set` or `vim.api.nvim_set_keymap` to set keymaps in lua.

# tmux

> tmux 是一个终端复用工具，使用 tmux 可以方便的在一个终端窗口里显示多个**session, window, pane**

| shortcut          | usage                  |
| ----------------- | ---------------------- |
| Ctrl+b, %         | vertical splite pane   |
| Ctrl+b, "         | horizontal splite pane |
| Ctrl+b, n         | change between windows |
| Ctrl+b, arrow_key | resize pane            |

Tmux 插件安装：

1. 在~/.tmux.conf 文件中添加对应的插件
2. 进入 tmux 之后使用：Ctrl+d, Shift+i 安装对应的插件即可

# 文件解压缩

1. unrar

```bash
# 解压文件到当前位置
unrar e finename
# 解压文件到指定文件夹
unrar x filename path
```

2. tar

```bash
tar -xzvf filename -C path
```

3. grep

```bash
# 在当前目录下的所有文件里查找target字符串
grep -r "target" .
```

4. 删除所有可执行文件

```bash
ls  -F | grep \* | cut -d \* -f 1 | xargs rm
```

# Git 命令

1. unstage all files in the stage erea: `git reset HEAD -- .`
2. Github Clone: Connection closed by remote host, [Solution Link](https://idreamshen.github.io/posts/github-connection-closed/)

# Makefile 笔记

```bash

# search path, the alternative way is to use `-I` option when using `make` command
VPATH = src:headers
#
# vpath %.h headers
# vpath %.c src

CC := gcc
CFLAGS :=

# source files and object files
cFilesPath=$(wildcard *.c src/*.c)
cFiles=$(notdir $(cFilesPath))
cObjects=$(patsubst %.c,%.o,$(cFiles))


all: $(cObjects) # default make target
	gcc $(cObjects) -o main


# compile .o file for each .c file
$(cObjects): %.o: %.c # static pattern->targets: target-pattern: dependency-pattern
	$(CC) -c $(CFLAGS) $< -o $@  # `$<` means dependency, `$@` means target

.PHONY: clean all

clean:
	@# echo "clean all temp files" # with @, the command will not appear when using `make`
	@echo "all file paths: " $(cFilesPath)
	@echo "all c files: " $(cFiles)
	@echo "all object files: " $(cObjects)
	@$(MAKE) -C src # equal to `cd src && $(MAKE)
	@# -rm *.o main
```
