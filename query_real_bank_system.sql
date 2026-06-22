## ЧАСТЬ 1 — Представления (VIEWS)
TASK 1 — Customer financial snapshot VIEW
Создать VIEW:

* total_balance (sum accounts.balance)
* active_accounts_count
* risk_score

CREATE VIEW customer_financial_snapshot AS
SELECT c.id customer_id, c.full_name, c.risk_score,
coalesce(SUM(a.balance), 0) AS total_balance,
count(a.id ) AS active_accounts_count
FROM customers c
LEFT JOIN accounts a ON c.id = a.customer_id AND a.status = 'active'
GROUP BY c.id, c.full_name, c.risk_score;


select * from customer_financial_snapshot;
TASK 2 — Active accounts VIEW
Создать VIEW:

* status = 'active'
* balance > 0


create VIEW active_accounts AS
SELECT id, customer_id, balance, status
FROM accounts
WHERE status = 'active' AND balance > 0;

drop VIEW active_accounts;

SELECT * FROM active_accounts;



TASK 3 — Enriched transactions VIEW
Создать VIEW:

* transactions + from_account + to_account + customer data


create view enriched_tx as 

select t.*, fc.full_name from_customer_name,
fa.balance from_account_balance,
tc.full_name to_customer_name,
ta.balance to_account_balance 

from transactions t
join accounts fa on t.from_account_id=fa.id 
join customers fc on fa.customer_id=fc.id
join accounts ta on t.to_account_id=ta.id 
join customers tc on tc.id = ta.customer_id











TASK 4 — Daily customer flow VIEW
Создать VIEW:

* customer_id
* date
* total_sent
* total_received
* net_flow


create VIEW daily_customer_flow AS 

with flow as (
select a.customer_id, cast(t.created_at as date) as tx_date,t.amount sent_amount, 0 recived_amount from transactions t
join accounts a on t.from_account_id=a.id 
union all 
select a.customer_id, cast(t.created_at as date) as tx_date,t.amount sent_amount, 0 recived_amount from transactions t
join accounts a on t.to_account_id=a.id 
)

select customer_id, sum(sent_amount) total_sent,sum(recived_amount)total_recived, sum(recived_amount)-sum(sent_amount) net_flow
from flow
group by customer_id



SELECT  a.customer_id, cast(t.created_at as date) as day,
sum(case when t.type='debit' then t.amount else 0 end) total_sent,
sum(case when t.type='credit' then t.amount else 0 end) total_received,
sum(case when t.type='debit' then t.amount else 0 end) -sum(case when t.type='credit' then t.amount else 0 end) 
from transactions t
join accounts a on t.from_account_id=a.id or t.to_account_id=a.id
group by a.customer_id, cast(t.created_at AS date) 






TASK 5 — Fraud signals VIEW
Создать VIEW:

* failed transactions count
* high amount transactions


create view fraud_signals as 
select t.id, count(ft.id) count_fialed_tx, max(t.amount) max_amount_tx from transactions t 
JOIN failed_transactions ft on t.from_account_id=ft.from_account_id or t.to_account_id=ft.to_account_id
group by t.id

select * from  fraud_signals



TASK 6 — Dormant accounts VIEW
Создать VIEW:

* no transactions for 30 days
* balance > 0


create VIEW dormant_accounts as 

select a.id, a.customer_id, a.balance from accounts a
where balance>0 
and not exists (
    select 1 from transactions t
    where (t.from_account_id = a.id or t.to_account_id = a.id)
    and t.created_at>=dateadd(day, -30, GETDATE())
);

SELECT * FROM dormant_accounts;




TASK 7 — High risk customers VIEW
Создать VIEW:

* risk_score > 70
* OR failed transactions > 5
create VIEW high_risk_customers AS
SELECT c.id, c.risk_score, count(ft.id) AS failed_transactions_count
FROM failed_transactions ft
JOIN customers c ON ft.customer_id = c.id
GROUP BY c.id, c.risk_score
HAVING c.risk_score > 70 OR count(ft.id) > 5;



