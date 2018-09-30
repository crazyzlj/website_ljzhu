+++
title = "Automatic approach to deriving fuzzy slope positions(模糊坡位提取自动化方法)"
date = 2018-03-01T00:00:00
draft = false

# Authors. Comma separated list, e.g. `["Bob Smith", "David Jones"]`.
authors = ["<b><I>朱良君</I></b>", "朱阿兴", "秦承志*", "刘军志"]

# Publication type.
# Legend:
# 0 = Uncategorized
# 1 = Conference paper
# 2 = Journal article
# 3 = Manuscript
# 4 = Chinese publication
# 5 = Book
# 6 = Book chapter
publication_types = ["2"]

# Publication name and optional abbreviated version.
publication = "Geomorphology, 304:173-183. doi:10.1016/j.geomorph.2017.12.024"
publication_short = "Geomorphology"

# Abstract and optional shortened version.
abstract = "坡位（如山脊、背坡、沟谷）的空间渐变特征可为地理建模提供重要的地形信息，这种空间渐变可用空间位置对坡位的模糊隶属度（或称相似度）值定量刻画，称之为模糊坡位。多数基于模糊分类思路的模糊坡位提取方法在数据准备和参数设定时需要大量人为干预，如Qin等（2009）提出的基于原型的模糊推理方法主要包括准备地形属性集、选取坡位典型位置及确定模糊推理参数三个步骤，易用性较差。模糊坡位通常采用的通用地形属性，包括一阶（如坡度）和二阶（如曲率）局部地形属性和区域地形属性（如相对位置指数），可通过自动化算法提取。坡位典型位置可通过地形属性及对应属性范围叠加后得到，属性范围可根据该地形属性的模糊推理函数形状及中心值确定，如S型函数取大于中心值的属性范围。模糊推理函数及参数可结合领域知识和对地形属性频率分布的数据挖掘（如bi-Gaussian模型）得到，如坡度一般由山脊增加至背坡然后减小至沟谷，因此坡度对于背坡的推理函数形状为钟形，结合bi-Gaussian模型拟合结果可最终确定推理参数。基于上述思路，以五类基本坡位为例，实现了一种模糊坡位提取自动化工作流，默认仅需输入研究区格网DEM即可得到提取模糊坡位信息，并允许自定义工作流配置（如参与推理的地形属性等）。自动化工作流涉及的计算密集型算法均基于消息传递并行库实现以提高计算效率。通过两个不同地形特征的研究区应用，表明了所提自动化方法的合理性、易用性和高效性。所提自动化方法思路可为类似地理学空间分析方法的自动化提供借鉴。"
abstract_short = "多数基于模糊分类思路的模糊坡位提取方法在数据准备和参数设定时需要大量人为干预，如Qin等（2009）提出的基于原型的模糊推理方法主要包括准备地形属性集、选取坡位典型位置及确定模糊推理参数三个步骤，易用性较差。以五类基本坡位为例，实现了一种模糊坡位提取自动化工作流，默认仅需输入研究区格网DEM即可得到提取模糊坡位信息，并允许自定义工作流配置（如参与推理的地形属性等）。自动化工作流涉及的计算密集型算法均基于消息传递并行库实现以提高计算效率。"

# Featured image thumbnail (optional)
image_preview = ""

# Is this a selected publication? (true/false)
selected = true

# Projects (optional).
#   Associate this publication with one or more of your projects.
#   Simply enter your project's filename without extension.
#   E.g. `projects = ["deep-learning"]` references `content/project/deep-learning.md`.
#   Otherwise, set `projects = []`.
projects = ["2014-phd-dissertation"]

# Tags (optional).
#   Set `tags = []` for no tags, or use the form `tags = ["A Tag", "Another Tag"]` for one or more tags.
tags = ["坡位", "模糊隶属度", "自动化", "并行计算"]

# Links (optional).
url_pdf = "https://www.sciencedirect.com/science/article/pii/S0169555X17300612"
url_preprint = ""
url_code = "https://github.com/lreis2415/AutoFuzSlpPos"
url_dataset = ""
url_project = ""
url_slides = ""
url_video = ""
url_poster = ""
url_source = ""

# Custom links (optional).
#   Uncomment line below to enable. For multiple links, use the form `[{...}, {...}, {...}]`.
#url_custom = [{name = "Custom Link", url = "http://example.org"}]

# Digital Object Identifier (DOI)
doi = "10.1016/j.geomorph.2017.12.024"

# Does this page contain LaTeX math? (true/false)
math = false

# Does this page require source code highlighting? (true/false)
highlight = false

# Featured image
# Place your image in the `static/img/` folder and reference its filename below, e.g. `image = "example.jpg"`.
[header]
image = ""
caption = ""

+++
