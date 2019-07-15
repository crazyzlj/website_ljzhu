+++
title= "基于百度地图API获取指定城市地名坐标并生成ESRI Shapefile"
date = "2011-11-12"
tags = ["Python"]
summary = """利用百度地图API查询指定城市地名坐标，并利用ArcPy生成矢量Shapefile文件。
"""
[header]
image = ""
caption = ""
+++

## 1. 需求分析及解决思路

我们经常会想获取一些地点的经纬度坐标，比如北京市所有三甲医院列表及地址，如果对数据精度要求不高（不在意火星坐标的影响），使用百度地图API提供的返回坐标功能恰巧能满足这个需求。

+ 调用+百度地图JS版API+，查询地点并将得到的经纬度坐标保存成+CSV文件+；
+ 利用+Python+调用+Arcpy+将CSV文件中的经纬度转换成+ESRI Shapefile+。

## 2. 实现

+ 程序是2011年11月写的，当时使用的是+百度地图 API JS版 v1.2+，我测试了一下，虽然历经版本迭代更新，这个代码依然可用。图1为运行效果。

![2011-11-12-search-for-coordinates-based-on-baidumap-api.png](http://zhulj-blog.oss-cn-beijing.aliyuncs.com/baidu-API-search-locations/2011-11-12-search-for-coordinates-based-on-baidumap-api.png)

图1 基于百度地图模糊查询地名并返回经纬度坐标

<i class="fa fa-download fa-2x" aria-hidden="true"></i>完整代码如下，[下载](http://zhulj-blog.oss-cn-beijing.aliyuncs.com/baidu-API-search-locations/SearchForLocationCoordinateFromBaiduAPI.html)。

+ 将坐标点+CSV文件+和以下代码放入同一个文件夹下，设置+CSVName+,+XName+和+YName+后运行即可得到+ESRI Shapefile+。

如果没有安装+ArcGIS+，即+Arcpy+不可用，可以选择调用+GDAL+，在此不再赘述。

<i class="fa fa-download fa-2x" aria-hidden="true"></i> [运行示例点坐标下载](http://zhulj-blog.oss-cn-beijing.aliyuncs.com/baidu-API-search-locations/designed_samples.csv)，[Python脚本下载](http://zhulj-blog.oss-cn-beijing.aliyuncs.com/baidu-API-search-locations/CSV2PtsShp.py)

+++python
#! /usr/bin/env python
#coding=utf-8
## Author : Liangjun Zhu
## Email : crazyzlj@gmail.com
## Date : 2015-1-23
## Usage : Convert a .csv filetype points file to a vector shapefile
##         put this .py file in the same folder, input the file name and 
##         x,y column name.
import os,sys
import arcpy
from arcpy import env

def currentPath():
    path = sys.path[0]
    if os.path.isdir(path):
        return path
    elif os.path.isfile(path):
        return os.path.dirname(path)

def CSV2PtsShp(CSVFile,X,Y):
    env.workspace = os.path.dirname(CSVFile)
    PtsShp = os.path.basename(CSVFile)
    PtsShp = PtsShp.split('.')[-2] + ".shp"
    print PtsShp
    try:
        arcpy.MakeXYEventLayer_management(CSVFile,X,Y,"tempLayer","","")
        arcpy.CopyFeatures_management("tempLayer",PtsShp)
    except:
        print arcpy.GetMessages()
        arcpy.AddMessage(arcpy.GetMessages())
    
    print os.path.dirname(CSVFile)
    print "%s Convert to Shp Done!" % CSVFile

if __name__ == '__main__':
    CSVName = "designed_samples.csv"
    XName = "RecommendedX"
    YName = "RecommendedY"
    currFolder = currentPath()
    CSVFile = currFolder + os.sep + CSVName
    CSV2PtsShp(CSVFile,XName,YName)
+++