TASK 8 — Loan exposure VIEW
Создать VIEW:

* total loans per customer
* active loans only

create view loan_exposure AS
select customer_id , sum(amount) as total_loans
from loans
where status = 'active'
group by customer_id;






TASK 9 — Card status VIEW
Создать VIEW:

* active / blocked / expired cards


create view card_status
select id, status from cards 
where status in('active', 'blocked', 'expired')



TASK 10 — System money flow VIEW
Создать VIEW:

* inflow vs outflow per day

create view system_money_flow as
select
cast(created_at as date ) as flow_date,
sum(case when type='deposit' then amount else 0 end) total_inflow,
sum(case when type = 'loan' then amount else 0 end ) total_outflow 
from transactions 
where status='success'
group by cast(created_at as date)



## ЧАСТЬ 2 — Функции (FUNCTIONS)
TASK 11 — get_account_balance(account_id)
Создать FUNCTION:

* вернуть баланс


create function get_account_balance(@account_id int) 
returns decimal(12,2) AS
begin 
declare @balance decimal(12,2);
select @balance=balance  from accounts
where id = @account_id 
return coalesce(@balance, 0);
end ;

select dbo.get_account_balance(4) as balance;



TASK 12 — get_customer_net_flow(customer_id)
Создать FUNCTION:

* inflow, outflow, net

create function get_cutomer_net_flow(@customer_id int)
returns decimal(12,2) as 
begin 
declare @inflow decimal(12,2);
declare @outflow decimal(12,2);
declare @net decimal(12,2);

select @inflow=coalesce(sum(t.amount), 0) from transactions t 
join accounts a on t.to_account_id=a.id 
where @customer_id = a.customer_id ;

select @outflow=coalesce(sum(t.amount), 0) from transactions t
join accounts a on t.from_account_id=a.id
where @customer_id = a.customer_id ;


set @net=@inflow-@outflow;

return @net;
end ;

select dbo.get_cutomer_net_flow(1) as net_flow;



TASK 13 — get_risk_score(customer_id)
Создать FUNCTION:

* вычислить риск

create function get_risk_score(@customer_id int)
returns bit 
as 
begin 
declare @risk int;

select @risk=risk_score from customers where id = @customer_id;
set @risk=coalesce(@risk, 0 );

set @risk =@risk+(
select count(*) from failed_transactions 
where customer_id=@customer_id )*5;

set @risk=@risk+(
select count(*) from fraud_alerts fa
join accounts a on fa.account_id=a.id 
where a.customer_id=@customer_id)*10;

return @risk;
end;

select dbo.get_risk_score(34)

drop function get_risk_score


TASK 14 — is_account_safe(account_id)
Создать FUNCTION:

* вернуть TRUE/FALSE

create function is_account_safe(@account_id int)
returns bit 
as begin 

declare @safe bit=1;

if not exists(select 1 from accounts where id=@account_id and status='active' and balance>0)
set @safe=0;

if exists (
select 1 from fraud_alerts where account_id=@account_id)
set @safe=0;

return @safe;

end;


select dbo.is_account_safe (353)



TASK 15 — detect_duplicate_transfer(from,to,amount)
Создать FUNCTION:

* повтор в течение 60 секунд


create function detect_duplicate_safe 
(
@from int,
@to int,
@p_amount decimal(12,2)
)
returns bit as 
begin 

declare @result bit=0;

if exists (select 1 from transactions where from_account_id=@from and to_account_id=@to and amount=@p_amount and status>='success' and created_at=DATEADD(SECOND, -60, GETDATE()))

begin set @result=1;
end
return @result;

end;

select dbo.detect_duplicate_safe (2,45,1233)

DROP FUNCTION detect_duplicate_safe





TASK 16 — get_failed_ratio(account_id)
Создать FUNCTION:

