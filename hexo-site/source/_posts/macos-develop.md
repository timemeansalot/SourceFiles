---
title: MacOS搭建开发和学习环境
date: 2023-06-20 22:13:57
tags: Tools
---

MacOS 下搭建开发环境如：Python, Scala, Verilog, etc;
学习环境如：LaTex, WPS and other mac handy tools

<!--more-->

# Step by step guide to setup your Macbook for coding and study

[TOC]

**Acknowledgement**: I used to want write a detailed guide of setting the Mac for coding and study, but I give up.
The reason is: I get all the installation guide from Google, and the guide are quite detailed. I don't think it's meaningful to copy their articles here so I just do the following two things:

1. give url to the articles which I read when I try to install these tools.
2. give my own notes about key steps which are not written by these articles.

> Thanks for reading this boring and long article, you can reach me by sending emails to **timemeansalot@gmail.com**.

## Chrome

If you use Safari instead of Chrome, you can skip this part.

1. Open your Safari web browser and type Chrome, then you can go to the main
   website of chrome. Allow download from this website and you can download
   `googlechrome.dmg` under your download folder.
2. Double click the install file, and you can finnaly install chrome on you MAC.

## [Clashx](https://github.com/yichengchen/clashX/releases)

**I Don't know why I want this app, I don't know what can I do with it,
I don't take any responsibility for installing this App and I will not use it**

## [Homebrew](https://brew.sh/)

Mac package manager, very useful for installing apps in Mac.

