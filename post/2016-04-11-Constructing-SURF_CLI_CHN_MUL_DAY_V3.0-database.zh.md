+++
title= "批量下载中国地面气候资料日值数据集(V3.0)并建立SQLite数据库"
date = "2016-04-11"
tags = ["Python", "Dataset"]
summary = """利用Python批量下载中国地面气候资料日值数据集(V3.0)数据集，并将原始数据整理为易用格式存入SQLite数据库，随后可根据站点号和起止日期查询数据。
"""
[header]
image = ""
caption = ""
+++

# 0 更新说明
## 0.1.关于时制和日界的问题（2017-7-25）
该数据集采用的是“北京时，日界20时”，也就是说记录为“2013-02-04”的数据应为“2013-02-04 20:00:00”，是“2013-02-03 20:00:01 ~ 2013-02-04 20:00:00 UTC+8” （当然，认为是“2013-02-03 20:00:00 ~ 2013-02-04 19:59:59 UTC+8”也可）这段时间的属性值，转换为UTC时间为“2013-02-04 12:00:00”。

原始数据格式为“YYYY MM DD”，为了方便使用，数据库中统一将时间保存为“**YYYY MM DD 20:00:00**”，即“**北京时 UTC+8**”！

## 0.2.关于数据更新频率
可根据官网的数据更新频率实时更新，一般来讲延迟半年，即2018年6月可获取最新至2017年12月31日的数据。


# 1 需求分析

