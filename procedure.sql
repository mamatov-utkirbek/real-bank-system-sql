create procedure update_account_status
@account_id int, 
@new_status nvarchar(20)
as begin 
declare @current_status nvarchar(20);
begin try begin tran;

if not exists(select 1 from accounts where id=@account_id)
throw 50001, 'account not found', 1;

if @new_status not in ('active',
        'frozen',
        'closed',
        'blocked',
        'dormant',
        'pending')
throw 50002, 'invailed account status',1;

select @current_status=status from accounts where id=@account_id ;
if @current_status=@new_status 
throw 50003, 'status already assigned',1;

update accounts set status=@new_status, update_at=getdate() where id =@account_id;

commit;

end try 
begin catch 
rollback;
throw;
end catch end;

go;



go;

create procedure add_fraud_alert
@account_id int,
@alert_type nvarchar(50),
@severity int
as begin 
declare @customer_id int;
begin try begin tran;

if not exists(select 1 from accounts where id =@account_id) 
throw 50001, 'account not found', 1;

select @customer_id=customer_id from accounts where id=@account_id ;

if @alert_type not in   ('suspicious_amount', 'rapid_transactions','multiple_failed_logins','usual_location','new_device_login', 'vilocity_check' ,'blacklist_ip', 'card_not_present', 'hogh_risk_country','account_takeover')
throw 50002, 'invailed alert type',1;

if @severity not  between 1 and 10 
throw 50003, 'invalid type',1;

insert into fraud_alerts(account_id, alert_type, severity) values (@account_id, @alert_type, @severity) ;

commit;
end try
begin catch
if @@trancount > 0
rollback;
throw;
end catch 
end;


exec add_fraud_alert 54,'usual_location',  3;

drop procedure add_fraud_alert


select * from fraud_alerts
where account_id =54


go;

create procedure log_failed_transaction 
@from_account_id int,
@to_account_id int,
@amount decimal(12,2),
@error_message nvarchar(max)

as begin 
declare @customer_id int;


begin try begin tran;

if not exists (select 1 from accounts  where id =@from_account_id)
throw 50001, 'not found from_account',1;

if not exists (select 1 from accounts  where id =@to_account_id)
throw 50002, 'not found to_account', 1;


select @customer_id = customer_id from accounts where id=@from_account_id;


if @amount<=0 
throw 50003, 'invalid amount',1;


insert into failed_transactions (from_account_id, to_account_id, amount, error_message, customer_id)values (@from_account_id, @to_account_id, @amount, @error_message, @customer_id);

commit;
end try 
begin catch
rollback;
throw;
end catch 
end;




go;


create procedure update_customer_risk 
@customer_id int,
@new_risk_score int
as begin 
declare @old_risk_score int;
BEGIN try begin tran;

if not exists (SELECT 1 from customers where id =@customer_id )
throw 50001, 'not founnd customer', 1;

select @old_risk_score=risk_score from customers where id =@customer_id;

if @new_risk_score not between 0 and 100
throw 50002, 'invalid risk score',1;

UPDATE customers set risk_score=@new_risk_score where id =@customer_id;

COMMIT;
end try 
BEGIN CATCH
ROLLBACK;
THROW;
end CATch
end;


go;

create procedure send_notification
@customer_id int,
@message NVARCHAR(max)

as begin 
declare @notification_id int;

begin try begin tran;
if not EXISTS(select 1 from customers where id =@customer_id)
THROW 50001, 'customer not found', 1;



if @message is null or trim(@message)=''
THROW 50003, 'message is rewuired',1;

insert into notifications (customer_id, [message]) values (@customer_id,@message);
commit;
end try 
begin catch 
ROLLBACK;
THROW;
end catch 
end;



go;



CREATE procedure close_expired_cards
as begin 
declare @expired_count int;
begin try begin tran;

SELECT @expired_count=count(id) from cards where [status]<>'expired' and expiry_date< GETDATE();

if @expired_count=0
throw 50001, 'no expiry cards not found',1;

update cards set status='expired' where [status]<>'expired' and expiry_date<GETDATE();