1. Run the following code in your terminal to install `Homebrew`.
   `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

2. Run the following two command to add homebrew to your PATH.
   `(echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> /Users/fujie/.zprofile`
   `eval "$(/opt/homebrew/bin/brew shellenv)"`
3. Check if homebrew is ready: `brew --version`

## Git

1. install git: `brew install git
2. config git: `cd ~ && mkdir .ssh && cd .ssh`
   `ssh-keygen -t rsa -C 'your email'`
3. copy the `.pub` key to your github setting
4. test: `ssh -T git@github.com'

## Iterm2

Better terminal than the default terminal in Mac.

1. Install command: `brew install --cask iterm2`
2. follow [this guid](https://www.josean.com/posts/terminal-setup) to config Iterm2. It will teach the following things:
   - installing Oh-my-zsh
   - installing powerlevel10K Theme for omz
   - installing Nerd-Font
   - installing zsh plugins
   - config Iterm2 color theme
3. optional: you can follow [dracula iterm2 theme guide](https://draculatheme.com/iterm) to install the dracula theme for Iterm2

## Neovim

It's a better vim tool with a lot of config options.

Make sure **you have good internet connection** before you want to config nvim, the config below will clone a lot of files from Githb.

1. install neovim: `brew install neovim`
2. config neovim
   1. install `stow`: this is a tool for better manager git repos
   2. clone `.env_config` repo
   3. `cd .env_config && stow nvim`
3. install all plugins: `cd ~/.config/nvim/lua/user && nvim plugins.lua`
   <u>Save the file</u>, nvim will **auto install** all the plugins.
4. in nvim, use `TSUpdateSync` to install treesitter plugins.
5. config markdown-preview: markdown-preview can let you see your markdown file **render** effect in neovim, 
   make sure you have `node` and `yarn` installed.
   ```bash
    cd ~/.local/share/nvim/site/pack/packer/start/
    git clone https://github.com/iamcco/markdown-preview.nvim.git
    cd markdown-preview.nvim
    yarn install
    yarn build
   ```
6. install picgo_core: picgo is a picture upload tool to easy upload your picture to image bed.
   nvim is configed to support picgo, we need to install picgo core to support picgo on sysetm,
   follow [this guide](https://github.com/askfiy/nvim-picgo) to install picgo_core.
   ```bash
    npm install picgo -g # install picgo-core
    # set uploader
    picgo set uploader
   ```
   the config file ins under `~/.picgo/config.json`, my config file is showing below:
   ```json
        {
          "picBed": {
            "uploader": "smms",
            "current": "smms",
            "smms": {
              "token": "vPkuQrDtSvj0nXrKgRTQbJqRoxP1msR2",
              "backupDomain": "smms.app"
            }
          },
          "picgoPlugins": {}
        }
   ```
7. formatter: markdown formatter need to start null-ls LSP, and null-ls need you to install prettier on you Mac:
   `brew install prettier`

## Tmux

It's a terminal manager will allow you to quick manage all your terminals.
Follow this [guid](https://www.josean.com/posts/tmux-setup) to config tmux.

1. install Tmux: `brew install tmux`
2. install tpm: `git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm`
3. config Tmux: `cd ~/.env_config && stow tmux`
   `

## tools

1. unzip: `brew install unzip`

## Tools which makes Macbook more easy to ues

> those tools are open source and easy to get, you can get them by Google or App Store

1. [drawio](https://www.drawio.com/): Security-first diagramming for teams
2. [rectangle](https://rectangleapp.com/): Move and resize windows in macOS using keyboard shortcuts or snap areas
3. [betterdisplay](https://github.com/waydabber/BetterDisplay):Custom Resolutions, XDR/HDR Extra Brightness, Dummy Displays, Brightness Adjustment, Picture in Picture, Display and EDID overrides + more!
4. [bartender](https://www.macbartender.com/Bartender4): Bartender is an award-winning app for macOS that superpowers your menu bar, giving you total control over your menu bar items, what's displayed, and when, with menu bar items only showing when you need them.
5. [TickTick](https://ticktick.com/home): job management tools to arrange your day, add todo lists
6. [Typora](https://typora.io/): Typora gives you a seamless experience as both a reader and a writer. It removes the preview window, mode switcher, syntax symbols of markdown source code, and all other unnecessary distractions. Instead, it provides a real live preview feature to help you concentrate on the content itself.
7. [scroll reverser](https://pilotmoon.com/scrollreverser/): reverse the mouse direction
8. [xnip](https://www.xnipapp.com/): screen shot app, free and useful
9. [Bob](https://github.com/ripperhe/Bob): very handy translation and ocr tool on mac
10. [4k video downlaoder](https://www.4kdownload.com/products/videodownloader-34): download youtube videos and playlists
11. [wps](https://www.wps.cn/): office tool, replace of microsoft office
12. [Caffeine](https://www.caffeine-app.net/): prevent your Mac from automatically going to sleep, dimming the screen or starting screen savers.
13. [picgo](https://github.com/Molunerfinn/PicGo/releases): A tool for quickly uploading pictures and getting URL links for pictures. I recommend you
    to **avoid the beta version** of picgo, because the file may be damaged.
14. [latex](https://www.latex-project.org/get/): LaTeX is not a stand-alone typesetting program in itself, but document preparation software that runs on top of Donald E. Knuth's TeX typesetting system. There are 2 ways which I think is convenient to install LaTeX on Mac:
    - `brew install mactex --cask`
    - go to [mactex homepage](https://www.tug.org/mactex/mactex-download.html), download the `MacTex.pkg` file, double click it after downloading, the installed is done.

# Coding Setup

## IDE

1. vscode
2. idea

## Config Python env using Miniconda

1. go to [miniconda website](https://docs.conda.io/en/latest/miniconda.html#macos-installers) to download the installer.
2. install: `cd ~/Downloads && bash xxx.sh`
3. config miniconda to use domestic source, following [this guide](https://mirrors.tuna.tsinghua.edu.cn/help/anaconda/)

## Config for NodeJS

1. install nvm: nvm is nodejs version manager, use `brew install nvm` to install it.  
   After installation, make sure to add nvm to your PATH variable and source `.bashrc` or `.zshrc` file
2. _Optional_: you may need to change nvm source to China if you are in China and want to boot up the download speed:
   ```bash
    export NVM_NODEJS_ORG_MIRROR=http://npm.taobao.org/mirrors/node
    export NVM_IOJS_ORG_MIRROR=http://npm.taobao.org/mirrors/iojs
   ```
3. install nodejs:
   - search all available nodejs: `nvm ls-remote`
   - install nodejs: `nvm install 18`, this command will install nodejs 18 on your Mac
4. _Optional_: config nodejs to use source in China, see the current source of nodejs: `npm config get registry`
   type the following command in your terminal: `npm config set registry https://registry.npm.taobao.org`
5. test nodejs by setting up **hexo website**
   ```bash
   npm install hexo -g # install hexo
   hexo s -g           # render the blog page locally
   brew install pandoc # optional: if blog render step fail
   ```

## Config for Verilog

1. gtkwave: go to [thie website](https://gtkwave.sourceforge.net/), clike **Download** the sourcecode tar.gz file, unzip the file, copy it to Application folder in your Macbook
2. [iverilog](https://github.com/steveicarus/iverilog): `brew install icarus-verilog`
3. [verilator](https://verilator.org/guide/latest/): `brew install verilator`
4. [RISC-V Toolchain](https://github.com/riscv-software-src/homebrew-riscv/blob/main/README.md): follow the link to install RISC-V Toolchain to mac is very easy. The key point is that: _if your are using WiFi, it may fail, you can use your phone's hotpot instead_.
   ```bash
   brew install riscv-tools # install Toolchain
   brew test riscv-tools    # test installation
   which riscv64-unknown-elf-gcc # if this works fine, the Toolchain is ready on your mac
   ```

## Config for Scala and Chisel

1. install scala on mac:

   **Don't install scala manually, Don't install scala manually, Don't install scala manually!!!**, <u>Skip this step, Skip this step, Skip this step</u>

   Because we will use `mill` to manage scala, we don't have to install scala by ourself!!!! DON'T install it by yourself!!!

   `curl -fL https://github.com/VirtusLab/coursier-m1/releases/latest/download/cs-aarch64-apple-darwin.gz | gzip -d > cs && chmod +x cs && (xattr -d com.apple.quarantine cs || true) && ./cs setup`

   The above command is from [this website](https://www.scala-lang.org/download/) and it's for <u>Macbook with Apple silicon</u>.

   - this will install scala related stuff and **<u>sbt</u>**(scala build tool)
   - however, you still have to install **Java Runtime** to run scala, using `brew install openjdk`
     Test installation: `scala -version`  
     **😭NOTES**: make sure you have correctly set `JAVA_HOME` to the right directory, otherwise `sbt` or `mill` will fail to run.
     In MacOS, you can use `/usr/libexec/java_home` command to show the correct `JAVA_HOME` path.

2. mill: Chisel build tool, faster than sbt, but takes more disk space, using `brew install mill` to install mill.  
   After installation, you can use `mill version` to check if mill is correctly installed. There are many ways to install mill on mac.
   - `brew install mill`, this will install the latest version of mill
   - `sh -c "curl -L https://github.com/com-lihaoyi/mill/releases/download/0.9.8/0.9.8 > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"`, 
      this will install mill version 0.9.8, it's the mill version used by **XiangShan** group.

3. follow [chisel-bootcamp guide](https://github.com/freechipsproject/chisel-bootcamp/blob/master/Install.md) to install jupyter and scala kernel for python.

   ```bash
    # install jupyter
    pip3 install --upgrade pip
    pip3 install jupyter --ignore-installed
    pip3 install jupyterlab
    # jupyter backend for Scala
    curl -L -o coursier https://git.io/coursier-cli && chmod +x coursier
    SCALA_VERSION=2.12.10 ALMOND_VERSION=0.9.1

    ./coursier bootstrap -r jitpack \
    -i user -I user:sh.almond:scala-kernel-api_$SCALA_VERSION:$ALMOND_VERSION \
    sh.almond:scala-kernel_$SCALA_VERSION:$ALMOND_VERSION \
    --sources --default=true \
    -o almond

    ./almond --install
    # after installation, You can delete coursier and almond files if you so desire.
   ```
