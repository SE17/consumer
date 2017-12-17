use OnlineOrderVegetable
go 
--顾客操作
--存储过程:proc_WebUserInsert
--功能：实现用户注册，将用户密码经过MD5加密后存入数据库。
--输入参数：用户账号、密码、用户名、性别、联系电话
--输出参数：无
--返回值：1：注册成功 2：账号已存在  
ALTER PROC proc_WebUserInsert
@user_account varchar(50),
@user_pwd varchar(20),
@user_name nvarchar(20),
@user_sex char(2),
@user_tel char(11)
AS
BEGIN
	--检查是否存在该注册号
	IF(EXISTS (SELECT *
				FROM webuser
				WHERE user_account = @user_account))
	BEGIN
		PRINT '账号已存在!'
		RETURN 2
	END
	ELSE 
	BEGIN
		--DECLARE @counts INT;
		DECLARE @webuser_id CHAR(10)
		DECLARE @maxID char(10)
		SELECT @maxID=max(webuser_id)
		FROM webuser;
		PRINT 'maxID:'+@maxID
		SET @webuser_id ='u'+CAST((SUBSTRING(@maxID,2,9)+1) AS CHAR(9))
		INSERT INTO webuser(webuser_id,usertype_id,user_account,user_pwd,user_name,user_sex,usr_tel) 
			VALUES (@webuser_id,'uty1000001',@user_account,@user_pwd,@user_name,@user_sex,@user_tel)
		PRINT '注册成功!'
		RETURN 1		
	END
END
GO
--测试数据
--用户注册开始
EXEC proc_WebUserInsert '12389099765','123456','张三三','男','13909877890'
GO
EXEC proc_WebUserInsert '12389099770','12345678','李思','男','16389099765'
GO
--存储过程: proc_WebUserSelectLogin
--功能：用户登录，使用PWDCOMPARE函数比对输入的密码与数据库中经过加密的是否一致。
--输入参数：用户账号、密码
--输出参数：用户编号
--返回值：1:登录成功 2：用户不存在 3：密码错误
ALTER PROC proc_WebUserSelectLogin
@account varchar(50),
@pwd varchar(20),
@webuser_id char(10) output
AS
BEGIN
	IF(NOT EXISTS(SELECT *
					FROM webuser
					WHERE @account = user_account))
	BEGIN 
		PRINT '用户不存在'
		RETURN 2
	END
	ELSE 
	BEGIN
		IF(EXISTS( SELECT *
					FROM webuser
					WHERE @account = user_account
					AND @pwd = user_pwd
					))
		BEGIN
			SELECT @webuser_id = webuser_id
			FROM webuser 
			WHERE @account = user_account
			PRINT '登录成功'
			RETURN 1
		END
		ELSE
		BEGIN	 
			PRINT '密码错误'
			RETURN 3
		END
	END
END
GO
--测试数据
declare @result varchar(20)
EXEC proc_WebUserSelectLogin '15606091036','123456',@result output
go
declare @result varchar(20)
EXEC proc_WebUserSelectLogin '16389099765','123456',@result output
go
declare @result varchar(20)
EXEC proc_WebUserSelectLogin '16389099765','1111111',@result output
go
--存储过程：proc_ProduceSelect
--功能：分类浏览商品 
--输入参数：商品类别编号、排序字段、排序类别
ALTER PROC proc_ProduceSelect
@protype_id char(10)=NULL,
@order_name varchar(10)=NULL,
@order_type varchar(10)='ASC'
AS
BEGIN
	DECLARE @sql varchar(255)
	IF(@order_name IS NULL)
	BEGIN
		SELECT pro_id ,pro_name 商品名称,protype_name 商品类别,pro_icon 商品图片,pro_price 商品价格,pro_disprice 促销价,pro_amount 商品数量,collect_num 收藏次数
		FROM produce INNER JOIN protype 
		ON produce.protype_id = protype.protype_id
		WHERE (@protype_id = produce.protype_id OR @protype_id IS NULL)
	END
	ELSE
	BEGIN
		SET @sql = 'SELECT pro_id 商品编号,pro_name 商品名称,protype_name 商品类别,pro_icon 商品图片,pro_price 商品价格,pro_amount 商品数量
		FROM produce INNER JOIN protype '+
		'ON produce.protype_id = protype.protype_id '+
		'WHERE ( produce.protype_id '+'LIKE '+@protype_id +' )'
		+' ORDER BY '+@order_name+' '+@order_type
		EXEC(@sql)
	END
