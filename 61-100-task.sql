
-- TASK 61 — safe_card_creation PROCEDURE
-- Создать PROCEDURE:
-- * создание карты
-- PARAMETER
-- @customer_id INT
-- @account_id INT
-- @card_number NVARCHAR(20)
-- @card_type NVARCHAR(20)
-- DECLARE
-- @account_status NVARCHAR(20)
-- 1. Customer mavjudligini tekshirish
-- 2. Account mavjudligini tekshirish
-- 3. Account shu customerga tegishli ekanini tekshirish
-- 4. Account active ekanini tekshirish
-- 5. Card number uzunligi va formatini tekshirish
-- 6. Card number oldin mavjud emasligini tekshirish
-- 7. Transaction boshlash
-- 8. Card yaratish
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish

create PROCEDURE safe_card_creation_add (@customer_id int, @account_id int, @card_number NVARCHAR(20))
as begin
DECLARE @account_status NVARCHAR(20);
begin try BEGIN TRANSACTION

if not EXISTS (SELECT 1 from customers WHERE id = @customer_id)
THROW 50001, N'customer not found', 1;

if not EXISTS(select 1 from accounts where id=@account_id)
THROW 50002, N'Account not found', 1;

IF not EXISTS(SELECT 1 from accounts where id=@account_id and customer_id=@customer_id)
THROW 50003, N'Account does not belong to customer', 1;

if not  EXISTS (select 1 from accounts where status='active' and id=@account_id )
throw 50004, N'Account is not active', 1;

if len( @card_number)<>19
THROW 50005, N'Card number must be  16 digit',1;

if  exists (SELECT 1 from cards where card_number=@card_number)
THROW 50006, N'Card alredy ezists', 1;


INSERT into cards (account_id, status, card_number, expiry_date) VALUEs 
(@account_id, 'active', @card_number, dateadd(month, 18, GETDATE()))

COMMIT;
PRINT N'Success added card';

end try begin catch ROLLBACK;THROW; end CATch end;



EXEC safe_card_creation_add 45,45, '4829 1736 5408 2617';

SELECT * from cards;

SELECT *from accounts ;

drop PROCEDURE safe_card_creation_add;


/*
-- TASK 62 — smart_transfer_with_risk_check PROCEDURE
-- Создать PROCEDURE:
-- * перевод только при низком риске

-- PARAMETER
-- @from_account_id INT
-- @to_account_id INT
-- @amount DECIMAL(18,2)

-- DECLARE
-- @sender_risk_score INT

-- 1. Отправитель account mavjudligini tekshirish
-- 2. Qabul qiluvchi account mavjudligini tekshirish
-- 3. Accountlar bir xil emasligini tekshirish
-- 4. Sender risk_score olish
-- 5. Faqat past risk bo‘lsa transferga ruxsat berish
-- 6. Risk yuqori bo‘lsa THROW qaytarish
-- 7. Sender balansini tekshirish
-- 8. Yetarli mablag‘ bo‘lmasa THROW qaytarish
-- 9. Transaction boshlash
-- 10. Sender account balansidan pul yechish
-- 11. Receiver account balansiga pul qo‘shish
-- 12. Transfer tarixini saqlash
-- 13. COMMIT qilish
-- 14. Xatolik bo‘lsa ROLLBACK qilish
-- 15. CATCH ichida THROW qaytarish*/

select 1 ;

SELECT * FROM customers

create PROCEDURE safe_transfer_with_risk_score (@from int, @to int, @amount DECIMAL(12,2))
as begin 
declare @sender_risk_score int;
DECLARE @sender_balance decimal(12,2);

begin try begin tran;

if not EXISTS(SELECT 1 from accounts  where id=@from)
THROW 50001, N'Not found sender', 1;

if not EXISTS(select 1 from accounts where id=@to)
THROW 50002, N'Not found recipient', 1;


IF @from=@to
THROW 50003, N'the account is the same', 1;

SELECT @sender_risk_score= c.risk_score from customers c join accounts a on a.customer_id=c.id where a.id=@from;

if @sender_risk_score>15
throw 50004, N'Risk is too high', 1;



select @sender_balance=balance from accounts where id =@from;

if @sender_balance<@amount
throw 50005, N'Insufficient balance',1;


UPDATE accounts set balance=balance-@amount
where id=@from;

update accounts set balance=balance+@amount
where id = @to;


insert into transactions(from_account_id, to_account_id, type, status, amount) values 
(@from, @to, 'transfer', 'success', @amount);

commit;

end TRY BEGIN CATCH ROLLBACK; THROW; end CATCH end;




select * from customers

