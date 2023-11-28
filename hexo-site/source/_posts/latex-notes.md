---
title: LaTex使用笔记
date: 2022-09-08 11:12:10
tags: LaTex
---

# 学习使用LaTex的一些记录

<!--more-->

# LaTeX语法

## 条件编译

类似于C语言的`#ifdefine`，当某个条件判断为真的时候，才会编译对应内容

```latex
  % !TEX program = xelatex
  \newif\ifchinese
  \chinesetrue % comment out to hide chinese
  \documentclass{article}
  \usepackage[UTF8]{ctex}
  \begin{document}

  \ifchinese
  这部分都是中文内容
  \fi
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

其中ad1是bib文件中，对应参考文献的名字3. 准备bib文件，放在跟tex文件的同一个目录下

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

将figure替换成`figure*·`可以让图片横跨两列 3. 插入图表

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

   ![](https://s2.loli.net/2023/11/28/ewVy4SojU29dGrR.png)
