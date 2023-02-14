---
title: Linux学习笔记
date: 2022-12-09 10:35:05
tags: Linux
---

本文档记录一些 Linux 相关的工具、命令的使用

<!--more-->

# neovim 笔记

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

# tmux

> tmux 是一个终端复用工具，使用 tmux 可以方便的在一个终端窗口里显示多个**session, window, pane**

| shortcut          | usage                  |
| ----------------- | ---------------------- |
| Ctrl+b, %         | vertical splite pane   |
| Ctrl+b, "         | horizontal splite pane |
| Ctrl+b, n         | change between windows |
| Ctrl+b, arrow_key | resize pane            |

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