* процент ошибок


create function get_failed_ratio
(
@account_id int
)
returns int
as begin 
declare @total int=0;
declare @failed int=0;
declare @ratio int=0;

select @total=count(*) from transactions where from_account_id=@account_id or to_account_id=@account_id;

select @failed=count(*) from transactions where (from_account_id=@account_id or to_account_id=@account_id and status='failed');

if @ratio>0 set @ratio=(@failed*100)/@total;
else set @ratio=0;

return @ratio;
end;



select dbo.get_failed_ratio(5)

TASK 17 — get_daily_limit_usage(account_id, date)
Создать FUNCTION:

* сумма операций за день


create function get_daily_usage
(
@account_id int,
@p_date date
)
returns decimal(12,2)
as begin 
declare @total decimal(12,2)=0;

select @total=sum(amount) from transactions where (from_account_id=@account_id or to_account_id=@account_id) and cast(created_at as date)=@p_date and status='success';
return coalesce(@total, 0); 
end;


select status, cast(created_at as date) as day from transactions 
where status='success'


SELECT dbo.get_daily_usage(5, '2026-06-04');

TASK 18 — get_account_activity_score(account_id)
Создать FUNCTION:

* активность аккаунта

create function get_account_activity_score
(
@account_id int
)
returns bit
as begin 

declare @result bit=0;

if exists(
select 1 from transactions where (from_account_id=@account_id or to_account_id=@account_id) and created_at>=DATEADD(day, -7, GETDATE()) and status ='success'
)

begin set @result=1
end 
return @result;

end;


select dbo.get_account_activity_score(424)







TASK 19 — get_customer_total_assets(customer_id)
Создать FUNCTION:

* активы - кредиты


create function get_customer_total_assets
(
    @customer_id int
)
returns decimal(12,2) 

as begin 
declare @assets decimal(12,2)=0;
declare @loans decimal(12,2)=0;
declare @reult decimal(12,2)=0;
select @assets=isnull(sum(amount),0) from loans where customer_id=@customer_id;

select @loans=ISNULL(sum(amount),0) from loans where customer_id=@customer_id and status='active';

set @reult=@assets-@loans;

return @reult;
end;

select dbo.get_customer_total_assets(23)



TASK 20 — predict_risk_level(customer_id)
Создать FUNCTION:

* LOW / MEDIUM / HIGH



create function predict_risk_level
(
@customer_id int
)

returns varchar(20)
as begin 
declare @risk int=0;
declare @result nvarchar(20);


select @risk=@risk+count(*)*5 from failed_transactions where customer_id=@customer_id;

select @risk=@risk+count(*)*10 from fraud_alerts fa join accounts a on fa.account_id=a.id where a.customer_id=@customer_id;


select @risk=@risk+count(*)*5 from loans where customer_id=@customer_id and status='active';


if exists (
select 1 from accounts where customer_id=@customer_id and balance<100)
begin 

set @risk=@risk+10

end;

if @risk<10
set @result='low';
else if @risk<30
set @result='medium';
else 
set @result='high';

return @result;
end;


select dbo.predict_risk_level(38)

use RealBankSystem

select * from loans
## ЧАСТЬ 3 — Процедуры (PROCEDURES)
TASK 21 — deposit_money(account_id, amount)
Создать PROCEDURE:

* обновить баланс
* записать transaction
* блокировка аккаунта

create procedure deposit_money
(

@account_id int,
@amount decimal(12,2)
)

as begin 
begin try 
begin tran;

update accounts set balance = balance +@amount
where id=@account_id;

insert into transactions(type,status, from_account_id, to_account_id, amount) values 
('deposit','success',  null, @account_id, @amount) ;
commit ;
end try
begin catch 
rollback ;
throw;
end catch;
end;


exec deposit_money 4,23332

select * from accounts
where id =4




TASK 22 — withdraw_money(account_id, amount)
Создать PROCEDURE:

