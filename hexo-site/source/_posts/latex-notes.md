---
title: LaTex使用笔记
date: 2022-09-08 11:12:10
tags: LaTex
---

# 学习使用LaTex的一些记录
<!--more-->

# 我的LaTex模板

## IEEE LaTex模板

```latex
% 文章格式定义 %
\documentclass[conference]{IEEEtran}
\IEEEoverridecommandlockouts
% The preceding line is only needed to identify funding in the first footnote. If that is unneeded, please comment it out.
% \usepackage{cite}
\usepackage{amsmath,amssymb,amsfonts}
\usepackage{algorithmic}
\usepackage{graphicx}
\usepackage{textcomp}
\usepackage{xcolor}
\usepackage[backref]{hyperref}
\def\BibTeX{{\rm B\kern-.05em{\sc i\kern-.025em b}\kern-.08em
		T\kern-.1667em\lower.7ex\hbox{E}\kern-.125emX}}
		
% 文章内容部分 %	
\begin{document}

\title{文章标题}
\maketitle

\begin{abstract}
	% 摘要正文
	{\bf\emph{关键字1，关键字2，etc.}\rm}
\end{abstract}

% 下面是正文部分
\section{Introduction}

% 插入图片
\begin{figure}[htbp]
	\centerline{\includegraphics[width=0.5\textwidth]{images/ml3.png}}
	\caption{How to judge a point is positive or negative}
	\label{ml3}
\end{figure}

% 插入表格
\begin{table}[htb]
	\caption{Description of the data}
	\label{tab:my table}
	\includegraphics[width=0.5\textwidth]{images/him1.png}
\end{table}

% 插入摘要
\bibliographystyle{IEEEtran}
\bibliography{reference}
```



## 中文笔记LaTex模板

```latex
%%%%%%%%%%%% 文章格式 %%%%%%%%%%%%%%%
\documentclass{article}

\usepackage{lipsum}   % 生成随机的内容
\usepackage{ctex}     % 中文输入
\usepackage{metalogo} % 跟LaTex有关的一些logo，如elatex
\usepackage{amsmath,amssymb,amsfonts} % 跟数学公式相关的包
\usepackage{algorithm}            % 代码块
\usepackage[noend]{algpseudocode} % 伪代码
\usepackage{graphicx}          % 图片
\usepackage[backref]{hyperref} % 超链接可以点
\usepackage{multicol}          % 多列文档
\usepackage{enumitem} % 调整上下左右缩进间距，标签样式
\setenumerate[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setitemize[1]{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}
\setdescription{itemsep=0pt,partopsep=0pt,parsep=\parskip,topsep=5pt}


%%%%%%%%%%%% 文章内容 %%%%%%%%%%%%%%%
\title{Hello World}
\author{Fu Jie}


\begin{document}
\maketitle
中文开始


\lipsum


\section{Section 2 Conditional Compile}
	\newcounter{CHINAESE_ENA}
    \setcounter{CHINAESE_ENA}{1}
	\newcounter{ENGLISH_ENA}
    \setcounter{ENGLISH_ENA}{1}

	\ifnum \value{CHINAESE_ENA}>0 {中文部分}{}
	\ifnum \value{ENGLISH_ENA}>0 {English Part}{}

Hello \XeLaTeX and \XeTeX
\[
    a^2+b^2=c^2
\]

% 插入图片
\begin{figure}[htbp]
    \centerline{\includegraphics[width=0.5\textwidth]{images/ad1.png}}
    \caption{How to judge a point is positive or negative}
    \label{ml3}
\end{figure}

% 插入图片当做表格
\begin{table}[htb]
	\caption{Description of the data}
	\label{tab:my table}
	\includegraphics[width=0.5\textwidth]{images/him1.png}
\end{table}


% 插入公式块
\begin{algorithm}[t]
	\caption{algorithm caption} %算法的名字
	\hspace*{0.02in} {\bf Input:} %算法的输入， \hspace*{0.02in}用来控制位置，同时利用 \\ 进行换行
	input parameters A, B, C\\
	\hspace*{0.02in} {\bf Output:} %算法的结果输出
	output result
	\begin{algorithmic}[1]
		\State some description % \State 后写一般语句
		\For{condition} % For 语句，需要和EndFor对应
		\State ...
		\If{condition} % If 语句，需要和EndIf对应
		\State ...
		\Else
		\State ...
		\EndIf
		\EndFor
		\While{condition} % While语句，需要和EndWhile对应
		\State ...
		\EndWhile
		\State \Return result
	\end{algorithmic}
\end{algorithm}

Hello \LaTeX\cite{ad2}

\bibliography{ref}        % 参看文献名
\bibliographystyle{unsrt} % 参考文献格式
\end{document}
```
# 在VS Code中编译LaTex文档

[安装LaTex并且在VSCode中使用LaTex的教程](https://zhuanlan.zhihu.com/p/38178015)

![image-20221128193036967](https://s2.loli.net/2022/11/28/UxTSqdmVvRB6IYF.png)

- 一般当LaTex中我们想要使用参考文献的时候，主要是使用第三个编译方法来编译文档
- 在选定了第三个编译方法作为“默认方法”之后，可以点击右上角的编译按钮进行编译
- 编译的时候可能需要更新一些索引文件，此时如果一直使用第三个编译方法，可能会更新失败。此时只需要使用第二种编译方法（1，2，4都行）编译一下（此时会编译出错），再切换回第三种编译方法，就可以按照更新后的文档内容进行编译了。

# 具体介绍各个LaTex宏包和语法



## 在LaTex中使用中文
> 使用宏包**ctex**即可在LaTex文档中支持中文

```
\documentclass[twocolumn]{article} % 文档使用两列
\usepackage[UTF8]{ctex}
\begin{document}
你好，这是一个测试文档。
\end{document}
```

## 在LaTex中引用文档
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

## LaTex中插入图片和图表
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

## LaTex中插入表格
```
\begin{table}[h!] % h! means the table mast be here
    \centering
    \begin{tabular}{ |p{2cm}||p{2.5cm}|p{2.5cm}|p{2.5cm}|}
        \hline
        a & b & c & d\\
        a & b & c & d\\
        \hline
    \end{tabular}
    \caption{AXI, AHB和APB总线对比}
    \label{tab_compare}
\end{table}
```


# Neovim配置LaTex开发环境
1. 在Mac上按照LaTeX
2. 下载skim PDF reader: `brew install --cask skim`
3. 参考[MacOS使用Nvim+LaTeX+Skim配置高效的论文写作环境](https://blog.51cto.com/u_15366127/5786454)
  - `nvim` + `--headless -c "VimtexInverseSearch %line '%file'"`
  - `nvr` + `--remote-silent +"%line" "%file"`, `cmd+shift+right click` in skim to back search
