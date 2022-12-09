---
title: Linux学习笔记
date: 2022-12-09 10:35:05
tags: Linux
---

本文档记录一些Linux相关的工具、命令的使用
<!--more-->

# tmux
> tmux是一个终端复用工具，使用tmux可以方便的在一个终端窗口里显示多个**session, window, panel**

1. `tmux new -s session_name` will create a session, inside this *session* there is a *window* and a *panel*. We first define **C-b** as **ctrl+b**. The **C-b** is *prefix-key* in tmux, it's followed by *command key*.
	`tmux ls` can list all sessions, `tmux attach -t session_name` can connect to one session. `tmux rename_session -t old_name new_name` can rename a session.
2. `C-b c` will create a new window inside a session, `C-b w` will list all sessions, windows and panels, you can use arrow-key or *h,j,k ,l* to choose a pannel you want. `C-b ,` can rename a window.
	`tmux rename-window -t old_name new_name` can rename a window.
3. `C-b %` can create a new *panel*, `C-b arrow` can choose between the left and right panel. You can type `exit` or `C-d` to close a panel.
	`C-b z` can make a panel to full screen, `C-b z` again can make a panel shrink to its previews size.