END
GO
--测试数据，排序类别缺省
EXEC proc_ProduceSelect 'pty1000001'
GO
--排序类别缺省为升序
EXEC proc_ProduceSelect 'pty1000002','pro_price'
GO
--
EXEC proc_ProduceSelect 'pty1000002','pro_price','DESC'
GO

--存储过程：proc_ProduceNameSelect
--功能：搜索商品名字，模糊匹配
--输入参数：关键字
--输出参数：
--返回值：相关商品记录
CREATE PROC proc_ProduceNameSelect
@key varchar(20)
AS
BEGIN
	DECLARE @indexWord varchar(20)
	SET @indexWord= '%'+@key+'%'
	IF((not exists (SELECT *
					FROM  produce
					WHERE pro_name LIKE @indexWord)))
	BEGIN
		PRINT '无相关记录！'
		RETURN 0
	END
	ELSE
	BEGIN
		SELECT pro_id,pro_name 商品名称,pro_price 商品价格,pro_icon 商品图片,pro_amount 商品数量 
		FROM produce
		WHERE pro_name LIKE @indexWord
		RETURN 1
	END
END
GO
--测试数据
EXEC proc_ProduceNameSelect '虾'
GO
EXEC proc_ProduceNameSelect '1'
GO
EXEC proc_ProduceNameSelect '33'
GO
--存储过程：proc_ProduceIdSelect
--功能：查看商品详情
--输入参数：商品编号
--输出参数：相关商品记录
--返回值：0：没找到，1：找到
CREATE PROC proc_ProduceIdSelect
@pro_id char(10)
AS
BEGIN
	IF(NOT EXISTS (SELECT *
					FROM produce
					WHERE pro_id = @pro_id))
	BEGIN
		PRINT '没找到'
		RETURN 0
	END
	ELSE
	BEGIN
		SELECT pro_id 商品编号,pro_name 商品名称,pro_price 商品价格,pro_amount 商品数量,pro_info 商品简介,collect_num 收藏次数
		FROM produce
		WHERE @pro_id = pro_id
		RETURN 1
	END
END
GO
EXEC proc_ProduceIdSelect pro1000001
GO
EXEC proc_ProduceIdSelect pro1002222
GO
--存储过程：proc_OrdersInsert
--功能：生成订单，默认配送为2元
--输入参数：用户编号，收货地址编号
--输出参数：订单编号
--返回值：0：没有收货地址，1：生成订单
ALTER PROC proc_OrdersInsert
@webuser_id char(10)=NULL,
@address_id char(10)=NULL,
@order_id char(10)=NULL OUTPUT
AS
BEGIN	
	IF(@address_id IS NULL)
	BEGIN
		PRINT '没有收货地址！'
		RETURN 0
	END
	ELSE
	BEGIN
		DECLARE @ord_id CHAR(10)
		DECLARE @maxID char(10)
		SELECT @maxID=ISNULL(max(order_id),1000000)
		FROM orders
		--PRINT 'maxID:'+@maxID
		SET @ord_id ='ord'+CAST((SUBSTRING(@maxID,4,7)+1) AS CHAR(7))
		INSERT INTO orders(order_id,webuser_id,order_sum,address_id,order_state,del_money) values(@ord_id,@webuser_id,2,@address_id,'待付款',2)	
		SET @order_id = @ord_id
		RETURN 1		
	END	