* проверка баланса
* ошибка при недостатке средств

create procedure withdraw_money(@account_id int , @amount decimal(12,2))
as begin 
declare @balance decimal(12,2);
begin try 
begin tran;

if not exists (select 1 from accounts where id = @account_id)
begin 
throw 50001, N'Account topilmadi', 1;
end;

select @balance=balance from accounts where id=@account_id;

if @balance is null 
begin throw 50002, N'Balance topilmadi', 1;
end;

if @balance<@amount
begin 
throw 50003, N'Balance yetarli emas', 1;
end;

update accounts set balance=balance-@amount
where id =@account_id;

insert into transactions(from_account_id, to_account_id, type, status, amount) values 
(@account_id, null, 'withdraw', 'success', @amount);
print N'Pul muvaffaqiyatli yechildi';

commit 
end try 
begin catch
rollback;
throw;
end catch
end;

exec withdraw_money 4, 23332

select type, count(*) from transactions
group by type



TASK 23 — transfer_money(from,to,amount)
Создать PROCEDURE:

* атомарная операция
* блокировка двух счетов
* защита от дедлока


create procedure transfer_money(@from int, @to int,@amount decimal(12,2))
as begin 
declare @from_balance decimal(12,2);
BEGIN TRY 
begin tran;

if @from<@to 
begin 
select balance from accounts with (updlock, holdlock) where id =@from;
select balance from accounts with (updlock, holdlock) where id =@to;
end;
else 
begin 


select balance from accounts with (updlock, holdlock) where id=@to;
select balance from accounts with(updlock, holdlock) where id = @from;
end;

if not exists (select 1 from accounts where id=@from)
throw 50001, N'from account topilmadi' , 1;
end;


if not exists (select 1 from accounts where id=@to)
throw 50002,N'to akkount topilmadi', 1;
end;

select @from_balance=balance from accounts where id=@from;

if @from_balance<@amount 
throw 50003,N'Balance yetarli emas', 1;
end;


update accounts set balance =balance-@amount
where id =@from;


update accounts set balance=balance+@amount
where id =@to;


insert into transactions(from_account_id, to_account_id, type, status, amount) values 
(@from, @to, 'transfer', 'success', @amount);
commit;

end try
begin catch 
rollback;
throw;
end catch
end;




CREATE PROCEDURE transfer_money
(
    @from_account_id INT,
    @to_account_id INT,
    @amount DECIMAL(12,2)
)
AS
BEGIN
    DECLARE @from_balance DECIMAL(12,2);

    BEGIN TRY
        BEGIN TRAN;

        -- 1. Deadlockni oldini olish uchun lock tartibini bir xil qilish
        -- Kichik ID birinchi lock qilinadi
        IF @from_account_id < @to_account_id
        BEGIN
            -- from accountni lock qilish
            SELECT balance
            FROM accounts WITH (UPDLOCK, HOLDLOCK)
            WHERE id = @from_account_id;

            -- to accountni lock qilish
            SELECT balance
            FROM accounts WITH (UPDLOCK, HOLDLOCK)
            WHERE id = @to_account_id;
        END
        ELSE
        BEGIN
            -- to accountni lock qilish
            SELECT balance
            FROM accounts WITH (UPDLOCK, HOLDLOCK)
            WHERE id = @to_account_id;

            -- from accountni lock qilish
            SELECT balance
            FROM accounts WITH (UPDLOCK, HOLDLOCK)
            WHERE id = @from_account_id;
        END;

        -- 2. accountlar mavjudligini tekshirish
        IF NOT EXISTS (SELECT 1 FROM accounts WHERE id = @from_account_id)
            THROW 50001, N'From account topilmadi', 1;

        IF NOT EXISTS (SELECT 1 FROM accounts WHERE id = @to_account_id)
            THROW 50002, N'To account topilmadi', 1;

        -- 3. balansni olish
        SELECT @from_balance = balance
        FROM accounts
        WHERE id = @from_account_id;

        -- 4. yetarli balans borligini tekshirish
        IF @from_balance < @amount
            THROW 50003, N'Balance yetarli emas', 1;

        -- 5. pul yechish (from accountdan kamaytirish)
        UPDATE accounts
        SET balance = balance - @amount
        WHERE id = @from_account_id;

        -- 6. pul qo‘shish (to accountga qo‘shish)
        UPDATE accounts
        SET balance = balance + @amount
        WHERE id = @to_account_id;

        -- 7. transaction log yozish
        INSERT INTO transactions
        (
            from_account_id,
            to_account_id,
            type,
            status,
            amount,
            created_at
        )
        VALUES
        (
            @from_account_id,
            @to_account_id,
            'transfer',
            'success',
            @amount,
            GETDATE()
        );

        COMMIT;

    END TRY
    BEGIN CATCH
        ROLLBACK;
        THROW;
    END CATCH