-- TASK 63 — adaptive_withdraw_limit PROCEDURE
-- Создать PROCEDURE:
-- * динамический лимит снятия

-- PARAMETER
-- @account_id INT
-- @amount DECIMAL(12,2)

-- DECLARE
-- @balance DECIMAL(12,2)
-- @risk_score INT
-- @withdraw_limit DECIMAL(12,2)

-- 1. Account mavjudligini tekshirish
-- 2. Account balansini olish
-- 3. Customer risk_score olish
-- 4. Risk asosida withdraw limitni hisoblash
-- 5. Agar summa limitdan oshsa THROW qaytarish
-- 6. Agar balans yetarli bo‘lmasa THROW qaytarish
-- 7. Transaction boshlash
-- 8. Account balansidan pul yechish
-- 9. Withdrawal transaction saqlash
-- 10. COMMIT qilish
-- 11. Xatolik bo‘lsa ROLLBACK qilish
-- 12. CATCH ichida THROW qaytarish

CREATE procedure adaptive_withdraw_limit (@account_id int, @amount DECIMAL(12,2))
as BEGIN 
DECLARE @balance DECIMAL(12,2);
declare @risk_score int;
DECLARE @withdraw_limit DECIMAL(12,2);
BEGIN try begin  tran ;

if not EXISTS(select 1 from accounts where id = @account_id) 
THROW 50001, N'Account not found', 1;

SELECT @risk_score=c.risk_score from customers c join accounts a on a.customer_id=c.id  where a.id= @account_id;

if @risk_score<= 15
set @withdraw_limit =10000;

else if @risk_score<=25
set @withdraw_limit=5000;

else set @withdraw_limit=1000;


if @amount>@withdraw_limit
throw 50002, N'Withdraw limit exceeded', 1;

SELECT @balance= balance from accounts where id = @account_id

if @balance<@amount
throw 50003, N'Insufficient balance', 1;

update accounts set balance=balance-@amount
where id = @account_id

INSERT INTO transactions(from_account_id, to_account_id, type, status, amount) values 
(@account_id, null, 'withdraw', 'success', @amount)
commit;
end try 
begin catch ROLLBACK; THROW; end CATCH end;



-- TASK 64 — risk_based_account_block PROCEDURE
-- Создать PROCEDURE:
-- * автоматическая блокировка на основе скора

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @risk_score INT
-- @account_status NVARCHAR(20)

-- 1. Account mavjudligini tekshirish
-- 2. Account customer_id orqali risk_score olish
-- 3. Risk_score yuqori bo‘lsa accountni bloklash
-- 4. Risk_score past bo‘lsa bloklamaslik
-- 5. Account statusini tekshirish
-- 6. Transaction boshlash
-- 7. Account statusini blocked ga o‘zgartirish
-- 8. Account block tarixini saqlash
-- 9. COMMIT qilish
-- 10. Xatolik bo‘lsa ROLLBACK qilish
-- 11. CATCH ichida THROW qaytarish


create procedure risk_based_account_block (@account_id int)
as BEGIN 
declare @risk_score int;
begin try begin tran;

if not EXISTS (select 1 from accounts where id =@account_id)
throw 50001, 'account not found', 1 ;

if not exists (select 1 from customers c join accounts a on a.customer_id=c.id where a.id=@account_id )
THROW 50003, 'customer account not found', 1;

select @risk_score = c.risk_score from customers c join accounts a on a.customer_id=c.id where a.id=@account_id


if @risk_score>25
BEGIN
update accounts set status='blocked'
WHERE id =@account_id;
END


commit;
end try
begin catch 
ROLLBACK;
THROW;
end catch end;





-- TASK 66 — customer_risk_recalculate PROCEDURE
-- Создать PROCEDURE:
-- * пересчёт риска клиента
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @risk_score INT
-- @failed_count INT
-- @fraud_count INT
-- @account_count INT
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Customer account sonini olish
--    accounts jadvalidan
-- 3. Failed transaction sonini hisoblash
--    failed_transactions jadvalidan
-- 4. Fraud alert sonini hisoblash
--    fraud_alerts jadvalidan
-- 5. Risk score hisoblash
--    boshlang‘ich 0
--    failed transaction ko‘p bo‘lsa oshirish
--    fraud alert mavjud bo‘lsa oshirish
--    account soni bo‘yicha hisoblash
-- 6. Risk score 0-100 oralig‘ida bo‘lishi
-- 7. customers jadvalidagi risk_score ni yangilash
-- 8. Transaction boshlash
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish

create procedure customer_risk_recalculate (@customer_id int) 
as begin 
declare @risk_score int;
declare @failed_count int;
declare @fraud_count int;
declare @account_count int;
begin try begin tran;

if not exists (select 1 from customers where id = @customer_id)
throw 50001, 'Customer not found', 1;

select @account_count=count(a.id) from customers c join accounts a on a.customer_id=c.id where c.id=@customer_id;

select @failed_count=count(t.id) from accounts a join transactions t on t.from_account_id=a.id or t.to_account_id=a.id where t.status='failed' and a.customer_id=@customer_id;
select @fraud_count= count(fa.id) from accounts a join fraud_alerts fa on fa.account_id=a.id where a.customer_id=@customer_id;


set @risk_score=0;
if @failed_count>=5
set @risk_score+=30;
else if @failed_count>0
set @risk_score+=10;

if @fraud_count>0
set @risk_score+=40;

if @account_count>3
set @risk_score+=10;

if @risk_score>100
set @risk_score=100;

if @risk_score<0
set @risk_score=0;

update customers set risk_score=@risk_score where id=@customer_id;
commit;

end try 
begin catch rollback; throw; end catch end;


-- TASK 66 — fraud_case_creation PROCEDURE
-- Создать PROCEDURE:
-- * создание дела для расследования
-- PARAMETER
-- @account_id INT
-- @alert_type NVARCHAR(50)
-- DECLARE
-- @fraud_count INT
-- @customer_id INT
-- @severity INT
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account customer_id olish
--    accounts jadvalidan
-- 3. Fraud alert mavjudligini tekshirish
--    fraud_alerts jadvalidan
-- 4. Agar fraud alert mavjud bo‘lmasa
--    yangi fraud alert yaratish
-- 5. Severity aniqlash
--    alert_type asosida
-- 6. fraud_alerts jadvaliga investigation uchun yozuv kiritish
-- 7. Account status tekshirish
--    accounts jadvalidan
-- 8. Agar account xavfli holatda bo‘lsa
--    status yangilash
-- 9. Transaction boshlash
-- 10. Commit qilish
-- 11. Xatolik bo‘lsa rollback qilish
-- 12. THROW qaytarish
create procedure fraud_creation_case(@account_id int, @alert_type nvarchar(50)) 
as begin 
declare @froud_count int;
declare @customer_id int;
declare @severity int;

begin try begin tran;


if not exists (select 1 from accounts where id=@account_id)
throw 50001, N'Account not found', 1;

select @customer_id = customer_id from accounts where id=@account_id;

select @froud_count=count(id) from fraud_alerts where alert_type=@alert_type and account_id=@account_id;

if @froud_count=0
begin 

if @alert_type in (N'account_takeover',N'blacklist_ip',N'hogh_risk_country')
set @severity=3;

else if @alert_type in (N'rapid_transactions',N'multiple_failed_logins',N'card_not_present')
set @severity=2 
else 
set @severity=1;


insert into fraud_alerts(account_id, alert_type, severity) values 
(@account_id, @alert_type, @severity) ;
end

commit;
end try 
begin catch 
rollback;
throw;
end catch 
end;

exec fraud_creation_case 45, N'account_takeover'


select * from fraud_alerts





-- TASK 67 — smart_deposit_validation PROCEDURE
-- Создать PROCEDURE:
-- * правила валидации пополнения
-- PARAMETER
-- @account_id INT
-- @amount DECIMAL(12,2)
-- DECLARE
-- @status NVARCHAR(20)
-- @balance DECIMAL(12,2)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account status olish
--    accounts jadvalidan
-- 3. Account active ekanini tekshirish
-- 4. Amount > 0 validation qilish
-- 5. Amount limitini tekshirish
-- 6. Agar account blocked/frozen/closed bo‘lsa
--    'UNSAFE' qaytarish
-- 7. Agar validation muvaffaqiyatli bo‘lsa
--    deposit qilishga ruxsat berish
-- 8. Transaction boshlash
-- 9. Xatolik bo‘lsa rollback qilish
-- 10. THROW qaytarish

create procedure smart_deposit_validation(@account_id int, @amount decimal(12,2))
as begin 
declare @status nvarchar(20);
declare @balance decimal(12,2);
begin try begin tran;

if not exists (select 1 from accounts where id =@account_id) 
throw 50001,'account not found', 1;



select @status=status from accounts where id = @account_id;


if exists (select 1 from accounts where id=@account_id and status<>'active') 
throw 50002, 'account  is not active', 1;

if @amount<=0 
throw 50003, 'amount must be greater than zero',1;

commit;
end try 
begin catch rollback;
throw;
end catch 
end;