END
GO
--
DECLARE @order_id char(10) 
EXEC proc_OrdersInsert u100000001,add1000002,@order_id OUTPUT
PRINT '订单编号：'+@order_id
GO
--①生成用户2的一条订单，返回订单编号给用户
DECLARE @order_id int 
EXEC proc_OrdersInsert 2,8,@order_id OUTPUT
PRINT '订单编号：'+CAST(@order_id AS VArchar(4))
GO
DECLARE @order_id int 
EXEC proc_OrdersInsert 3,6,@order_id OUTPUT
PRINT '订单编号：'+CAST(@order_id AS VArchar(4))
GO

--存储过程：proc_OrdersInfoInsert
--功能：生成订单明细
--输入参数：订单编号，商品编号,商品数量
--输出参数：
--返回值：0：库存不足，生成订单失败，1：生成订单成功
CREATE PROC proc_OrdersInfoInsert
@order_id char(10),
@pro_id char(10),
@order_amount int
AS
BEGIN
	DECLARE @amount int
	SELECT @amount = pro_amount
	FROM produce 
	WHERE pro_id = @pro_id 
	IF(@order_amount > @amount )
	BEGIN
		PRINT '库存不足！生成订单失败！'
		DELETE FROM 
		orderinfo
		WHERE order_id = @order_id 
		DELETE FROM
		orders
		WHERE order_id = @order_id 
		RETURN 0
	END
	ELSE
	BEGIN
		INSERT INTO orderinfo(order_id,pro_id,order_amount) VALUES(@order_id,@pro_id,@order_amount)
		RETURN 1
	END
END
GO
--查询商品
EXEC proc_ProduceSelect
GO
--②根据订单编号和订单中的商品系统自动生成订单明细
--a.若其中某种商品库存不足，则删除该订单。
EXEC proc_OrdersInfoInsert ord1000011,pro1000001,3
GO
--b.给24号订单添加1件1号商品，4件2号商品
--若商品的售出后库存小于20，请管理员发出提醒！
EXEC proc_OrdersInfoInsert ord1000028,8,11
GO
EXEC proc_OrdersInfoInsert 29,6,25
GO
EXEC proc_OrdersInfoInsert 30,10,5
GO
--存储过程：proc_OrderIdSelect
--功能：用户查看某个订单
--输入参数：订单编号
--输出参数：该订单明细，
--返回值：0：查找订单失败，1：查找订单成功
CREATE PROC proc_OrderIdSelect
@order_id char(10)
AS
BEGIN
	IF(NOT EXISTS (SELECT *
					FROM orders
					WHERE order_id= @order_id ))
	BEGIN
		PRINT '没有该订单！'
	END
	ELSE
	BEGIN
		SELECT a.order_id ,b.pro_id ,pro_name 商品名称,pro_price 商品单价,order_amount 商品数量,order_sum 订单总价,order_time 订单时间,order_state 订单状态
		FROM orders a INNER JOIN orderinfo b
		ON a.order_id = b.order_id 
		INNER JOIN produce p
		ON b.pro_id = p.pro_id
		WHERE a.order_id = @order_id 
	END
END
GO
--查看该订单
EXEC proc_OrderIdSelect ord1000011
GO
--③生成给用户的订单，订单状态默认为‘待付款’
EXEC proc_OrderIdSelect ord1000011
GO
--存储过程：proc_OrdersStateSelect
--功能：查看用户的各种状态的订单列表
--输入参数：用户编号、订单状态
--输出参数：订单列表
--返回值：0：没有相关订单，1：存在订单
CREATE PROC proc_OrdersStateSelect
@webuser_id char(10),
@order_state char(6)=NULL
AS
BEGIN
	IF(NOT EXISTS(SELECT *
					FROM orders
					WHERE webuser_id = @webuser_id))
	BEGIN
		PRINT '没有相关订单'
		RETURN 0
	END
	ELSE
	BEGIN		
		SELECT DISTINCT a.order_id 订单编号,pro_name 商品名称,order_amount 商品数量 ,order_sum 订单总价, order_state 订单状态
		FROM orders a,orderinfo b,produce p
		WHERE a.order_id = b.order_id
		AND b.pro_id = p.pro_id
		AND	a.webuser_id = @webuser_id
		--默认@order_state为空值，显示全部订单。
		AND (order_state = @order_state OR @order_state IS NULL)
		ORDER BY a.order_id
		RETURN 1
	END		
