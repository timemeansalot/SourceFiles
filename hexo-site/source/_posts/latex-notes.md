---
title: LaTex使用笔记
date: 2022-09-08 11:12:10
tags: LaTex
---

# 学习使用LaTex的一些记录
<!--more-->

# 我的LaTex中所用的包
```
\usepackage[UTF8]{ctex}
\usepackage{cite}
\usepackage{amsmath,amssymb,amsfonts}
\usepackage{algorithmic}
\usepackage{graphicx}         % 图片
\usepackage{textcomp}
\usepackage{xcolor}
\usepackage[backref]{hyperref} % 超链接可以点
\usepackage{multicol}          % 多列文档

\usepackage{enumitem}
\setenumerate[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setitemize[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setdescription{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}


\begin{document}
\title{基于AHB的Bus Matrix设计}
\author{付杰}

\maketitle
\thispagestyle{empty} % 目录不显示页码


\newpage
\tableofcontents      % 目录
\pagenumbering{roman} % 希腊页码
\newpage

\setcounter{page}{1}   % 起始页
\pagenumbering{arabic} % 数字页码
```
[安装LaTex并且在VSCode中使用LaTex的教程](https://zhuanlan.zhihu.com/p/38178015)

# 在LaTex中使用中文
> 使用宏包**ctex**即可在LaTex文档中支持中文

```
\documentclass[twocolumn]{article} % 文档使用两列
\usepackage[UTF8]{ctex}
\begin{document}
你好，这是一个测试文档。
\end{document}
```

# 在LaTex中引用文档
1. 在文档末尾\end{document}之前申明要使用*引用*
```
\bibliographystyle{IEEEtran}
\bibliography{reference}

\end{document}
```
2. 在需要引用的地方，使用`\cite[]{name}`来引用对应的参考文献
```
\cite{ad1}
```
其中ad1是bib文件中，对应参考文献的名字
3. 准备bib文件，放在跟tex文件的同一个目录下

# LaTex中插入图片和图表
1. 在文档开头使用graphicx包
```
\usepackage{graphicx}
```
2. 插入图片
```
\begin{figure}[htbp]
	\centerline{\includegraphics[width=0.5\textwidth]{images/him7.png}}
	\caption{Confusion matrices of 5 methods}
	\label{him7}
\end{figure}
```
将figure替换成`figure*·`可以让图片横跨两列
3. 插入图表
```
\begin{table*}[htb]
	\caption{Summary of related work}
	\label{tab2}
	\includegraphics[width=\textwidth]{images/him6.png}
\end{table*}
```
4. 引用图表
```
\ref*{tab2} % 在文档中引用图表的label即可引用图表
```

# LaTex中插入表格