-- TASK 68 — emergency_fund_lock PROCEDURE
-- Создать PROCEDURE:
-- * заморозка средств при кризисе
-- PARAMETER
-- @account_id INT
-- @reason NVARCHAR(MAX)
-- DECLARE
-- @balance DECIMAL(12,2)
-- @status NVARCHAR(20)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account status olish
--    accounts jadvalidan
-- 3. Agar account allaqachon blocked/frozen bo‘lsa
--    xatolik qaytarish
-- 4. Account balance olish
--    accounts jadvalidan
-- 5. Account freeze sababini tekshirish
--    reason bo‘sh bo‘lmasligi
-- 6. account_freeze jadvaliga yozuv kiritish
--    account_id
--    reason
-- 7. Account statusini frozen qilish
--    accounts jadvalidan
-- 8. Transaction boshlash
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish

create procedure emergency_fund_lock(@account_id int, @reason nvarchar(max))
as begin 
declare @balance decimal(12,2);
declare @status nvarchar(20);

begin try begin tran;

if not exists (select 1 from accounts where id=@account_id)
throw 50001, 'account not found', 1;

select @status=status from accounts where id=@account_id;

if exists (select 1 from accounts where status in ('blocked', 'frozen') and id =@account_id)
throw 50002, 'account bloked or frozen', 1;
select @balance= balance from accounts where id =@account_id;
if @reason is null or @reason=''
throw 50003, 'reason is required',1;
 insert into account_freeze(account_id, reason) values (@account_id, @reason);
update accounts set status='frozen'
where id =@account_id

commit;
end try 
begin catch 
rollback;
throw;
end catch end;

exec emergency_fund_lock 35, 'KYC pending'

select * from account_freeze

update accounts set status='active' 
where id =35


update accounts
set status='active'
where id=35;

update account_freeze
set unfrozen_at=getdate()
where account_id=35
and unfrozen_at is null;

-- TASK 69 — account_recovery_engine PROCEDURE
-- Создать PROCEDURE:
-- * восстановление подозрительных счетов
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @status NVARCHAR(20)
-- @freeze_count INT
-- @risk_score INT
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account status olish
--    accounts jadvalidan
-- 3. Account freeze mavjudligini tekshirish
--    account_freeze jadvalidan
-- 4. Customer risk_score olish
--    customers jadvalidan
-- 5. Agar risk_score yuqori bo‘lsa
--    tiklashni rad etish
-- 6. Agar active tiklash mumkin bo‘lsa
--    accounts.status = 'active'
-- 7. account_freeze jadvalidagi ochilmagan freeze yozuvlarini yangilash
--    unfrozen_at = GETDATE()
-- 8. Transaction boshlash
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish
create account_recovery_engine(@account_id int)
as begin 
declare @status nvarchar(20);
declare @freeze_count int;
declare @risk_score int;

begin try begin tran;

if not exists (select 1 from accounts where id =@account_id)
throw 50001, 'account not found', 1;

select @status=status from accounts where id=@account_id;

if  @status='active' 
throw 50002, 'account is not frozen',1;

select @risk_score=c.risk_score from customers c join accounts a on a.customer_id=c.id where  a.id =@account_id;

select @freeze_count= count(*) from account_freeze where unfrozen_at is null and account_id=@account_id;


if @risk_score>25
throw 50003, 'high risk', 1;

if @freeze_count=0
throw 50004, 'freeze not found',1;
 
update accounts set status='active'
where id =@account_id;

update account_freeze 
set unfrozen_at=GETDATE()
where account_id=@account_id and unfrozen_at is null;
commit;
 

end try 
begin catch 
rollback;
throw;
end catch end;




-- TASK 70 — transaction_reconciliation PROCEDURE
-- Создать PROCEDURE:
-- * исправление несоответствий балансов
-- PARAMETER
-- @transaction_id INT
-- DECLARE
-- @from_account_id INT
-- @to_account_id INT
-- @amount DECIMAL(12,2)
-- @from_balance DECIMAL(12,2)
-- @to_balance DECIMAL(12,2)
-- 1. Transaction mavjudligini tekshirish
--    transactions jadvalidan
-- 2. Transaction ma'lumotlarini olish
--    from_account_id
--    to_account_id
--    amount
-- 3. Ikkala account mavjudligini tekshirish
--    accounts jadvalidan
-- 4. From account balance olish
-- 5. To account balance olish
-- 6. Agar transaction status failed bo‘lsa
--    balansni o‘zgartirmaslik
--    xatolik qaytarish
-- 7. Agar transfer summasi noto‘g‘ri bo‘lsa
--    amount <= 0
--    xatolik qaytarish
-- 8. Balanslar orasida nomuvofiqlik aniqlansa
--    from_account balance tiklash
--    to_account balance tiklash
-- 9. Transaction status yangilash
--    success
-- 10. Transaction boshlash
-- 11. Commit qilish
-- 12. Xatolik bo‘lsa rollback qilish
-- 13. THROW qaytarish
create procedure transaction_reconciliation(@tx_id int)
as begin 
declare @from int;
declare @to int;
declare @to_balance decimal(12,2);
declare @from_balance decimal(12,2);
declare @amount decimal(12,2);
declare @ledger_from_balance decimal(12,2);
declare @ledger_to_balance decimal(12,2);
begin try begin tran;