END
GO
--
EXEC proc_OrdersStateSelect u100000001,'待付款'
GO
EXEC proc_OrdersStateSelect u100000002
GO
EXEC proc_OrdersStateSelect 3,'待配送'
GO
EXEC proc_OrdersStateSelect u100000003
GO
--存储过程：proc_OrderStateUpdatePay
--功能：用户为某个订单付款操作
--输入参数：订单编号，用户编号
--输出参数：无
--返回值：0：付款失败，订单状态‘待付款’1：付款成功，订单状态‘待配送’
ALTER PROC proc_OrderStateUpdatePay
@order_id char(10),
@webuser_id char(10),
@result varchar(20) OUTPUT
AS
BEGIN
	DECLARE @requireMoney money
	SELECT @requireMoney = order_sum
	FROM orders
	WHERE order_id = @order_id
	IF(@requireMoney > (SELECT balance 
						FROM webuser 
						WHERE webuser_id = @webuser_id))
	BEGIN 
		SET @result = '余额不足'
		PRINT @result
		RETURN 0
	END
	ELSE
	BEGIN
		IF((SELECT order_state
		FROM orders
		WHERE @order_id = order_id
		AND webuser_id = @webuser_id)!='待付款')
		BEGIN
			PRINT '该订单已付款!' 
			RETURN 0
		END
		ELSE
		BEGIN
			UPDATE orders
			SET order_state = '待收货'
			WHERE order_id = @order_id
			SET @result = '付款成功'
			PRINT @result
			RETURN 1
		END		
	END
END
GO
--④用户给24号订单付款，扣除用户余额
--付款前，用户账号余额情况
EXEC proc_WebuserSelect '15985700852'
GO
--付款结果
DECLARE @result varchar(20)
EXEC proc_OrderStateUpdatePay ord1000011,u100000001,@result OUTPUT
PRINT @result
GO
--付款后，用户账号余额情况
EXEC proc_WebuserSelect '15985700852'
GO
DECLARE @result varchar(20)
EXEC proc_OrderStateUpdatePay 17,2,@result OUTPUT
PRINT @result
GO
--存储过程：proc_OrderStateUpdateReceive
--功能：收货操作，用户对某个订单进行收货
--输入参数：订单编号
--输出参数：无
--返回值：
CREATE PROC proc_OrderStateUpdateReceive
@order_id char(10)
AS
BEGIN
	IF((SELECT order_state
		FROM orders 
		WHERE @order_id = order_id )='待收货')
	BEGIN
		PRINT '成功收到'+ @order_id +'号订单，该订单等待您的评价~'
		UPDATE orders
		SET order_state = '待评价'
		WHERE order_id = @order_id 	
	END
	ELSE
	BEGIN
		PRINT '该订单不处于待收货状态！'
	END
	
END
GO
--查看订单
EXEC proc_OrdersStateSelect u100000001
GO
--⑤用户确认收货订单24号
EXEC proc_OrderStateUpdateReceive ord1000011
GO
-----------------------------------------------1-完成-------------------------------------------------------
--存储过程：proc_OrderStateUpdateComment
--功能：用户评价商品操作
--输入参数：商品编号、订单编号、评价内容
--输出参数：
--返回值：
ALTER proc proc_OrderStateUpdateComment
@procduce_id char(10),
@order_id char(10),
@webuser_id char(10),
@com_text ntext
as
begin
     declare @counts int;
	 declare @maxID varchar(20)
	 declare @com_id char(10);
	 declare @com_seq int
	 select @maxID=max(com_id)
	 from comment;
	 set @com_id='com'+cast (substring(@maxID,4,7)+1 as char(7)) 
	 IF(EXISTS (SELECT *
				FROM comment
				WHERE order_id =  @order_id
				AND pro_id = @procduce_id
				AND webuser_id = @webuser_id))
	BEGIN
		SET @com_seq = 2;
	END
	ELSE
	BEGIN
		SET @com_seq = 1;
	END
     insert into comment(com_id,order_id,pro_id,webuser_id,com_message,com_seq)
	 values(@com_id,@order_id,@procduce_id,@webuser_id,@com_text,@com_seq)
	  PRINT '感谢您的本次评价~欢迎回购。'