> “[中国地面气候资料日值数据集(V3.0)](http://data.cma.cn/dataService/index/datacode/SURF_CLI_CHN_MUL_DAY_V3.0.html "SURF_CLI_CHN_MUL_DAY_V3.0")”包含了中国824个基准、基本气象站1951年1月以来本站气压、气温、降水量、蒸发量、相对湿度、风向风速、日照时数和0cm地温要素的日值数据。截至2017年12月31日的数据量为8.35 GB。

降水、气温、风速、相对湿度等气象资料对流域建模是至关重要的数据，[中国气象数据网](http://data.cma.cn/)为我们提供了良好的数据共享平台。其中，最常用的当属中国地面气候资料日值数据集(V3.0)，其站点分布如图1所示（实际下载下来是839个），目前数据已更新至2017年12月。

<img src="http://zhulj-blog.oss-cn-beijing.aliyuncs.com/climate%2Fchina-meteo-sites.jpg" width="600">

**图1. 中国839个基准、基本气象站分布图**

但是，网站更新之后，数据只能按照时间检索，如图2所示，对只想下载某几个站点非常不便。

![search](http://zhulj-blog.oss-cn-beijing.aliyuncs.com/climate%2Fsearch.jpg)

**图2. 中国地面气候资料日值数据集(V3.0)数据检索界面**

但是，这样下载下来是存有每月数据的链接，如图3所示。

<img src="http://zhulj-blog.oss-cn-beijing.aliyuncs.com/climate%2Fdown-links.jpg" width="800">

**图3. 下载链接**

手动逐条下载显然不太现实，即便是逐条下载了，每个数据文件含有800多个站点某个月的某一类指标（降水、气温等）的数据，因此，如果想得到某个站点某时间段内所有气象指标数据，实属不易。

因此，考虑：

+ 1.批量下载数据文件（txt）；

+ 2.读取数据并按站点存入数据库（SQLite）；

+ 3.按照站点及时间范围从数据库中提取数据。

# 2 实现

## 2.1 批量下载

批量下载比较简单，调用`urllib2`库即可，核心代码如下：

```python
def downloadByUrl(curUrl, filePath):
    f = urllib2.urlopen(curUrl)
    data = f.read()
    with open(filePath, "wb") as code:
        code.write(data)
```

## 2.2 存入数据库

包括气象站点数据结构及如何写入SQLite数据库代码设计。

### 2.2.1 气象站点数据结构

+ 原始记录中，每条记录均包含站点编号、经纬度、高程，造成数据冗余，因此设计一个站点父类`climateStation`，保存这些信息：

```python
class climateStation:
    '''
    base class of climate station
    :method: init(ID, lat, lon, alti)
    :method: printSation()
    '''
    def __init__(self, ID = '', lat=9999, lon=9999, alti=9999):
        self.count     = 0
        self.StationID = ID    ## 5 digits
        self.lat       = lat   ## latitude, float degree
        self.lon       = lon   ## longitude, float degree
        self.alti      = alti  ## altitude, as ORIGIN: unit 0.1 meter
    def printStation(self):
        print('%s, %.3f, %.3f, %.1f' % (self.StationID, self.lat, self.lon, self.alti)
```

+ 随后设计子类`climateFeatures`，用于保存每个站点所有的气象数据，其中`initValues()`方法用于添加一天记录时进行赋初值，`assignValuesByFtCode(idx, ftCode, ClimValues)`方法根据索引`idx`、气象数据类型`ftCode`和数据值`ClimValues`对当天数据进行修改，`check()`方法用于检查该站点数据是否具有一致条数，`printFeature()`方法用于打印该站点信息：

```python
class climateFeatures(climateStation):
    '''
    sub-class of climate feature
    :method: init(ID, lat, lon, alti)
    :method: initValues()
    :method: assignValuesByFtCode(idx, ftCode, ClimValues)
    :method: check()
    :method: printFeature()
    '''
    def __init__(self, ID = '', lat=9999, lon=9999, alti=9999):
        climateStation.__init__(self, ID, lat, lon, alti)
        self.count     = 0
        self.date      = []    ## date
        self.avgPRS    = []    ## average pressure of the day, ORIGIN: unit 0.1 hPa
        self.maxPRS    = []    ## maximum pressure of the day, ORIGIN: unit 0.1 hPa
        self.minPRS    = []    ## minimum pressure of the day, ORIGIN: unit 0.1 hPa
        self.avgTEM    = []    ## average temperature of the day, ORIGIN: unit 0.1 degree
        self.maxTEM    = []    ## maximum temperature of the day
        self.minTEM    = []    ## minimum temperature of the day
        self.avgRHU    = []    ## average relative humidity, unit 1%
        self.minRHU    = []    ## minimum relative humidity, nuit 1%
        self.PRE208    = []    ## precipitation from 20:00 to 8:00
        self.PRE820    = []    ## precipitation from 8:00 to 20:00
        self.PRE       = []    ## precipitation from 20:00 to 20:00, ORIGIN: unit 0.1 mm
        self.smEVP     = []    ## small evaporation, ORIGIN: unit 0.1 mm
        self.lgEVP     = []    ## large evaporation, ORIGIN: unit 0.1 mm
        self.avgWIN    = []    ## mean wind speed, ORIGIN: unit 0.1 m/s
        self.maxWIN    = []    ## maximum wind speed, ORIGIN: unit 0.1 m/s
        self.maxWINASP = []    ## aspect of maximum wind speed
        self.extWIN    = []    ## extreme wind speed
        self.extWINASP = []    ## aspect of extreme wind speed
        self.SSD       = []    ## sunshine duration hours, ORIGIN: 0.1 hour
        self.avgGST    = []    ## average ground surface temperature of the day, ORIGIN: 0.1 degree
        self.maxGST    = []    ## maximum ground surface temperature of the day, ORIGIN: 0.1 degree
        self.minGST    = []    ## minimum ground surface temperature of the day, ORIGIN: 0.1 degree
        
        
    def initValues(self):
        self.count += 1
        self.avgPRS.append(9999)
        self.maxPRS.append(9999)
        self.minPRS.append(9999)
        self.avgTEM.append(9999)
        self.maxTEM.append(9999)
        self.minTEM.append(9999)
        self.avgRHU.append(9999)
        self.minRHU.append(9999)
        self.PRE208.append(9999)
        self.PRE820.append(9999)
        self.PRE.append(9999)
        self.smEVP.append(9999)
        self.lgEVP.append(9999)
        self.avgWIN.append(9999)
        self.maxWIN.append(9999)
        self.maxWINASP.append(9999)
        self.extWIN.append(9999)
        self.extWINASP.append(9999)
        self.SSD.append(9999)
        self.avgGST.append(9999)
        self.maxGST.append(9999)
        self.minGST.append(9999)
        
    def assignValuesByFtCode(self, idx, ftCode, ClimValues):
        ## ['PRS', 'TEM', 'RHU', 'PRE', 'EVP', 'WIN', 'SSD', 'GST']
        if ftCode == 'PRS' and len(ClimValues) == 3:
            self.avgPRS[idx] = ClimValues[0]
            self.maxPRS[idx] = ClimValues[1]
            self.minPRS[idx] = ClimValues[2]
        elif ftCode == 'TEM' and len(ClimValues) == 3:
            self.avgTEM[idx] = ClimValues[0]
            self.maxTEM[idx] = ClimValues[1]
            self.minTEM[idx] = ClimValues[2]
        elif ftCode == 'RHU' and len(ClimValues) == 2:
            self.avgRHU[idx] = ClimValues[0]
            self.minRHU[idx] = ClimValues[1]
        elif ftCode == 'PRE' and len(ClimValues) == 3:
            self.PRE208[idx] = ClimValues[0]
            self.PRE820[idx] = ClimValues[1]
            self.PRE[idx] = ClimValues[2]
        elif ftCode == 'EVP' and len(ClimValues) == 2:
            self.smEVP[idx] = ClimValues[0]
            self.lgEVP[idx] = ClimValues[1]
        elif ftCode == 'WIN' and len(ClimValues) == 5:
            self.avgWIN[idx] = ClimValues[0]
            self.maxWIN[idx] = ClimValues[1]
            self.maxWINASP[idx] = ClimValues[2]
            self.extWIN[idx] = ClimValues[3]
            self.extWINASP[idx] = ClimValues[4]
        elif ftCode == 'SSD' and len(ClimValues) == 1:
            self.SSD[idx] = ClimValues[0]
        elif ftCode == 'GST' and len(ClimValues) == 3:
            self.avgGST[idx] = ClimValues[0]
            self.maxGST[idx] = ClimValues[1]
            self.minGST[idx] = ClimValues[2]
        else:
            exit(1)
    def check(self):
        if self.count == len(self.date) \
                == len(self.avgPRS) == len(self.maxPRS) == len(self.minPRS) \
                == len(self.maxTEM) == len(self.minTEM) == len(self.avgTEM) \
                == len(self.avgRHU) == len(self.minRHU) \
                == len(self.PRE208) == len(self.PRE820) == len(self.PRE) \
                == len(self.smEVP) == len(self.lgEVP) \
                == len(self.avgWIN) == len(self.maxWIN) == len(self.maxWINASP) \
                == len(self.extWIN) == len(self.extWINASP) == len(self.SSD) \
                == len(self.avgGST) == len(self.maxGST) == len(self.minGST):
            return True
        else:
            return False
    def printFeature(self):
        print('%s, lat=%.3f, lon=%.3f, alti=%.1f, count=%d, date=%s, PRS=%s, TEM=%s,'
              ' RHU=%s, PRE=%s, EVP=%s, WIN=%s, SSD=%s, GST=%s' %
              (self.StationID, self.lat, self.lon, self.alti, self.count, self.date,
               self.avgPRS, self.avgTEM, self.avgRHU, self.PRE,
               self.lgEVP, self.avgWIN, self.SSD, self.avgGST))
```

### 2.2.2 写入SQLite数据库

逐个数据文件读取完之后，得到存有所有站点所有数据的数据字典，即：

```python
all_station_climate_data = {}  ##  format: StationID: climateFeatures()
```
设计函数`writeClimateDataToDatabase(allClimData, dbpath)`将数据写入数据库：

```python
def writeClimateDataToDatabase(allClimData, dbpath):
    '''
    write climate data to database
    :param allClimData: climate data of all stations' directionary
    :param dbpath: path of Sqlite database
    '''
    print "Write climate data to database..."
    conn = sqlite3.connect(dbpath)
    count = 1
    for station in allClimData:
        print "---%d / %d, station ID: %s..." % (count, len(allClimData), allClimData[station].StationID)
        count += 1
        stationTabName = 'S' + allClimData[station].StationID
        create_climdata_tab_sql = '''CREATE TABLE IF NOT EXISTS %s (
                        stID varchar(5) NOT NULL,
                        date datetime DEFAULT NULL,
                        avgPRS int DEFAULT 9999,
                        maxPRS int DEFAULT 9999,
                        minPRS int DEFAULT 9999,
                        avgTEM int DEFAULT 9999,
                        maxTEM int DEFAULT 9999,
                        minTEM int DEFAULT 9999,
                        avgRHU int DEFAULT 9999,
                        minRHU int DEFAULT 9999,
                        PRE208 int DEFAULT 9999,
                        PRE820 int DEFAULT 9999,
                        PRE int DEFAULT 9999,
                        smEVP int DEFAULT 9999,
                        lgEVP int DEFAULT 9999,
                        avgWIN int DEFAULT 9999,
                        maxWIN int DEFAULT 9999,
                        maxWINASP int DEFAULT 9999,
                        extWIN int DEFAULT 9999,
                        extWINASP int DEFAULT 9999,
                        SSD int DEFAULT 9999,
                        avgGST int DEFAULT 9999,
                        maxGST int DEFAULT 9999,
                        minGST int DEFAULT 9999
                        )''' % stationTabName
        #print create_climdata_tab_sql
        ### create current station climate data table
        createTable(create_climdata_tab_sql, conn)
        ### insert station information
        curClimateData = allClimData[station]
        fetchone_sql = 'SELECT * FROM %s WHERE stID = ? AND date = ?' % stationTabName
        update_sql = '''UPDATE %s SET avgPRS = ?, maxPRS = ?, minPRS = ?, \
                        avgTEM = ?, maxTEM = ?, minTEM = ?, avgRHU = ?, minRHU = ?,\
                        PRE208 = ?, PRE820 = ?, PRE = ?, \
                        smEVP = ?, lgEVP = ?, avgWIN = ?, maxWIN = ?,\
                        maxWINASP = ?, extWIN = ?, extWINASP = ?, SSD = ?,\
                        avgGST = ?, maxGST = ?, minGST = ? WHERE stID = ? AND date = ?''' \
                     % stationTabName
        save_sql = '''INSERT INTO %s values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)''' % stationTabName
        for i in range(curClimateData.count):
            # If the current station record exists, then update it, else insert one.
            uniqueitem = [curClimateData.StationID, curClimateData.date[i]]
            dataRow = [curClimateData.StationID, curClimateData.date[i],
                       curClimateData.avgPRS[i], curClimateData.maxPRS[i], curClimateData.minPRS[i],
                       curClimateData.avgTEM[i], curClimateData.maxTEM[i], curClimateData.minTEM[i],
                       curClimateData.avgRHU[i], curClimateData.minRHU[i],
                       curClimateData.PRE208[i], curClimateData.PRE820[i],
                       curClimateData.PRE[i], curClimateData.smEVP[i], curClimateData.lgEVP[i],
                       curClimateData.avgWIN[i], curClimateData.maxWIN[i],
                       curClimateData.maxWINASP[i],
                       curClimateData.extWIN[i], curClimateData.extWINASP[i],
                       curClimateData.SSD[i],
                       curClimateData.avgGST[i], curClimateData.maxGST[i], curClimateData.minGST[i]]
            # print(dataRow)
            if fetchOneRecord(conn, fetchone_sql, uniqueitem):
                updateRecord(conn, update_sql, dataRow[2:] + uniqueitem)
                continue
            saveRecord(conn, save_sql, dataRow)
    conn.commit()
    conn.close()
```

## 2.3 读取数据库

读取数据库设计，包括查询条件输入格式及查询函数设计。

### 2.3.1 输入查询条件

查询条件包括站号（为空则查询所有站点），起始时间和终止时间：

```python
## Input parameters
    SQLITE_DB_PATH = r'...\SURF_CLI_CHN_MUL_DAY_V3.0.db'
    QUERY_STATION_IDs = []       ## leave it blank to query all stations
    QUERY_DATE_FROM = [1951,1,1] ## format: Year, Month, Day
    QUERY_DATE_END  = [2015,12,31]
    SAVE_PATH = r'...\results'
```

### 2.3.2 查询函数设计

输出为：

+ 1.站点经纬度、高程信息文件：`stationInfo.csv`

+ 2.按站点名命名的气象数据文件：e.g., `S50527.csv`

```python
def QueryDatabase(dbpath, savePath, stationIDs, startTime, endTime):
    '''
    Query and save data from Sqlite database
    :param dbpath:
    :param savePath:
    :param stationIDs:
    :param startTime:
    :param endTime:
    :return:
    '''
    tableList = getTablesList(dbpath)
    conn = sqlite3.connect(dbpath)
    stationInfoCSVPath = savePath + os.sep + 'stationInfo.csv'
    stationInfoData = []
    if stationIDs == []:
        stationIDs = getTablesList(dbpath)
    else:
        for i in range(len(stationIDs)):
            stationIDs[i] = 'S' + stationIDs[i]
    for tabName in stationIDs:
        #tabName = 'S' + stationID
        stationID = tabName[1:]
        if tabName in tableList:
            csvPath = savePath + os.sep + tabName + '.csv'
            startT = datetime.datetime(startTime[0], startTime[1], startTime[2])
            endT = datetime.datetime(endTime[0], endTime[1], endTime[2])
            startTStr = startT.strftime("%Y-%m-%d %H:%M:%S")[:10]
            endTStr = endT.strftime("%Y-%m-%d %H:%M:%S")[:10]
            fetch_data_sql = '''SELECT * FROM %s WHERE date BETWEEN "%s" AND "%s" ORDER BY date''' % (tabName, startTStr, endTStr)
            #print fetch_data_sql
            data = fetchData(conn,fetch_data_sql)
            saveToCSV(data, csvPath)
            fetch_station_sql = '''SELECT * FROM stationInfo WHERE stID=%s ''' % (stationID)
            stationInfoData.append(fetchData(conn,fetch_station_sql))
    saveToCSV(stationInfoData, stationInfoCSVPath,'stationInfo')
    conn.close()
```

# 3 站点经纬度及高程信息

<i class="fa fa-exclamation-triangle fa-2x" aria-hidden="true"></i> 当完成数据库构建之后，我查询了几个站点，发现经纬度和高程信息与之前看到的有细微差异！

检查后发现，我的代码是以站点编号进行索引的，而默认了其经纬度、高程信息是正确且无误的。

显然，事实并非如此，我又重新跑了一遍数据，找到并总结了每个站点的不同信息（经纬度和高程），比如下图这样，不知道气象共享网的数据库是怎么设计的，**难道没有检查过站点的经纬度和高程信息吗**？

![stations_lat_lon_alti](http://zhulj-blog.oss-cn-beijing.aliyuncs.com/climate%2Fstations_latlonalti.jpg)

<i class="fa fa-download fa-2x" aria-hidden="true"></i>Excel表格可以点击[这里](http://zhulj-blog.oss-cn-beijing.aliyuncs.com/climate%2Fstations_all-%E6%89%80%E6%9C%89%E7%AB%99%E7%82%B9%E7%9A%84%E6%89%80%E6%9C%89%E4%B8%8D%E5%90%8C%E7%9A%84%E7%BB%8F%E7%BA%AC%E5%BA%A6%E9%AB%98%E7%A8%8B.csv "all_stations_latlonalti")下载。


# 4 总结

+ 就是为了简单实现这么个功能，代码没进行优化设计，8G多的数据读取并存入一个数据字典中，非常耗时。

+ 最终得到的SQLite数据库文件大小为**1.61** GB，SQLite打开如图4。

<img src="http://zhulj-blog.oss-cn-beijing.aliyuncs.com/climate%2Fsqlite-jietu.jpg" width="600">

**图4. SURF_CLI_CHN_MUL_DAY_V3.0数据库截图**


# 5 数据获取

自从本博客发表以来，已经累计帮助了几十位同学、老师、同行。如果对该数据集有兴趣，可邮件联系。

另外，欢迎技术交流。

Github: [创建数据库](https://github.com/crazyzlj/Python/blob/master/HydroDataDownload/CreateDatabase_SURF_CLI_CHN_MUL_DAY.py)、[查询数据库](https://github.com/crazyzlj/Python/blob/master/HydroDataDownload/ReadDatabase_SURF_CLI_CHN_MUL_DAY.py)

Email: crazyzlj@gmail.com