if not exists (select 1 from transactions where id =@tx_id)
throw 50001, 'Transaction not found', 1;

select @from=from_account_id, @to= to_account_id, @amount= amount from transactions where id=@tx_id;

if @from=@to
throw 50002, 'same account transfer', 1;

if not exists (select 1 from accounts where id=@from)
throw 50003, 'from account not found',1;

if not exists (select 1 from accounts where id =@to)
throw 50004, 'to account not found', 1;

if exists (select 1 from transactions where status='failed' and id=@tx_id)
throw 50005, 'transaction is failed', 1;

if @amount<=0
throw 50006, 'amount must be greater than zero', 1;

select @from_balance=balance from accounts where id=@from;
select @to_balance=balance from accounts where id=@to;

select @ledger_from_balance=sum(case when entry_type='credit' then amount when entry_type='debit' then -amount end) from ledger_entries where account_id=@from;
select @ledger_to_balance=sum(case when entry_type='credit' then amount when entry_type='debit' then -amount end) from ledger_entries where account_id=@to;

if @from_balance<>@ledger_from_balance
update accounts set balance=@ledger_from_balance
where id =@from;

if @to_balance<>@ledger_to_balance
update accounts set balance=@ledger_to_balance
where id=@to;

update transactions set status='success' where id =@tx_id;
commit;
end try 
begin catch 
rollback;
throw;
end catch 
end;

-- TASK 71 — customer_risk_recalculation PROCEDURE
-- Создать PROCEDURE:
-- * полный пересчет рисков
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @risk_score INT
-- @failed_count INT
-- @fraud_count INT
-- @account_count INT
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Customer account sonini olish
--    accounts jadvalidan
-- 3. Failed transaction sonini hisoblash
--    transactions jadvalidan
--    status='failed'
-- 4. Fraud alert sonini hisoblash
--    fraud_alerts jadvalidan
-- 5. Boshlang‘ich risk score
--    0 qilish
-- 6. Failed transaction bo‘yicha risk oshirish
--    ko‘p bo‘lsa +30
--    mavjud bo‘lsa +10
-- 7. Fraud alert mavjud bo‘lsa
--    +40 qo‘shish
-- 8. Account soni bo‘yicha risk hisoblash
-- 9. Risk score 0-100 oralig‘ida bo‘lishi
-- 10. customers jadvalidagi risk_score yangilash
-- 11. Transaction boshlash
-- 12. Commit qilish
-- 13. Xatolik bo‘lsa rollback qilish
-- 14. THROW qaytarish

create procedure customer_risk_recalculation(@customer_id int) 
as begin 
declare @risk_score int;
declare @failed_count int;
declare @froud_count int;
declare @account_count int;

begin try begin tran;

if not exists (select 1 from customers where id =@customer_id)
throw 50001, 'customer not found', 1;

select @account_count=count(*) from accounts where customer_id=@customer_id
select @failed_count=count(t.id) from transactions t join accounts a on t.from_account_id=a.id or t.to_account_id=a.id 
where t.status='failed' and a.customer_id=@customer_id;
select @froud_count= count(fa.id) from fraud_alerts fa join accounts a on fa.account_id=a.id where a.customer_id=@customer_id;

set @risk_score=0;
if @failed_count>5
set @risk_score+=30;
else if @failed_count>0
set @risk_score+=10;

if @froud_count>0
set @risk_score+=40;

if @account_count>3
set @risk_score+=10;

if @risk_score>100
set @risk_score=100;

update customers set risk_score=@risk_score
where id =@customer_id;
commit;
end try 
begin catch
rollback; throw; end catch end;