end 

--⑥2号用户对刚才收到的24号订单的商品做出评价
--对2号商品的评价
exec proc_OrderStateUpdateComment pro1000001,ord1000011,u100000001,"食材新鲜美味！还会回购的。"
GO
--对商品的评价
exec proc_OrderStateUpdateComment pro1000005,ord1000008,"味道一般吧。"
GO
select *
from comment
select *
from orders

go
-------------------------------------------------2--完成-------------------------------------------------------
--存储过程：proc_CollectInsert
--功能：收藏商品
--输入参数：商品编号、用户编号
--输出参数：
--返回值：
ALTER proc proc_CollectInsert
@pro_id char(10),
@webuser_id char(10)
as
begin
	 declare @maxID varchar(20);
	 declare @col_id char(10);
	 select @maxID=ISNULL(MAX(collect_id),'col1000000')
	 from collect;
	 set @col_id='col'+cast(SUBSTRING(@maxID,4,7)+1 as char(7))
     insert into collect(collect_id,pro_id,webuser_id)
	 values(@col_id,@pro_id,@webuser_id)
	 PRINT '成功收藏'+@pro_id+'号商品!'
end
go
--⑦若用户喜欢哪一件商品，可以对商品进行收藏
--2号用户对2号商品进行了收藏
exec proc_CollectInsert pro1000006,u100000002
select *
from collect
go
--存储过程：proc_CollectSelect
--功能：查看用户收藏的商品
--输入参数：用户账号
--输出参数：用户收藏信息相关记录
--返回值：
ALTER PROC proc_CollectSelect
@webuser_id char(10)
AS
BEGIN
	SELECT collect.pro_id,pro_name 商品名称,pro_icon 商品图片,pro_price 商品价格
	FROM collect INNER JOIN produce
	ON COLLECT.pro_id = produce.pro_id
	WHERE webuser_id = @webuser_id
END
GO
--测试数据
EXEC proc_CollectSelect 'u100000001'
GO
------------------------------------------------3--完成------------------------------------------------
--存储过程：proc_WebuserSelect
--功能：查看用户信息
--输入参数：用户账号
--输出参数：用户信息相关记录
--返回值：
CREATE proc proc_WebuserSelect
@account varchar(50)
as
begin
     select webuser_id 用户编号,user_account 登录账号,user_name 用户名称 ,usertype_name 用户类别,user_sex 性别,usr_tel 电话,Balance 账户余额
	 from webuser INNER JOIN usertype
	 ON webuser.usertype_id = usertype.usertype_id
	 where user_account=@account
end
go
--用户查看个人信息
exec proc_WebuserSelect "13255900215"


------------------------------------------------4--完成--------------------------------------
--存储过程：proc_WebuserUpdate
--功能：修改用户信息
--输入参数：用户名、性别、联系电话、用户编号
--输出参数：
--返回值：
ALTER proc proc_WebuserUpdate
@account varchar(50),
@user_name nvarchar(20),
@user_sex char(2),
@user_tel char(11)
as
begin
     update webuser
     set user_name=@user_name,user_sex=@user_sex,Usr_tel=@user_tel
     where user_account=@account
end
go
exec proc_WebuserUpdate '13255900215','张书','男','18790987652'
go
exec proc_WebuserSelect '13255900215'
select *
from webuser