END;

exec transfer_money 54,4,543



TASK 24 — freeze_account(account_id, reason)
Создать PROCEDURE:

* изменить статус


create procedure freze_account 
(
@account_id int 
)
as
begin 
begin try 
begin tran;

if not exists (select 1 from accounts where id = @account_id 
)
begin 
throw 50001,N'Account topilmadi', 1;
end;

update accounts set status = 'frozen' where id = @account_id;

commit;

print N'Account muzlatildi';

end try 
begin catch 
rollback;
throw;
end catch 
end;

exec freze_account 4


select * from accounts
where status = 'blocked' 


TASK 25 — unfreeze_account(account_id)
Создать PROCEDURE:

* вернуть active


create procedure unfreeze_account 
(
@account_id int 
)
as
begin 
begin try 
begin tran;

if not exists (select 1 from accounts where id = @account_id 
)
begin 
throw 50001,N'Account topilmadi', 1;
end;

update accounts set status = 'active' where id = @account_id;

commit;

print N'Account activlashtirildi';

end try 
begin catch 
rollback;
throw;
end catch 
end;


exec unfreeze_account 8
select * from accounts
where id =8

TASK 26 — create_loan(customer_id, amount)
Создать PROCEDURE:

* создать кредит

create procedure create_loan 
(
@customer_id int,
@amount decimal(12,2)
)
as begin
begin try 
begin tran;

if not exists (select 1 from customers where id = @customer_id )
begin 
throw 50001, N'Mijoz topilmadi', 1;
end;



if @amount <=0
begin 
throw 50002, N'Loan summasi notog`ri', 1;
end;

if  not exists (select 1 from loans where customer_id=@customer_id and status='active')
begin 
throw 50003, N'Mijoz activ emas', 1;
end;


insert into loans (customer_id, amount, status) values 
(@customer_id, @amount, 'active');

commit;

print N'Loan mufaqayatli olindi';

end try 
begin catch 
rollback;
throw;
end catch 
end;

exec create_loan 28, 434223232

drop procedure create_loan


select status, count(*) from loans
group by status

loans where id = 28


select amount, customer_id, status   from loans 
where id =28
group by customer_id, status,amount
having sum(amount) >0



TASK 27 — repay_loan(loan_id, amount)
Создать PROCEDURE:

* погашение кредита


create procedure repay_loan(@loan_id int, @amount decimal(12,2)) 
as begin declare @current_amount decimal(12,2);
begin try begin tran;

if not exists (select 1 from loans where id=@loan_id) begin 
throw 50001, N'Loan topilmadi',1;
end;

select @current_amount=amount from loans where id =@loan_id;

if @amount <=0 begin 
throw 50002, N'To`lov summasi notog`ri', 1;
end;

if @amount>@current_amount
begin throw 50003, N'To`lov summasi qarzdan katta', 1;
end;

update loans set amount=amount-@amount where id =@loan_id;

update loans set status='closed' where amount=0 and id=@loan_id;
commit;

