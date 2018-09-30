+++
title= "跨平台(PC、Mac、iPhone)文献管理攻略"
date = "2016-12-30"
tags = ["Zotero"]
summary = """Zotero、Zotfile及坚果云进行跨平台文献管理、同步。"""
[header]
image = ""
caption = ""
+++

## 1.软件

+ Zotero
    + Zotfile
    + Better Bib(La)TeX
+ 坚果云
+ 手机端
	+ Papership (iOS)
+ 插件
	+ Zotero Connector (Chrome 插件)
	+ Word processors add-in

## 2.Zotero配合坚果云进行文献同步

+ Zotero
    + Preference-Advanced-Files and Folders, Base directory填写坚果云同步目录，Data directory location填写Zotero的文件目录（即为Zotero自己的同步目录，免费用户只有300M空间）

+ Better BibTex
    + Citation keys: `[auth:lower]_[journal][>0]_[year]|[auth:lower]_[Title:select,1,1]_[year]`

+ Zotfile
    + General settings, 上面填写Zotero自己的数据目录，下面填写坚果云同步目录，最后一级均为`storage`，如`C:\z_reading\zotero\papers\storage`和`D:\mysync\storage`
    + Use subfolder defined by: `\%w|%T|%I|%t\%y`
    + Renaming rules: `%a_ %y_ %t`

+ Papership

Papership配合坚果云的WebDav服务可以很方便的实现和电脑版一样的体验：浏览文件夹、查看Notes、打开PDF、标注（需app内购）。但是使用WebDav服务有一个对我来讲无法忍受的缺点，同步的文献会被压缩成zip文件传至坚果云，且文件名为无序字符，虽然可以通过PaperShip方便查看，但是并不方便日常查询。

因此，我放弃了这种同步方案，依然采用的是坚果云同步storage文件夹，Zotfile对文献重命名并链接的方案。

## 3.优缺点

+ 优点
  + 多个平台之间文献和PDF文件的同步更新
  + Zotero提供的全文搜索、全文下载等便利功能
  + 可以导出多个Bib(La)TeX格式的引文库，并实时更新
+ 缺点
  + Papership不能直接打开PDF，只能是结合Papership保留的Zotero文件夹结构及Tags和Note+坚果云上完整的规范命名后的PDF文件
  + 使用Zotfile对文献进行重命名后，Zotero对PDF文件是文件链接的方式，因此，删除文献后，PDF文档并不会删除，需得同时手动删除

## 4.文献管理经验

## 4.1.文献搜集整理
+ 文献通过Zotero Connector插件自动添加，可归于多个分类，如研究内容、文章等
+ 添加原文并由Zotfile重命名后存入storage文件夹，由坚果云同步
+ 添加多个Tags方便查找：
  + 文章类型 [原理、方法、应用]
  + 阅读状态 [DONE、TODO、DOING]
  + 借鉴意义 [重要、参考]
+ 添加一条Notes，可通过PaperShip同步编辑，包括但不仅限于以下内容：
  + 文章亮点
  + 研究区简介
  + 方法步骤
  + 共享数据
  + …
+ 设置相关文献 (Related)

## 4.2.文档中插入文献
+ Better BibTeX插件的自动导出功能可以方便地更新文献库，直接用于LaTeX
+ 通过Zotero的Word插件插入文献，不会受其他人修改的影响


## 5.一些改进

### 5.1.Python代码整理storage文件夹
为了方便清理Zotero产生的空白文件夹，以便通过坚果云查找文件，我写了一个简单的Python脚本来删除这些文件夹：

```python
import os
from shutil import rmtree
suffix = ['.pdf', '.doc', '.docx', '.xls', '.xlsx', '.ppt', '.pptx', '.tex', '.txt']
deldirs = []
for root, dirs, files in os.walk(r"D:\mysync\storage"):
    for i in files:
        for suf in suffix:
            if i.find(suf) < 0:
                continue
            else:
                break
        else:  # Can not find any useful documents.
             deldirs.append(root)
deldirs = list(set(deldirs))
for deldir in deldirs:
    print "deleting %s..." % deldir
    rmtree(deldir)
```

+ 修改第4行storage路径为你自己的路径
+ 保存文件为`*.py`，双击即可运行（前提是电脑上正确配置过python）
+ 添加计划任务，每天定期执行该脚本