---------------------------------------------------5--完成--------------------------------
--存储过程：proc_AddressForWebuserIdSelect
--功能：用户查看本人的收货地址
--输入参数：用户编号
--输出参数：地址列表
--返回值：0：没有收货地址，给出提示，1：有收货地址
drop proc proc_AddressForWebuserIdSelect
create proc proc_AddressForWebuserIdSelect
@webuser_id char(10)
as
begin
   if exists (select addresss  from useraddress where webuser_id=@webuser_id )
      begin
        select address_id as 收货地址编号,addresss as 收货地址
        from useraddress
        where webuser_id=@webuser_id
        return 1 
      end
   else
      begin 
		print'没有收货地址'
        return 0
      end
end
GO
--①用户查看本人的收货地址
exec proc_AddressForWebuserIdSelect  'u000000001'
GO
exec proc_AddressForWebuserIdSelect  'u000000002'
GO

------------------------------------------------------6--完成-----------------------------------
--存储过程：proc_AddressIdSelect
--功能：查看某一订单的收货地址信息
--输入参数：订单编号
--输出参数：地址信息
--返回值：
alter proc proc_AddressIdSelect
@order_id char(10)
as
begin
     select addresss 收货地址
	 from orders , useraddress
	 where useraddress.address_id=orders.address_id and order_id=@order_id 
end
GO
exec proc_AddressIdSelect "ord0000001"
GO

-------------------------------------------------------7--完成-----------------------------------------------------

--存储过程：proc_AddressInsert
--功能：添加收货地址
--输入参数：用户编号、地址信息
--输出参数：无
--返回值：0：地址重复，无法插入，1：添加成功
alter proc proc_AddressInsert
@webuser_id char(10),@addresss nvarchar(100)
as
begin
     declare @counts int;
	 declare @add_id char(10);
	 select @counts=(count(address_id)+1)
	 from useraddress;
	 set @add_id='add'+cast (@counts as char(7))

    if exists( select * from useraddress where webuser_id=@webuser_id and addresss=@addresss)
	begin
	   print '该地址重复，无法插入'
	   return 0
	end 
	else
	begin
	    insert into useraddress(address_id,webuser_id,addresss)
		values(@add_id,@webuser_id,@addresss)
		print'添加收货地址成功'
		return 1
	end
end
GO
--测试数据
--②用户还可以为自己添加收货地址，但是不能为自己添加重复的地址。
EXEC proc_AddressInsert 'u000000001','福建省厦门市集美大学轮机工程学院'
GO
select *
from useraddress

-------------------------------------------8--完成-----------------------------------------------------------

--存储过程：proc_AddressUpdate
--功能：某一用户修改其某一地址内容
--输入参数：地址编号,地址信息
--输出参数：无
--返回值：0：没有修改，1：修改成功
alter proc proc_AddressUpdate
@address_id char(10),@addresss nvarchar(100)
as
  begin
  if exists (select * from useraddress where address_id=@address_id and addresss=@addresss)
     begin
	 print '没有修改!'
	 return 0
	 end
  else 
     begin 
	 update useraddress
	 set addresss=@addresss
	 where address_id=@address_id
	end 
  end
  go
exec proc_AddressUpdate "add0000001","北京市朝阳区"
select *
from useraddress
----------------------------------------------------9--完成----------------------------------------------------
--存储过程：proc_AddressDelete
--功能：删除收货地址
--输入参数：地址编号
--输出参数：
--返回值：0：无法删除 1：删除成功
create proc proc_AddressDelete
@address_id char(10)
as
begin
     if exists (select * from useraddress as a,orders as o where a.address_id=@address_id and a.address_id=o.address_id)
	BEGIN
		 print '该地址正在使用，无法删除!'
		 RETURN 0
	 END
	 else
	 begin 
		delete from useraddress where address_id=@address_id
		Print '删除成功！'
		RETURN 1
	 end
