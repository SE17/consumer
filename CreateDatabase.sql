--创建数据库
CREATE DATABASE OnlineOrderVegetable
   ON  PRIMARY  --默认就属于PRIMARY主文件组，可省略
(
	 NAME='OnlineOrderVegetable',  --主数据文件的逻辑名
	 FILENAME='E:\SoftwareProject\teamwork\datafile\OnlineOrderVegetable.mdf', 
				 --主数据文件的物理名
	 SIZE=50mb,			--主数据文件初始大小 
	 FILEGROWTH=20%		--主数据文件的增长率
)
LOG ON
(
  NAME='OnlineOrderLog',
  FILENAME='E:\SoftwareProject\teamwork\datafile\OnlineOrderLog.ldf',
  SIZE=10mb,
  MAXSIZE=50MB,
  FILEGROWTH=10MB
)
GO