-- TASK 72 — emergency_lockdown PROCEDURE
-- Создать PROCEDURE:
-- * аварийная блокировка
-- PARAMETER
-- @account_id INT
-- @reason NVARCHAR(MAX)
-- DECLARE
-- @status NVARCHAR(20)
-- @risk_score INT
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account status olish
-- 3. Customer risk score olish
--    customers jadvalidan
-- 4. Agar account allaqachon blocked bo‘lsa
--    xatolik qaytarish
-- 5. Agar risk score yuqori bo‘lsa
--    emergency block qilish
-- 6. Reason bo‘sh bo‘lmasligini tekshirish
-- 7. Account status yangilash
--    blocked
-- 8. account_freeze jadvaliga sabab yozish
-- 9. fraud_alerts jadvaliga alert yaratish
--    alert_type = 'account_takeover'
-- 10. Transaction boshlash
-- 11. Commit qilish
-- 12. Xatolik bo‘lsa rollback qilish
-- 13. THROW qaytarish
select  * from fraud_alerts

create procedure emergency_lockdown(@account_id int,  @reason nvarchar(max))
as begin 
declare @status nvarchar(20);
declare @risk_score int;

begin try begin tran;

if not exists (select 1 from accounts where id =@account_id)
throw 50001, 'account not found', 1; 

select @status=status from accounts where id=@account_id;

if @reason is null or @reason=''
throw 50003, 'reason is required',1;

if @status='blocked' 
throw 50002, 'account alredy blocked',1;



select @risk_score=c.risk_score from customers c join accounts a on a.customer_id=c.id where a.id =@account_id;

if @risk_score<=25
throw 50004, 'risk score is not high', 1;
update accounts set status='blocked'
where id =@account_id;

insert into fraud_alerts (account_id, alert_type, severity) values 
(@account_id, 'account_takeover', 5);
OOoOOOO
insert into account_freeze (account_id, reason) values
(@account_id, @reason)


commit;

end try
begin catch rollback;
throw;
end catch end;
OoO

-- TASK 73 — batch_settlement PROCEDURE
-- Создать PROCEDURE:
-- * массовые операции
-- PARAMETER
-- @date DATE
-- DECLARE
-- @transaction_id INT
-- @account_id INT
-- @amount DECIMAL(12,2)
-- @status NVARCHAR(20)
-- 1. Berilgan sana bo‘yicha pending transactionlarni olish
--    transactions jadvalidan
-- 2. Har bir transaction uchun tekshirish
-- 3. Transaction account mavjudligini tekshirish
--    accounts jadvalidan
-- 4. Transaction amount tekshirish
--    amount > 0 bo‘lishi
-- 5. Pending transactionlarni settlement qilish
-- 6. Transaction status yangilash
--    success
-- 7. Account balance yangilash
-- 8. Barcha operatsiyalarni transaction ichida bajarish
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish

CREATE procedure batch_settlement(@date date ) 
as begin 
	declare @tx_id int;
declare @account_id int;
declare @amount decimal(12,2);
declare @status nvarchar(20);

begin try begin tran;

declare batch_cursor cursor for 
select id, from_account_id, amount, status  from transactions 
where cast(created_at as date)=@date and
status='pending ';

open batch_cursor;

fetch next from batch_cursor into @tx_id, @account_id, @amount, @status
while @@fetch_status=0
begin 
	if not exists (SELECT 1 from accounts where id=@account_id )
	throw 50001, 'account not found', 1;
if @amount<=0
throw 50002, 'amount must be greater than zero', 1;

UPDATE transactions set status='success '
where id =@tx_id;
update accounts set balance =balance +@amount where id=@account_id;

fetch next from batch_cursor 
into @tx_id, @account_id, @amount, @status;

end


close batch_cursor;
deallocate batch_cursor;



commit;
end try 
begin catch
rollback;
throw;
end catch 
end;

-- TASK 74 — reconcile_accounts PROCEDURE
-- Создать PROCEDURE:
-- * сверка счетов
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @balance DECIMAL(12,2)
-- @ledger_balance DECIMAL(12,2)
-- @difference DECIMAL(12,2)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account balansini olish
--    accounts jadvalidan
-- 3. Ledger balansini hisoblash
--    ledger_entries jadvalidan
-- 4. Account balance va ledger balance solishtirish
-- 5. Farqni hisoblash
-- 6. Agar farq mavjud bo‘lsa
--    balansni tuzatish
-- 7. Account balance yangilash
-- 8. Transaction boshlash
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish
create procedure reconcile_accounts(@account_id int)
as begin 
declare @balance decimal(12,2);
declare @ledger_balance decimal(12,2);
declare @diffrence decimal(12,2);

begin try begin tran;

if not exists (select 1 from accounts where id = @account_id) 
throw 50001, 'account not found',1;


select @balance=balance from accounts where id =@account_id;