end  
--③删除掉不需要的地址。如果该地址正在使用，则无法删除。
exec proc_AddressDelete add0000001
GO
exec proc_AddressDelete add0000011
GO
SELECT *
FROM useraddress
GO 
-------------------------------------------------------10--完成-------------------------------------------
--存储过程：proc_WebuserAccountMoneyUpdate
--功能：用户充值
--输入参数：用户编号、冲值金额
--输出参数：无
--返回值：0：充值失败，1：充值成功
alter proc proc_WebuserAccountMoneyUpdate
@webuser_id char(10),@money money
as
begin
	DECLARE @account_money money
	if exists (select * from webuser where webuser_id=@webuser_id)
	begin
		update webuser
		set Balance=Balance+@money,@account_money = Balance
		where webuser_id=@webuser_id
		print '充值成功!'
		print '充值前账户余额为：'+CAST(@account_money AS VARCHAR(8))
		return 1
		end
	else
	BEGIN
		print '该用户不存在，充值失败!'
		RETURN 0
	END  
end
go

--给2号用户账号充值1000元
exec proc_WebuserAccountMoneyUpdate "u000000007","1000"
--
exec proc_WebuserAccountMoneyUpdate "u000000005","2000"
--查看结果
select *
from webuser


---------------------------------------------------触发器-----------------------------------------------------------
--触发器tri_orderinfoInsert_UpdateOrders
--对象：orderinfo
--触发事件：插入
--功能:插入订单明细时，更新订单总金额 
CREATE TRIGGER tri_orderinfoInsert_UpdateOrders
ON orderinfo FOR INSERT
AS
BEGIN
	DECLARE @usertype_id char(10)  
	--查找用户类别
	SELECT @usertype_id = usertype_id
	FROM webuser w INNER JOIN orders o
	ON w.webuser_id = o.webuser_id
	INNER JOIN inserted i
	ON  i.order_id = o.order_id	
	--更新订单金额,根据用户类别计算订单金额
	UPDATE orders
	SET order_sum = CASE @usertype_id
					WHEN 'uty1000001' THEN ISNULL(order_sum,0) + pro_price*order_amount 
					WHEN 'uty1000002' THEN ISNULL(order_sum,0) + pro_price*order_amount*0.85
					END 
	FROM inserted i INNER JOIN produce p
	ON i.pro_id = p.pro_id	
	INNER JOIN orders o
	ON o.order_id = i.order_id
END
GO
--触发器tri_orderinfoInsert_UpdateProduce
--对象：orderinfo
--触发事件：插入、
--功能:插入订单明细时，更新商品库存。
CREATE TRIGGER tri_orderinfoInsert_UpdateProduce
ON orderinfo FOR INSERT
AS
BEGIN
	--更新商品的库存
	UPDATE produce
	SET pro_amount = pro_amount - order_amount
	FROM inserted INNER JOIN produce
	ON inserted.pro_id = produce.pro_id
END
GO
--触发器tri_produceUpdate
--对象：produce
--触发事件：更新库存
--功能:更新商品库存，检查商品库存是否小于下限20,小于20件提醒商家进货。
ALTER TRIGGER tri_produceUpdate
ON  produce FOR UPDATE
AS
BEGIN
	DECLARE @pro_amount INT
	IF(UPDATE(pro_amount))
	BEGIN
		SELECT @pro_amount = pro_amount
		FROM inserted 
		IF(@pro_amount<20)
		BEGIN
			PRINT '库存不足于20件，请尽快进货'
		END	
		IF(@pro_amount>500)	
		BEGIN
			PRINT '库存多余500件，请注意商品保质期！'
		END
	END		
END
GO
--触发器tri_ordersUpdate1
--对象：orders
--触发事件：修改
--功能:修改订单状态时，统计用户不是待付款状态订单数量，修改用户级别。
ALTER TRIGGER tri_ordersUpdate1
ON orders FOR UPDATE
AS
BEGIN
	DECLARE @orderCnt int
	IF(UPDATE(order_state))
	BEGIN
		--如果从待付款状态变成付款状态，则统计该用户的订单总量
		IF((SELECT order_state
			FROM inserted)='待配送' AND (SELECT order_state
										FROM deleted)='待付款')
		BEGIN
			SELECT @orderCnt = (SELECT COUNT(*)
								FROM orders o INNER JOIN inserted i
								ON o.webuser_id = i.webuser_id
								WHERE o.order_state !='待付款')
			--如果用户订单量超过10单，则提升用户等级
			IF(@orderCnt >=10)
			BEGIN
				UPDATE webuser
				SET usertype_id = 'uty0000002'
				FROM inserted i INNER JOIN webuser w
				ON i.webuser_id  = W.webuser_id
			END				
		END
	END	
