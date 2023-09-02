---
title: 一生一芯记录
date: 2023-03-13 15:45:26
top: true
tags:
  - RISCV
  - YSYX
---

> 一生一芯学习讲义

# 环境配置相关

1. [安装Ubuntu教程](https://timemeansalot.github.io/2023/08/30/linux-setup/)
2. [环境配置脚本](https://github.com/timemeansalot/env_config/blob/linux/env-install-scripts.sh)：配置verilator, risc-v toolchians
3. 获取ysyx-workbench:
   ```bash
       git clone -b master git@github.com:OSCPU/ysyx-workbench.git
       git branch -m master
       bash init.sh npc
       bash init.sh nvboard
       bash init.sh nemu
       bash init.sh bastract-machine
       bash init.sh abstract-machine
       bash init.sh am-kernels
       source ~/.zshrc
       cd nemu
       make menuconfig # config nemu
       make            # build nemu
       make run        # run nemu
       make gdb        # debug nemu
   ```

# TODOS

> 暂时没有时间去学习的知识

- [ ] [Chisel](https://ysyx.oscc.cc/docs/2306/prestudy/0.5.html)
- [ ] [数字电路基础实验](https://nju-projectn.github.io/dlco-lecture-note/index.html)