print N'Qarz muvaffaqiyatli to`landi';

end try 
begin catch 
rollback;
throw;
end catch end;

select * from loans where status='active'
and id =5


select * from loans where status='closed' and id=64

drop procedure repay_loan

exec repay_loan 5, 1000






TASK 28 — add_beneficiary(customer_id, account_id)
Создать PROCEDURE:

* проверка дубликатов


create procedure add_beneficiary(@customer_id int, @account_id int) 
as begin begin try begin tran;

if not exists(select 1 from customers where id=@customer_id) begin 
throw 50001, N'Mijoz topilmadi',1;
end;

if not exists (select 1 from accounts where id=@account_id) begin 
throw 50002, N'Account topilmadi', 1;
end;

if  exists (select 1 from beneficiaries where customer_id =@customer_id and beneficiary_account_id=@account_id) begin 
throw 50003, N'Beneficiary  allaqachon mavjud', 1;
end;

insert into beneficiaries(customer_id, beneficiary_account_id)values 
(@customer_id, @account_id );

commit;

print N'Beneficiary qoshildi';

end try
begin catch 
rollback;
throw;
end catch end;

exec add_beneficiary 4,6



select * from beneficiaries

TASK 29 — rollback_transaction(transaction_id)
Создать PROCEDURE:

* откат операции

use RealBankSystem



create procedure roll_back_tx (@transaction_id int)
as begin

declare @from int, 
@to int, 
@amount decimal(12,2), 
@status nvarchar(20);

begin try begin tran;

if not exists (select 1 from transactions where id =@transaction_id) begin 
throw 50001, N'Transaksiya topilmadi', 1;
end;

select @from=from_account_id, @to=to_account_id, @amount=amount, @status=status  from transactions
where id = @transaction_id;

if @status<>'succuss' begin
throw 50002, N'Rollback bo`lmaydi', 1; 
end;

if (select balance from accounts where id=@to)<@amount begin 
throw 50003, N'Rollback uchun balance yetrali emas', 1;
end;

update accounts set balance=balance-@amount
where id=@to;

update accounts set balance=balance+@amount
where id=@from;

update transactions set status='reversed' where id =@transaction_id;
commit;
print N'Tranzaksiya muvaffaqiyatli bekor qilindi';

end try begin catch rollback; throw; end catch end;


exec roll_back_tx 75

select * from transactions 
where id=75



where status = 'pending'






TASK 30 — generate_statement(customer_id)
Создать PROCEDURE:

* выписка по счету



create procedure generate_statement(@customer_id int) 
as begin 
begin try 

if not exists (select 1 from customers where @customer_id=id) begin 
throw 50001, N'Mijoz topilmadi', 1;
end;



select t.* --t.id, t.from_account_id, t.to_account_id, t.status, t.amount, t.created_at,t.type 
from transactions t
join accounts a on t.from_account_id=a.id or t.to_account_id=a.id 
where a.customer_id=@customer_id
order by t.created_at desc;

end try
begin catch 
throw;
end catch 
end;


exec generate_statement 5


drop procedure generate_statement



TASK 31 — safe_transfer_money
Создать PROCEDURE:

* insufficient funds
* invalid account
* rollback on error


create procedure safe_transfer_money

-- PARAMETER
-- @from INT
-- @to INT
-- @amount DECIMAL(12,2)

(
@from int, 
@to int, 
@amount decimal(12,2)
)
as begin
-- DECLARE
-- @from_balance DECIMAL(12,2)
declare @from_balance decimal(12,2);
begin try 
begin tran;

-- 1. From account mavjudligini tekshir

if not exists (select 1 from accounts where id = @from) begin 
throw 50001, N'From account topilmadi', 1;
end;

-- 2. To account mavjudligini tekshir


if not exists (select 1 from accounts where id = @to) begin 
throw 50002, N'To account topilmadi', 1;
end;






-- 3. From ≠ To ekanini tekshir