set @expired_count=@@ROWCOUNT;
commit;
end try 
BEGIN catch 
ROLLBACK;
THROW;
end CATCH
end;

exec close_expired_cards ;


go;


create procedure archive_old_transactions
as begin 
declare @old_count int ;
begin try begin tran;

select @old_count= count(id) from transactions where [status]='failed' and  created_at<dateadd(day, -30, GETDATE());

if @old_count=0 
throw 50001, 'no old transactions found',1;


DELETE from transactions where [status]='failed' and created_at<DATEADD(day, -30, GETDATE());

set @old_count=@@ROWCOUNT

commit;
end try 
begin CATCH
ROLLBACK;
throw;
end CATCH
end;

go;

create PROCEDURE generate_monthly_statement
@customer_id int,
@month int,
@year int
as BEGIN 
DECLARE @statement_count int;
begin try begin tran;

if not exists (SELECT 1 from customers where id =@customer_id)
throw 50001, 'customer not found', 1;

SELECT @statement_count=COUNT(t.id) from transactions t JOIN accounts a on t.from_account_id=a.id or t.to_account_id=a.id where year(t.created_at)=@year and MONTH(t.created_at)=@month and a.customer_id=@customer_id;

if @statement_count=0 
throw 50002, 'no tx found',1;

commit;
end try 
begin catch 
ROLLBACK;
THROW;
end catch 
end;


-- TASK 59 — update_loan_status PROCEDURE
-- Создать PROCEDURE:
-- * обновление статуса кредита
-- PARAMETER
-- @loan_id INT
-- @new_status NVARCHAR(20)
-- DECLARE
-- @current_status NVARCHAR(20)
-- 1. Transaction boshlash
-- 2. Loan mavjudligini tekshirish
--    loans jadvalidan
-- 3. Yangi status qiymatini tekshirish
--    active, closed
-- 4. Hozirgi loan statusini olish
-- 5. Agar status o‘zgarmasa THROW qaytarish
-- 6. Loan statusini yangilash
-- 7. Commit qilish
-- 8. Xatolik bo‘lsa rollback qilish
-- 9. THROW qaytarish
go;

create procedure update_loan_status 
@loan_id int,
@new_status NVARCHAR(20)
as begin declare @current_status NVARCHAR(20);

BEGIN try BEGIN tran ;

if not EXISTS(SELECT 1 from loans where id=@loan_id)
THROW 50001, 'not found loan', 1;

if @new_status not in('active', 'closed')
throw 50002, 'invalid status', 1;

select @current_status=status from loans where id =@loan_id;

if @current_status=@new_status
throw 50003, 'status alredy set',1;


update loans set [status]=@new_status where id =@loan_id;
commit;
end try 
begin catch 
ROLLBACK;
THROW;
end catch 
end;
-- TASK 60 — record_login_history PROCEDURE
-- Создать PROCEDURE:
-- * запись истории входов
-- PARAMETER
-- @customer_id INT
-- @ip_address NVARCHAR(45)
-- @device NVARCHAR(MAX)
-- DECLARE
-- @login_count INT
-- 1. Transaction boshlash
-- 2. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 3. Login ma'lumotlarini tekshirish
--    ip_address
--    device
-- 4. Login tarixini login_history jadvaliga qo‘shish
-- 5. Qo‘shilgan yozuv sonini olish
--    @@ROWCOUNT orqali
-- 6. Commit qilish
-- 7. Xatolik bo‘lsa rollback qilish
-- 8. THROW qaytarish
go;

create procedure record_login_history 
@customer_id int,
@ip_address NVARCHAR(45),
@device NVARCHAR(max)
as BEGIN
DECLARE @login_count int;
begin try BEGIN TRANSACTION;

if not EXISTS(SELECT 1 from customers where id=@customer_id)
throw 50001,'customer not found',1;

insert into  login_history (customer_id, ip_address, device) values (@customer_id, @ip_address, @device);

set @login_count=@@ROWCOUNT;


COMMIT;
end try 
BEGIN CATCH
ROLLBACK;
THROW;
end CATCH 
end;