select @ledger_balance=sum(case when entry_type='credit' then amount when entry_type='debit' then -amount end ) from ledger_entries where account_id=@account_id;


set @diffrence=@balance	-@ledger_balance;


if @diffrence<>0
begin 
update accounts set balance=@ledger_balance where id =@account_id;
end


commit;
end try begin catch rollback;
throw; end catch end;






-- TASK 75 — fraud_report_generator PROCEDURE
-- Создать PROCEDURE:
-- * отчет по fraud
-- PARAMETER
-- @date DATE
-- DECLARE
-- @fraud_count INT
-- @blocked_count INT
-- @total_amount DECIMAL(12,2)
-- 1. Berilgan sana bo‘yicha fraud alertlarni olish
--    fraud_alerts jadvalidan
-- 2. Fraud alert sonini hisoblash
-- 3. Block qilingan accountlar sonini hisoblash
--    accounts jadvalidan
-- 4. Fraud bilan bog‘liq transaction summasini hisoblash
--    transactions jadvalidan
-- 5. Fraud hisobotini chiqarish:
--    fraud_count
--    blocked_count
--    total_amount
-- 6. Transaction boshlash
-- 7. Commit qilish
-- 8. Xatolik bo‘lsa rollback qilish
-- 9. THROW qaytarish

create procedure fraud_report_generator (@date date) 
as begin 
declare @fraud_count int;
declare @blocked_count int;
declare @total_amount decimal(12,2);

begin try begin tran;

select @fraud_count= count(*) from fraud_alerts where cast(created_at as date )=@date

select @blocked_count=count(distinct a.id) from accounts a join fraud_alerts fa on fa.account_id=a.id where a.status='blocked' and cast(fa.created_at as date)=@date;


select @total_amount=isnull(sum(t.amount),0) from transactions t where exists (select 1 from fraud_alerts fa where fa.account_id in( t.from_account_id, t.to_account_id) and cast(fa.created_at as date) =@date);

select @fraud_count as fraud_count, @total_amount as total_amount, @blocked_count as blocked_count ;

commit;
end try
begin catch 
rollback;
throw;
end catch end;




-- ---
-- TASK 76 — Prevent negative balance trigger
-- Создать TRIGGER:
-- * баланс < 0 запрет

-- TABLE
-- accounts

-- TRIGGER TYPE
-- AFTER UPDATE

-- 1. Balance yangilanishidan keyin tekshirish
-- 2. Agar balance < 0 bo‘lsa
--    xatolik qaytarish
-- 3. Update operatsiyasini bekor qilish
-- 4. ROLLBACK qilish
-- 5. THROW qaytarish

create trigger prevent_negative_balance
on accounts 
after update 
as begin 
if exists (select 1 from inserted where balance<0)

begin 
rollback;
throw 50001, 'balance cannot be nrgative',1;

end
end;

-- TASK 77 — prevent_self_transfer trigger
-- Создать TRIGGER:
-- * перевод самому себе
-- TABLE
-- transactions
-- TRIGGER TYPE
-- AFTER INSERT
-- 1. Yangi transaction qo‘shilganda tekshirish
--    inserted jadvalidan
-- 2. Agar from_account_id = to_account_id bo‘lsa
--    xatolik qaytarish
-- 3. Transactionni bekor qilish
--    ROLLBACK qilish
-- 4. THROW qaytarish
create trigger prevent_self_transfer
on transactions 
after insert 
as begin 
if exists (select 1 from inserted where from_account_id=to_account_id) 

begin rollback;
throw 50001, 'cannot transfer sam ccount', 1;

end end;





