--使用数据库
use OnlineOrderVegetable
go
--创建表
--用户类别表
CREATE TABLE usertype				
(
	usertype_id char(10) not null,		--用户类别编号uty开头
	usertype_name char(4),			--用户类别名称
	CONSTRAINT PK_UserType PRIMARY KEY(usertype_id)
)
GO
--网站用户表
CREATE TABLE webuser					--网站用户表
(
	webuser_id char(10) not null,		--用户编号u开头
	usertype_id char(10),				--用户类别id
	user_account varchar(50) not null,			--登录账号
	user_pwd VARBINARY(50)  not null,			--密码
	user_name nvarchar(20) null,			--用户昵称
	user_sex char(2) null,			--用户性别
	usr_tel char(11) not null,			--改成手机,11位
	user_icon varchar(50),
	user_point int default 0,
	reg_time datetime DEFAULT GETDATE() ,				--注册时间
	bank_card char(19) null,
	balance money null  DEFAULT 0.0,
	pay_pwd varchar(20) null,			--支付密码
	CONSTRAINT PK_webuser PRIMARY KEY(webuser_id),
	CONSTRAINT FK_webuser_usertype FOREIGN KEY (usertype_id) REFERENCES usertype(usertype_id),	
)
GO


--商品类别表
CREATE TABLE protype
(
	protype_id char(10) not null, --商品类别编号pty开头
	protype_name nvarchar(10) not null,	   --商品类别名字
	constraint pk_protype primary key(protype_id)
)
GO
--商品表
CREATE TABLE produce				
(
	pro_id char(10) not null,	--商品编号pro开头
	pro_name nvarchar(20) not null,		--商品名称
	protype_id char(10) not null,			--商品类别编号
	pro_price money not null,			--商品单价
	pro_amount int not null,			--商品库存
	pro_icon varchar(50) null,			--商品图片
	pro_info ntext null,				--商品简介
	pro_disprice money null,			--商品折扣价格
	collect_num int null  DEFAULT(0),					--收藏数量
	constraint pk_produce PRIMARY KEY(pro_id),
	constraint fk_produce_produceType foreign key(protype_id) references protype(protype_id),
)
GO
--   收货地址表
create table useraddress			
(
	address_id char(10) not null,		--收货地址编号
	webuser_id char(10)  not null,		--用户编号
	useraddress  nvarchar(100) not null,	--详细地址
	constraint pk_address_id  primary key(address_id),
	constraint fk_useraddress_webuser foreign key(webuser_id) references webuser(webuser_id),
	--constraint UX_user_add UNIQUE(webuser_id,useraddress)
)
go
-- 配送员
CREATE TABLE deliveryMan
(
	del_id char(10) not null, 	--配送员编号del开头
	del_name varchar(10) ,		--配送员姓名
	del_telephone char(11) not null,--配送员电话
	del_wage money  DEFAULT(0),			--配送员预计得到的工资
	CONSTRAINT PK_DEL PRIMARY KEY (del_id),
)
GO
-- 商家表
CREATE TABLE saler			
(
	saler_id char(10) not null,		--商家用户编号sal开头
	saler_account varchar(50) not null,	--商家登录账号
	saler_pwd varchar(20) not null,		--商家登录密码
	CONSTRAINT PK_saler PRIMARY KEY (saler_id),
)
GO
--   订单表
CREATE table orders		 
(
	order_id  char(10) not null,				--订单编号ord开头
	webuser_id  char(10)  not null,				--用户编号
	order_time datetime not null default (getdate()),				--订单时间
	order_sum  money   not null,				--订单总价
	address_id char(10) not null,				--订单状态
	order_state char(6) not null,				--配送费
	del_money money null default(0),			--配送员编号
	del_id char(10) null,					--配送时间
	del_time datetime null,					--送达时间
	rec_time datetime null, 
	constraint pk_order_id primary key(order_id),
	constraint fk_orders_user  foreign key(webuser_id) references webuser(webuser_id),
	constraint fk_orders_address foreign key(address_id) references useraddress(address_id),
	constraint ck_order_state check(order_state in ('待付款','待配送','待收货','待评价','已评价')),
)
go


--订单明细表
create table orderinfo		
(	
	order_id char(10) not null,		--订单编号ord开头
	pro_id char(10) not null,		--商品编号pro开头
	order_amount int not null,		--该商品订购的数量
	return_goods bit null  default(0) ,		--是否申请退货
	refund bit null  default(0) ,			--是否申请退款
	constraint pk_orderinfo primary key(pro_id,order_id),
	constraint fk_orderinfo_order foreign key(pro_id) references produce(pro_id),
	constraint fk_orderinfo_produce foreign key(pro_id) references produce(pro_id),
)
go
--收藏表
CREATE TABLE collect
(
	collect_id char(10) not null,	--收藏编号col开头
	webuser_id char(10),		--用户编号u开头
	pro_id char(10),		--商品编号
	collect_time datetime default (getdate()),		--收藏时间
	constraint pk_collect_id primary key(collect_id),
	constraint fk_collect_webuser foreign key (webuser_id) references webuser(webuser_id),
	constraint fk_collect_produce foreign key (pro_id) references produce(pro_id),	
	constraint UX_collect_user_pro UNIQUE(webuser_id,pro_id),
)
GO
drop table comment
go
--评价表
create table comment
(
	com_id char(10) not null,	--评价编号com开头
	order_id char(10) not null,		--订单编号
	pro_id char(10) not null,		--商品编号
	webuser_id char(10) not null,	--用户编号
	com_time datetime not null default (getdate()) ,	--评价时间
	com_message ntext not null default('default review'),	--评价信息
	com_pic varchar(50) null,	--评价图片
	com_score int null default(5),		--商品打分，默认5星，满分5星。
	com_seq int not null,		--评价次序,需要一个触发器来判断是首次评价还是追加评价。
	constraint pk_comment primary key(com_id),
	constraint fk_comment_webuser foreign key(webuser_id) references webuser(webuser_id),
	constraint fk_comment_produce foreign key(pro_id) references produce(pro_id),
)
go 

-- 商家回复表
CREATE TABLE saler_reply		
(
	com_id char(10)	not null,	--评论编号com开头
	saler_id char(10) not null,	--商家用户编号sal开头
	reply_time datetime  null DEFAULT(GETDATE()),	--回复时间
	reply_context varchar(200) null  DEFAULT('DEFAULT REPLY '),--回复内容
	CONSTRAINT PK_SALER_REPLY PRIMARY KEY(com_id,saler_id),
	CONSTRAINT FK_REPLY_COM FOREIGN KEY (com_id) REFERENCES COMMENT(com_id),
	CONSTRAINT FK_REPLY_SALER FOREIGN KEY (saler_id ) REFERENCES saler(saler_id ),
)
GO
-- 售后表
CREATE TABLE sale_back			
(
	saler_id char(10) not null,	--处理售后商家的编号
	pro_id char(10) not null,	--商品编号
	order_id char(10) not null,	--订单编号
	deal_time datetime not null DEFAULT(GETDATE()),	--处理完成时间
	refund_money money not null,	--退款金额
	CONSTRAINT PK_sale_back PRIMARY KEY(saler_id,pro_id,order_id),
	CONSTRAINT FK_BACK_SALER FOREIGN KEY (saler_id ) REFERENCES saler(saler_id),
	CONSTRAINT FK_BACK_PRODUCE FOREIGN KEY (pro_id ) REFERENCES produce(pro_id ),
	CONSTRAINT FK_BACK_ORDER FOREIGN KEY (order_id ) REFERENCES orders(order_id ),
)
GO