END
GO
--触发器tri_orderStateUpdate2
--对象：orders
--触发事件：修改、
--功能:付款之后，修改订单状态为待配送时，修改用户余额。
ALTER TRIGGER tri_orderStateUpdate2
ON orders FOR UPDATE
AS
BEGIN
	IF(UPDATE(order_state))
	BEGIN
		--如果从待付款状态变成待配送状态，修改用户余额。
		IF((SELECT order_state
			FROM inserted)='待配送' AND (SELECT order_state
										FROM deleted)='待付款')
		BEGIN
			UPDATE webuser
			SET account_money = account_money - order_sum
			FROM webuser w INNER JOIN inserted i
			ON 	w.webuser_id = i.webuser_id 
		END
	END	
END
GO
-----------------------------------------------------1----完成----------------------------------------------------------
--触发器tri_commentInsert
--对象：comment
--触发事件：插入
--功能:插入评价记录时，修改该订单状态。
alter trigger tri_commentInsert
on comment after insert
as
begin
     declare @order_id char(10)
     select @order_id=order_id
	 from inserted

     update orders
	 set order_state='已评价'
	 where order_id=@order_id
end
go
----------------------------------------------------2----------------------------------------------------
--触发器tri_collectInsert
--对象：collect
--触发事件：插入、
--功能:插入收藏记录时，统计商品收藏次数，修改collect_num的值。
alter trigger tri_collectInsert
on collect after insert
as
begin
     declare @pro_id char(10),@count int
	 select @pro_id=pro_id
	 from inserted
	 select @count=count(*)
	 from collect
	 group by pro_id
	 having pro_id=@pro_id
	 update produce
	 set collect_num=@count
	 where pro_id=@pro_id
end
go
-----------------------------------------------------3-------------------------------------------------------
--触发器tri_orderStateUpdate3
--对象：orders
--触发事件：更新
--功能:修改订单状态为待评价时，更新配送员的工资。
alter trigger tri_orderStateUpdate3
on orders after update
as
begin
     declare @orders_id char(10),@del_money money,@del_id char(10)
	 select @orders_id=order_id,@del_money=del_money,@del_id=del_id
	 from inserted
	 IF((SELECT order_state
			FROM inserted)='待评价' AND (SELECT order_state
										FROM deleted)='待收货')
	 BEGIN
		 update deliveryman
		 set del_wage=del_wage+@del_money
		 where del_id=@del_id
	 END
end 
GO
------------------------------------------------------------4---------------------------------------------
--触发器tri_recommand_produce
--对象: orders
--触发事件：插入
--功能:查看所有订单记录，找出所有订单明细表,找出订单明细中购买量排前2的商品的种类，给用户做出推荐
alter trigger tri_recommand_produce
on orders after UPDATE
as
begin
	declare @webuser_id char(10)
	select @webuser_id=webuser_id
	from inserted
	IF(UPDATE(order_state))
	BEGIN
	--如果从待付款状态变成待配送状态，给用户推荐商品
		IF((SELECT order_state
			FROM inserted)='待配送' AND (SELECT order_state
										FROM deleted)='待付款')
		begin
			select '推荐给你这些商品：',produce.*
			from produce
			where protype_id in (select top 2 protype_id
								from  orders as a,orderinfo as b,produce as c
								where a.order_id=b.order_id 
								and webuser_id=@webuser_id  
								and b.pro_id =c.pro_id
								group by b.pro_id,protype_id
								order by sum(order_amount) desc)
		end
	end
end 
go