-- TASK 78 — audit_log_trigger trigger
-- Создать TRIGGER:
-- * лог всех операций
-- TABLE
-- accounts
-- TRIGGER TYPE
-- AFTER INSERT, UPDATE, DELETE
-- 1. Account jadvalidagi barcha operatsiyalarni kuzatish
-- 2. INSERT operatsiyasini log qilish
--    inserted jadvalidan
-- 3. UPDATE operatsiyasini log qilish
--    inserted va deleted orqali
-- 4. DELETE operatsiyasini log qilish
--    deleted jadvalidan
-- 5. Audit jadvaliga yozuv qo‘shish:
--    table_name
--    operation_type
--    record_id
-- 6. Xatolik bo‘lsa operatsiyani bekor qilish
--    ROLLBACK qilish
-- 7. THROW qaytarish
create trigger audit_log_trigger 
on accounts 
after insert, update, delete
if exists(select 1 from inserted

-- TASK 79 — fraud_alert_trigger trigger
-- Создать TRIGGER:
-- * fraud alerts
-- TABLE
-- transactions
-- TRIGGER TYPE
-- AFTER INSERT
-- 1. Yangi transaction qo‘shilganda tekshirish
--    inserted jadvalidan
-- 2. Katta summadagi transactionlarni aniqlash
-- 3. Shubhali transactionlarni aniqlash
-- 4. Fraud alert yaratish
--    fraud_alerts jadvaliga
-- 5. Alert uchun account_id yozish
-- 6. Alert turi yozish
--    suspicious_transaction
-- 7. Severity qiymatini yozish
-- 8. Alert yaratilgan sanani saqlash
-- 9. Xatolik bo‘lsa ROLLBACK qilish
-- 10. THROW qaytarish

create trigger fraud_alert_trigger 
on transactions 
after insert 
as begin 

insert into fraud_alerts(account_id, alert_type, severity) 
select from_account_id, 'suspicious_transaction', 5
from inserted where amount>10000;
end;




-- TASK 80 — data_integrity_check_trigger trigger
-- Создать TRIGGER:
-- * проверка целостности данных
-- TABLE
-- accounts
-- TRIGGER TYPE
-- AFTER INSERT, UPDATE
-- 1. Yangi yoki o‘zgartirilgan ma'lumotlarni tekshirish
--    inserted jadvalidan
-- 2. Majburiy maydonlar bo‘sh emasligini tekshirish
-- 3. Noto‘g‘ri qiymatlarni aniqlash
-- 4. Ma'lumotlar yaxlitligini tekshirish
-- 5. Xato ma'lumot aniqlansa
--    operatsiyani bekor qilish
-- 6. ROLLBACK qilish
-- 7. THROW qaytarish

create trigger data_integrity_check_trigger
on accounts 
after insert, update
as begin 
begin try 
if exists (select 1 from inserted where balance <0 customer_id is null or status is null) 
begin

rollback;
throw 50001, N'data integrity violation', 1;
end 
if exists (select 1 from inserted i left join customers c on c.id=i.customer_id where c.id is null) begin rollback;
throw 50002, N'customer refernces not found', 1;
end 
end try 
begin catch rollback;
throw;
end catch end;





-- TASK 81 — High amount trigger
-- Создать TRIGGER:
-- * большие суммы

-- TASK 82 — Rapid transaction trigger
-- Создать TRIGGER:
-- * слишком частые операции

-- TASK 83 — Duplicate transfer trigger
-- Создать TRIGGER:
-- * дубликаты переводов

-- TASK 84 — velocity_anomaly_trigger
-- Создать TRIGGER:
-- * слишком быстрые транзакции

-- TASK 85 — login_device_change_trigger
-- Создать TRIGGER:
-- * обнаружение нового устройства

-- TASK 86 — multi_account_abuse_trigger
-- Создать TRIGGER:
-- * одинаковое поведение на нескольких счетах

-- TASK 87 — sudden_balance_spike_trigger
-- Создать TRIGGER:
-- * аномальный скачок пополнения

-- TASK 88 — repeated_failed_login_trigger
-- Создать TRIGGER:
-- * обнаружение подбора пароля

-- TASK 89 — card_usage_abroad_trigger
-- Создать TRIGGER:
-- * использование карты за границей

-- TASK 90 — loan_default_risk_trigger
-- Создать TRIGGER:
-- * предупреждение о риске дефолта по кредиту

-- TASK 91 — system_load_warning_trigger
-- Создать TRIGGER:
-- * риск производительности системы

-- TASK 92 — suspicious_beneficiary_trigger
-- Создать TRIGGER:
-- * обнаружение рискованного получателя

-- TASK 93 — real_time_fraud_block_trigger
-- Создать TRIGGER:
-- * мгновенная блокировка при мошенничестве

-- TASK 94 — Cashback trigger
-- Создать TRIGGER:
-- * начисление cashback

-- TASK 95 — Fee trigger
-- Создать TRIGGER:
-- * списание комиссии

-- TASK 96 — Interest trigger
-- Создать TRIGGER:
-- * начисление процентов

-- TASK 97 — Inactivity trigger
-- Создать TRIGGER:
-- * неактивность

-- TASK 98 — System health trigger
-- Создать TRIGGER:
-- * здоровье системы

-- TASK 99 — Liquidity protection trigger
-- Создать TRIGGER:
-- * защита ликвидности

-- TASK 100 — Loan overdue trigger
-- Создать TRIGGER:
--  просрочка кредита 

select 1 ;

SELECT * FROM account_freeze af 






SELECT local_tcp_port 
FROM sys.dm_exec_connections 
WHERE local_tcp_port IS NOT NULL;






































SELECT * FROM customers 