if @to=@from begin 
throw 50003, N'Bir xil account transfer mumkin emas', 1;
end;
-- 4. From account balansini olish
select @from_balance=balance from accounts where id=@from
-- 5. Balance < amount bo‘lsa → insufficient funds




if @from_balance<@amount begin 
throw 50004, N'Balans yetarli emas', 1;
end;
-- 6. Transaction boshlash
-- 7. From accountdan pul yechish
update accounts set balance=balance-@amount where id =@from;

-- 8. To accountga pul qo‘shish

update accounts set balance=balance+@amount where id =@to;



-- 9. Transaction log yozish

insert into transactions (from_account_id, to_account_id, status, type, amount)values 
(@from, @to, 'success', 'transfer', @amount)

-- 10. Commit qilish
commit;
print N'Transfer muvaffaqiyatli yakunlandi';

-- 11. Xatolik bo‘lsa rollback qilish
end try 
begin catch 
rollback;
throw;
end catch 
end;


exec safe_transfer_money 15,36,244

select * from transactions 
order by id desc


TASK 32 — safe_withdraw
Создать PROCEDURE:

* обработка исключений при снятии


-- TASK 32 — safe_withdraw

-- PARAMETER
-- @account_id INT
-- @amount DECIMAL(12,2)
create procedure safe_withdraw
(
@account_id int, 
@amount decimal(12,2)
)
as begin
-- DECLARE
-- @balance DECIMAL(12,2)
declare @balance decimal(12,2);
begin try 
begin tran


-- 1. Account mavjudligini tekshirish


if not exists (select 1 from accounts where id=@account_id and status='active') begin 
throw 50001, N'Account mavjud emas',1;
end;
/*
-- 2. Account active ekanini tekshirish
if not exists (select 1 from accounts where status='active') begin 
throw 50002, N'Account active emas', 1;
end*/
-- 3. Balance ni olish

select @balance=balance from accounts where id=@account_id;

if @balance is null begin 
throw 50004, N'Balance topilmadi', 1;
end; 

-- 4. Balance < amount bo‘lsa → insufficient funds
if @balance<@amount begin 
throw 50003, N'Balance yetarli emas', 1;
end;

-- 5. Transaction boshlash
-- 6. Pul yechish (balance = balance - amount)

update accounts set balance =balance-@amount
where id =@account_id ;
-- 7. Transaction log yozish
insert into transactions (from_account_id, to_account_id, type, status, amount) values 
( @account_id,null, 'withdraw', 'success', @amount);

commit;

end try 
begin catch  
rollback;
throw;
end catch
end;

-- 8. Commit qilish
-- 9. Xatolik bo‘lsa rollback qilish
-- 10. THROW qaytarish


insert into transactions (from_account_id, to_account_id, type, status, amount) values 
(null,58, 'withdraw', 'success', 2332)


select * from transactions
where status='withdraw'
where id between 1 and 20






TASK 33 — safe_deposit
Создать PROCEDURE:

* обработка исключений при пополнении

-- TASK 33 — safe_deposit

-- PARAMETER
-- @account_id INT
-- @amount DECIMAL(12,2)

create procedure safe_deposit
(
@account_id int, 
@amount decimal(12,2)
) as begin 

-- DECLARE
-- @balance DECIMAL(12,2)
declare @balance decimal(12,2);

begin try 
begin tran
-- 1. Account mavjudligini tekshirish
-- 2. Account active ekanini tekshirish
if not exists (select 1 from accounts where id = @account_id and status='active') begin 
throw 50001, N'Active account mavjud emas', 1;
end;
-- 3. Amount > 0 ekanini tekshirish
if @amount <= 0 begin 
throw 50003, N'Amount notog`ri', 1;
end;
-- 4. Transaction boshlash
-- 5. Balance ni olish
select @balance=balance from accounts where id=@account_id;
-- 6. Balance ga amount qo‘shish (deposit)
update accounts with(updlock, holdlock) set balance=balance+@amount where id =@account_id;
-- 7. Transaction log yozish
insert into transactions (from_account_id, to_account_id, type, status, amount) values 
(null, @account_id, 'deposit', 'success', @amount);

