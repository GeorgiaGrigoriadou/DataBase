CREATE TABLE CardsTransactions
(
	pid int, 
	pname varchar(50), 
	age int, 
	gender char(1),
	cardno char(16), 
	card_brand varchar(30), 
	card_type varchar(20), 
	tdate datetime, 
	amount decimal(6,2), 
	ttc int, 
	trans_type varchar(30),
	mcc int, 
	merchant_city varchar(50)
);

BULK INSERT CardsTransactions
FROM 'C:\data\CardsTransactions.txt' 
WITH (FIRSTROW =2, FIELDTERMINATOR='|', ROWTERMINATOR = '\n');

CREATE TABLE customers(
pid numeric primary key,
pname varchar(50),
age int,
gender char(1)
);

CREATE TABLE cards(
cardno numeric primary key,
card_brand varchar(30),
card_type varchar(20)
);

CREATE TABLE timeinfo(
tdate datetime primary key,
t_year int,
t_month int,
t_dayofmonth int,
t_hour int,
t_quarter int,
t_week int,
t_dayofyear int,
t_dayofweek int
);

CREATE TABLE city(
mcc numeric primary key,
merchant_city varchar(50)
);

CREATE TABLE transactions(
ttc int,
pid numeric,
cardno numeric,
tdate datetime,
mcc numeric,
amount decimal(6,2),
trans_type varchar(30),

primary key(ttc, pid, cardno, tdate, mcc),
foreign key (pid) references customers(pid),
foreign key (cardno) references cards(cardno),
foreign key (tdate) references timeinfo(tdate),
foreign key (mcc) references city(mcc)
);



INSERT INTO customers
	SELECT DISTINCT pid, pname, age, gender
		FROM CardsTransactions;

INSERT INTO cards
	SELECT DISTINCT cardno, card_brand, card_type
		FROM CardsTransactions;

SET DATEFIRST 1;
INSERT INTO timeinfo
	SELECT DISTINCT tdate, datepart(year, tdate), datepart(month, tdate),
	datepart(day,tdate),datepart(hour, tdate),
	datepart(quarter,tdate), datepart(week,tdate),
	datepart(dayofyear,tdate),datepart(dw,tdate)
		FROM CardsTransactions;

INSERT INTO city
	SELECT DISTINCT mcc, merchant_city
		FROM CardsTransactions;

INSERT INTO transactions
	SELECT ttc, pid, cardno, tdate, mcc, SUM(amount), trans_type 
		FROM CardsTransactions
			GROUP BY ttc, pid, cardno, tdate, mcc, trans_type;
			
			
			
			
select merchant_city, sum(amount) as total_amount
from city, transactions
where city.mcc = transactions.mcc
group by merchant_city 
order by merchant_city 



select t_year, gender, sum(amount) as total_amount
from timeinfo, transactions, customers
where customers.pid=transactions.pid and transactions.tdate=timeinfo.tdate 
group by t_year, gender
order by t_year desc


select card_brand,card_type , count(ttc) as numberOfTransactions, sum(amount) as total_amount
from transactions , cards
where transactions.cardno=cards.cardno
group by card_brand, card_type


select trans_type,  t_quarter, sum(amount) as total_amount_2019
from transactions , cards , timeinfo
where transactions.cardno=cards.cardno and transactions.tdate=timeinfo.tdate
and timeinfo.t_year=2019  
group by rollup (trans_type,t_quarter)




select sum(amount) as total_amount, t_year , gender, age
from customers, cards, timeinfo, transactions
where customers.pid=transactions.pid and
cards.cardno=transactions.cardno and
timeinfo.tdate=transactions.tdate and
trans_type = 'Online Transaction' 
group by rollup(t_year, gender,age)
order by t_year, gender,age

select count(ttc) as numberOftransactions, t_year, card_brand, gender
from customers, transactions, timeinfo, cards
where timeinfo.tdate=transactions.tdate and
customers.pid=transactions.pid and
cards.cardno=transactions.cardno
group by cube (t_year, card_brand, gender)


SET NUMERIC_ROUNDABORT OFF;
SET ANSI_PADDING, ANSI_WARNINGS, CONCAT_NULL_YIELDS_NULL, ARITHABORT,
   QUOTED_IDENTIFIER, ANSI_NULLS ON;

--Create view with SCHEMABINDING.
IF OBJECT_ID ('view1', 'view') IS NOT NULL
   DROP VIEW view1 ;
   
   go
   
create view view1 
with schemabinding as
select count_big(*) as numberOftransactions, [ti].t_year, [ca].card_brand, [c].gender
from dbo.customers[c], dbo.transactions[t], dbo.timeinfo[ti], dbo.cards[ca]
where [ti].tdate=[t].tdate and
[c].pid=[t].pid and
[ca].cardno=[t].cardno
group by  [ti].t_year,[ca].card_brand, [c].gender

go

create unique clustered index idx1 on view1(t_year, card_brand, gender)

go

select sum(numberOftransactions) from view1

select sum(numberOftransactions), t_year from view1
group by t_year

select sum(numberOftransactions), card_brand from view1
group by card_brand

select sum(numberOftransactions), gender from view1
group by gender

select sum(numberOftransactions), t_year, card_brand from view1
group by  t_year, card_brand

select sum(numberOftransactions), t_year, gender from view1
group by  t_year, gender

select sum(numberOftransactions), card_brand, gender from view1
group by   card_brand, gender
