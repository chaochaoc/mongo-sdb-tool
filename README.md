## Mongo Transfer Sdb 工具使用说明

#### 概述

​		工具用于从mongo迁移应用数据到sdb， 其功能涵盖了从mongo查看数据库，查看数据表，查看索引，导出数据和sdb创建域，创建集合，创建索引等功能。



#### 环境

		- 本工具有/bin/bash shell语言编写，执行需要依赖4个外部工具， 否则程序将不能正常执行

    sdb		                  sdb shell 连接工具
    sdbimprt				  sdb 数据导入工具		
    mongo  					  mongo shell 连接工具
    mongoexport				  mongo 数据导出工具

- **建议：**（如果mongo安装在同一环境同一用户下，请忽略）
  - 拷贝工具  ```sdb```  和  ```sdbimprt```   到Mongo所在环境下, 并赋予mongo管理用户执行权限
  - 使用mongo管理用户进行操作
- 由于在部分操作系统中，sh和bash解释器有不兼容现象，请使用  ```./脚本名``` 执行程序，而并非  ```sh 脚本名``` 



#### 帮助

```
Usage: ./mongo_transfer_sdb.sh Operation

Operation:
	listDatabases		列出mongo的所有数据库
		-g arg			可选，用于过滤条件，eg: '-g SAT00' 将列出所有包含'SAT00'的数据库
		-G				可选，自动过滤掉所有系统库
		-F 				可选，将查询所得的数据库写入到文件'.mongo.database.list'中
    listCollections		列出mongo的数据表，注：仅列出在文件'.mongo.database.list'中的数据库中的表
		-F				可选，将查询所得的数据表写入到文件'.mongo.collection.list'中
	listIndexes			列出mongo的索引，注：仅列出在文件'.mongo.collection.list'中的数据表的索引
		-I 				可选，索引将包含'_id_'索引
		-F 				可选，将查询所得的索引信息写入到文件'.mongo.index.json'中
	createSdbDomain		创建sdb的数据域，将会包含所有数据组
		-n arg			可选，设置域的名字，缺省时域名为'all_groups'
	createSdbCL			创建sdb集合，注：仅创建在文件'.mongo.collection.list'中的集合
	createSdbIndex		创建sdb集合，注：仅创建在文件'.mongo.index.json'中的索引
	exportFromMongo		导出mongo中的document，注：仅导出一个集合的document
		-p arg			必选，设置数据导出的路径，注：请确保目录存在且为空
		-A              可选，将导出所有在文件'.mongo.collection.list'中的集合下的所有数据
		-I              可选，导出数据时是否包含'_id'字段，默认不包含
	importToSdb		 	导入数据到sdb
		-p arg			必选，设置json数据的路径，工具依照文件名匹配对应集合，请勿更改
```



#### 步骤

- 解压工具

```shell
tar -zxvf mongo-sdb-tool.tar.gz
```



- 修改配置文件 

```
vim authentication
```

```properties
mongo.host=localhost
mongo.port=27017
mongo.user=
mongo.pswd=

sdb.host=localhost
sdb.port=11810
sdb.user=sdbadmin
sdb.pswd=sdbadmin
#domain可不设置，若此次处设置domain则必须通过本工具创建domain(domain即上文所提‘域’、‘数据域’)
sdb.domain=
```



- 赋予工具执行权限 

```
chmod u+x mongo_transfer_sdb.sh
```



- 查询mongo中的数据库信息

```shell
# 本命令将所有除[admin|config|local|test]外的所有数据库写入文件
./mongo_transfer_sdb.sh listDatabases -G -F
```



- 查询mongo中的数据表信息

```shell
# 注：执行此命令前，请确保'.mongo.database.list'文件存在
# 此命令将列出'.mongo.database.list'中包含的数据库中的数据表，并将结果写入文件
./mongo_transfer_sdb.sh listCollections -F
```



- 创建sdb数据域(domain)   （注：如果配置文件authentication已配置，请忽略此步）

```shell
# 创建名为‘all_groups’的domain, 如果不喜欢改名，请配合 -n 使用
./mongo_transfer_sdb.sh createSdbDomain
```



- 创建sdb集合

```shell
# 创建在文件‘.mongo.collection.list’中的所有集合，所以请确保该文件存在
./mongo_transfer_sdb.sh createSdbCL
```



- 将数据从mongo导出

```shell
# 将导出在文件‘.mongo.collection.list’中的所有集合下的数据到/data/目录下,文件名为‘库名.表名.json’
# 注意：执行命令前请确保数据目录为空，执行成功后请勿修改文件名
./mongo_transfer_sdb.sh exportFromMongo -p /data/ -A
```



- 将数据导入到sdb

```shell
./mongo_transfer_sdb.sh importToSdb -p /data/ 
```



- 列出mongo表中的索引信息

```shell
# 保存索引信息到文件，需确保文件‘.mongo.collection.list’存在
./mongo_transfer_sdb.sh listIndexes -F
```



- 创建sdb索引

```shell
./mongo_transfer_sdb.sh createSdbIndex
```



#### 后记

- 感谢使用
- 工具未通过专业测试，使用时请尽量按照步骤使用，在使用过程中请勿删除或修改所在目录下的隐藏文件，以免给您造成不必要的困扰
- 如果您在使用过程中发现了bug或有什么更好的建议，请您联系我，我将万分感激
- 我的邮箱    ```liangchao@sequoiadb.com```