commit;
end try 
begin catch
rollback;
throw;
end catch 
end;


-- 8. Commit qilish
-- 9. Xatolik bo‘lsa rollback qilish
-- 10. THROW qaytarish




TASK 34 — safe_loan_repayment
Создать PROCEDURE:

* обработка исключений при погашении


create procedure safe_loan_repayment
@loan_id int,
@amount decimal(12,2)
as begin 

begin try
begin tran 
if not exists(select 1 from loans where id=@loan_id and status='active')
begin 
throw 50001, N'Loan topilmadi', 1;
end;

insert into loan_payments(loan_id, amount) values (@loan_id, @amount);
update loans set status='closed' where id =@loan_id;
COMMIt;
end try
begin catch 
ROLLBACK;
throw;
end catch;
end;


exec safe_loan_repayment 1,500

select * from loans where id =1

TASK 35 — safe_card_creation
Создать PROCEDURE:

* duplicate card_number handling

create procedure safe_card_creation 
@account_id int,
@card_number nvarchar(20),
@expiry_date date
as begin
if exists (
    select 1 from cards where card_number=@card_number
)

begin 
throw 50001, N'Bu karta raqam allaqachon mavjud', 1;
end;

insert into cards (account_id, card_number, expiry_date) values (@account_id, @card_number, @expiry_date);
print N'Karta muvaffaqiyatli yaratildi';
end;

EXEC safe_card_creation 1, N'1234', '2028-12-31';




## ЧАСТЬ 4 — Аналитика (ANALYTICS)
TASK 36 — Top active accounts (7 days)
Создать VIEW:

* топ активных аккаунтов за неделю

create view analitika as 

select a.customer_id, a.id,count(t.id)  count_tx  from accounts a
join transactions t on t.from_account_id =a.id or t.to_account_id=a.id 
where t.created_at >=dateadd(day, -7, getdate())
and a.status='active'
group BY a.customer_id, a.id 

TASK 37 — Fastest balance drop accounts
Создать VIEW:

* аккаунты с быстрым падением баланса

create view fastets_account as
with daily as (
    select account_id, cast(created_at as date) as tx_date, sum(case when entry_type='credit' then amount else 0 end) inflow,
    sum(case when entry_type='debit' then amount else 0 end) outflow
    from ledger_entries GROUP BY account_id, cast(created_at as date)
),

net as (
    select account_id, tx_date, inflow-outflow as netflow
    from daily
)
select account_id, sum(netflow) total_netflow from net
group by account_id
having sum(netflow)<0


select * from fastets_account


select * from ledger_entries
TASK 38 — High fraud risk customers
Создать VIEW:

* клиенты с высоким риском мошенничества

create view high_fraud_risk_customers as 
select c.id, c.full_name, c.risk_score, count(ft.id) failed_tx_count, count(fa.id) fraud_alert_count
from customers c
left join failed_transactions ft on c.id=ft.customer_id 
left join fraud_alerts fa on fa.account_id in (select id from accounts where customer_id=c.id )
group by c.id, c.full_name, c.risk_score



TASK 39 — Anomaly detection transactions
Создать VIEW:

* транзакции с аномальными суммами


create view anomaly_detection_transactions as
select id, from_account_id, to_account_id, amount, created_at
from transactions
where amount > 10000 and status='success'


TASK 40 — System liquidity report
Создать VIEW:

* ликвидность системы, inflow vs outflow

create view system_liquidity_report as
select
cast(created_at as date ) as report_date,
sum(case when type='deposit' then amount else 0 end) total_inflow,
sum(case when type = 'loan' then amount else 0 end ) total_outflow
from transactions
where status='success'
group by cast(created_at as date)


