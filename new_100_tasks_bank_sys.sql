-- ============================================================
-- REAL BANK SYSTEM — 100 TASK (YANGI, OXSHAMAYDI)
-- ============================================================

-- ============================================================
-- VIEW (1-25)
-- ============================================================

-- TASK 1 — account_opening_trends VIEW
-- Создать VIEW:
-- * количество открытых счетов по месяцам
-- * средний начальный баланс
-- * статус счетов

-- PARAMETER
-- TABLE: accounts

-- 1. accounts jadvalidan account ochilgan sanani olish
-- 2. Account ochilgan oy bo‘yicha guruhlash
-- 3. Har bir oyda ochilgan accountlar sonini hisoblash
-- 4. Har bir oy uchun o‘rtacha boshlang‘ich balansni hisoblash
-- 5. Account statuslarini aniqlash
-- 6. Status bo‘yicha accountlar taqsimotini chiqarish
-- 7. NULL qiymatlarni COALESCE orqali 0 ga aylantirish
-- 8. Natijani quyidagi ustunlarda chiqarish:
--    opening_month
--    account_count
--    avg_initial_balance
--    account_status
-- 9. Opening month bo‘yicha GROUP BY qilish
-- 10. Natijani oy bo‘yicha tartiblash


create view account_opening_trends as 
SELECT format(a.created_at, 'yyyy-MM'), count(a.id),avg(a.balance), a.status  from accounts a 
GROUP BY FORMAT(a.created_at, 'yyyy-MM'), a.status



-- TASK 2 — customer_contact_frequency VIEW
-- Создать VIEW:
-- * частота входов в систему
-- * последний вход
-- * общее количество сессий

-- PARAMETER
-- TABLE: customers, login_sessions

-- 1. customers jadvalini login_sessions jadvali bilan JOIN qilish
-- 2. Har bir customer uchun login sonini hisoblash
-- 3. Har bir customer uchun oxirgi login sanasini topish
-- 4. Har bir customer uchun umumiy sessiyalar sonini hisoblash
-- 5. Login frequency ko‘rsatkichini hisoblash
-- 6. NULL qiymatlarni COALESCE orqali 0 ga aylantirish
-- 7. Customer_id bo‘yicha GROUP BY qilish
-- 8. Natijada quyidagi ustunlarni chiqarish:
--    customer_id
--    full_name
--    login_frequency
--    last_login_date
--    total_sessions
-- 9. Natijani customer_id bo‘yicha tartiblash

create view customer_contact_frequency as 
select c.id, c.full_name, count(lg.id),max(lg.created_at )   from customers c  join login_history lg on lg.customer_id=c.id 
GROUP by c.id, c.full_name 


-- TASK 3 — notification_delivery_stats VIEW
-- Создать VIEW:
-- * доставленные уведомления
-- * прочитанные уведомления
-- * процент прочтения

-- PARAMETER
-- TABLE: notifications

-- 1. notifications jadvalidan ma'lumotlarni olish
-- 2. Har bir foydalanuvchi bo‘yicha bildirishnomalarni guruhlash
-- 3. Yetkazilgan bildirishnomalar sonini hisoblash
-- 4. O‘qilgan bildirishnomalar sonini hisoblash
-- 5. Yetkazilgan va o‘qilgan bildirishnomalar nisbatini aniqlash
-- 6. O‘qilish foizini hisoblash
-- 7. NULL qiymatlarni COALESCE orqali 0 ga aylantirish
-- 8. Foydalanuvchi identifikatori bo‘yicha GROUP BY qilish
-- 9. Natijada quyidagi ustunlarni chiqarish:
--    user_id
--    delivered_count
--    read_count
--    read_percentage
-- 10. Natijani user_id bo‘yicha tartiblash

select n.customer_id, count(n.id), sum(case when n.is_read=1 then 1 0 end )read_notifacation , 
coalesce(sum(case when n.is_read=1 then 1 0 end ), 0)*100.0/nullif(COUNT(n.id),0), 0 from notifications n
GROUP by  n.customer_id
-- TASK 4 — loan_repayment_history VIEW
-- Создать VIEW:
-- * история платежей по кредитам
-- * сумма платежа
-- * дата платежа

-- PARAMETER
-- TABLE: loans, loan_payments

-- 1. loans jadvalini loan_payments jadvali bilan JOIN qilish
-- 2. Har bir kredit bo‘yicha to‘lov tarixini olish
-- 3. Har bir to‘lov uchun to‘langan summani chiqarish
-- 4. Har bir to‘lov sanasini chiqarish
-- 5. Loan_id bo‘yicha to‘lovlarni guruhlash
-- 6. Natijada quyidagi ustunlarni chiqarish:
--    loan_id
--    payment_amount
--    payment_date
-- 7. NULL qiymatlarni COALESCE orqali 0 ga aylantirish
-- 8. Natijani payment_date bo‘yicha tartiblash

create view loan_repayment_history as
select l.id, sum(lp.amount) paymet_amount, cast(lp.created_at as date) payment_date from loans l join loan_payments lp on lp.loan_id=l.id 
GROUP BY l.id, cast(lp.created_at as date)




-- TASK 5 — account_freeze_events VIEW
-- Создать VIEW:
-- * замороженные счета
-- * причина заморозки
-- * продолжительность заморозки

-- PARAMETER
-- TABLE: accounts, account_freeze

-- 1. accounts jadvalini account_freeze jadvali bilan JOIN qilish
-- 2. Muzlatilgan accountlarni aniqlash
-- 3. Account freeze sababini olish
-- 4. Freeze boshlangan sanani aniqlash
-- 5. Freeze davomiyligini hisoblash
-- 6. Duration qiymatini kunlarda hisoblash
-- 7. NULL qiymatlarni COALESCE orqali 0 ga aylantirish
-- 8. Natijada quyidagi ustunlarni chiqarish:
--    account_id
--    freeze_reason
--    freeze_date
--    freeze_duration
-- 9. Account_id bo‘yicha GROUP BY qilish
-- 10. Natijani freeze_date bo‘yicha tartiblash

select a.id, af.reason,a.status, af.frozen_at, DATEDIFF(day, af.frozen_at, GETdate()) from accounts a join account_freeze  af on af.account_id=a.id 
where a.[status]='frozen'

SELECT * from accounts

SELECT * from account_freeze

-- TASK 6 — failed_login_attempts VIEW
-- Создать VIEW:
-- * неудачные попытки входа
-- * IP адреса
-- * устройства


select lh.customer_id, lh.ip_address, lh.device, lh.created_at from login_history lh join customers c on lh.customer_id=c.id  JOIN accounts a on a.customer_id=c.id join fraud_alerts fa on a.id=fa.account_id
where fa.alert_type='multiple_failed_logins'


-- TASK 7 — high_balance_accounts VIEW
-- Создать VIEW:
-- * счета с высоким балансом (>10000)
-- * валюта счета
-- * статус

select id, [status],balance from accounts  where balance>10000



-- TASK 8 — recent_transactions VIEW
-- Создать VIEW:
-- * последние 100 транзакций
-- * тип транзакции
-- * сумма

select top 100 amount, [type], created_at from  transactions

order by created_at desc



-- TASK 9 — card_expiry_warnings VIEW
-- Создать VIEW:
-- * карты с истекающим сроком (30 дней)
-- * статус карты
-- * владелец счета

select c.id,a.id, cu.full_name,c.[status], c.expiry_date from cards c join accounts a  on c.account_id=a.id join customers cu on cu.id=a.customer_id
where c.expiry_date<=DATEADD(day, 30, GETDATE()) and c.expiry_date>=CAST(GETDATE() as date);




-- TASK 10 — beneficiary_statistics VIEW
-- Создать VIEW:
-- * количество получателей у клиента
-- * никнеймы получателей
-- * дата добавления

select customer_id,  count(beneficiary_account_id),nickname,  created_at  from beneficiaries 
group by customer_id, nickname, created_at





-- TASK 11 — daily_transaction_volume VIEW
-- Создать VIEW:
-- * ежедневный объем транзакций
-- * количество транзакций
-- * средняя сумма


SELECT cast(created_at as date ),sum(amount), count(id),  avg(amount) from transactions 
GROUP BY cast(created_at as date)


-- TASK 12 — customer_risk_distribution VIEW
-- Создать VIEW:
-- * распределение risk_score
-- * количество клиентов
-- * средний баланс

select c.risk_score, count(c.id) count_customer, avg(a.balance) avg_balance  from customers c join accounts a on a.customer_id=c.id 
GROUP by c.risk_score



-- TASK 13 — currency_usage VIEW
-- Создать VIEW:
-- * популярность валют
-- * количество счетов
-- * общий баланс

select a.currency , count(a.id)count_account, sum(a.balance)  total_balance  from accounts a  
group by a.currency


-- TASK 14 — loan_status_distribution VIEW
-- Создать VIEW:
-- * активные кредиты
-- * закрытые кредиты
-- * общая сумма

select status, sum(amount) total_amount from loans 
group by [status]


-- TASK 15 — account_creation_by_month VIEW
-- Создать VIEW:
-- * счета по месяцам
-- * количество
-- * статус


select count(id), [status], format(created_at, 'yyyy-MM') from  accounts 
GROUP by [status],format(created_at, 'yyyy-MM') 



-- TASK 16 — transaction_type_distribution VIEW
-- Создать VIEW:
-- * типы транзакций
-- * количество
-- * общая сумма

SELECT sum(amount) total_tx, count(*) count_tx,type  from transactions
group by [type]



-- TASK 17 — customer_registration_trends VIEW
-- Создать VIEW:
-- * регистрация клиентов по дням
-- * количество
-- * risk_score

select risk_score, count(*) count_customers, FORMAT(created_at, 'yyyy-mm-dd')  from customers
GROUP by risk_score,  FORMAT(created_at, 'yyyy-mm-dd') 


-- TASK 18 — fraud_alert_severity VIEW
-- Создать VIEW:
-- * уровень серьезности
-- * количество алертов
-- * типы алертов


SELECT severity, count(*) count_alerts, alert_type  from fraud_alerts
group by severity, alert_type



-- TASK 19 — account_status_summary VIEW
-- Создать VIEW:
-- * статус счетов
-- * количество
-- * общий баланс


select [status], count(*) count_account, sum(balance) total_balance  from accounts 
group by [status]


-- TASK 20 — top_customers_by_balance VIEW
-- Создать VIEW:
-- * топ 10 клиентов по балансу
-- * общий баланс
-- * количество счетов


select top 10 customer_id, sum(balance) total_balance, count(*) from accounts 
group by customer_id
order by total_balance desc 

-- TASK 21 — recent_fraud_alerts VIEW
-- Создать VIEW:
-- * последние 50 fraud алертов
-- * тип алерта
-- * серьезность

select top 50 created_at, alert_type,severity  from fraud_alerts
order by id desc


-- TASK 22 — transaction_failure_rate VIEW
-- Создать VIEW:
-- * процент failed транзакций
-- * по дням
-- * общее количество


select count(*) total_count_tx, COUNT(case when [status]='failed' then 1 end)*100.0/count(*) precent_tx, format(created_at, 'yyyy-MM-dd') from transactions
GROUP by format(created_at, 'yyyy-MM-dd')


-- TASK 23 — customer_activity_status VIEW
-- Создать VIEW:
-- * активные/неактивные клиенты
-- * последняя активность
-- * количество транзакций


select c.id, c.full_name,count(t.id )  count_tx, case when count(t.id)>0 then 'active' 'inactive' end status_customer, max(t.created_at) last_tx
from customers c left join accounts a on a.customer_id=c.id 
left JOIN transactions t on t.to_account_id=a.id or t.from_account_id=a.id 
group by c.id, c.full_name

-- TASK 24 — loan_payment_schedule VIEW
-- Создать VIEW:
-- * график платежей по кредитам
-- * сумма платежа
-- * дата

select loan_id,  sum(amount) total_amount, format(created_at, 'yyyy-MM-dd') from loan_payments
GROUP by loan_id,  format(created_at, 'yyyy-MM-dd')


-- TASK 25 — account_balance_changes VIEW
-- Создать VIEW:
-- * изменения баланса
-- * тип изменения
-- * дата

select le.account_id, le.entry_type, le.amount, format(created_at, 'yyyy-MM')  from ledger_entries le

-- ============================================================
-- FUNCTION (26-50)
-- ============================================================

-- TASK 26 — calculate_account_age FUNCTION
-- Создать FUNCTION:
-- * расчет возраста счета в днях
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @created_at DATETIME2
-- @age_days INT
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account yaratilgan sanani olish
--    created_at ustunidan
-- 3. Account mavjud bo‘lmasa
--    NULL qaytarish
-- 4. Account yoshini hisoblash
--    DATEDIFF(day, created_at, GETDATE())
-- RETURN:
-- INT


create function calculate_account_age(@account_id int) 
returns int 
as begin 
declare @age_days int;

select @age_days=DATEDIFF(day, created_at, GETDATE()) from accounts where id =@account_id;

RETURN @age_days;
end;

-- TASK 27 — get_customer_loan_count FUNCTION
-- Создать FUNCTION:
-- * количество кредитов у клиента

-- PARAMETER
-- @customer_id INT

-- DECLARE
-- @loan_count INT

-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan

-- 2. Customer kreditlarini hisoblash
--    loans jadvalidan

-- 3. Customer mavjud bo‘lmasa
--    0 qaytarish

-- 4. Kreditlar sonini COUNT(id) orqali olish

-- RETURN:
-- INT

create function get_customer_loan_count(@customer_id int)
returns int 
as begin 
declare @loan_count int;

if not exists(select 1 from customers  where  id =@customer_id) 
return 0;

select @loan_count= count(*) from loans where customer_id =@customer_id;

return @loan_count;
end;





-- TASK 28 — calculate_total_fraud_alerts FUNCTION
-- Создать FUNCTION:
-- * общее количество fraud алертов по счету
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @alert_count INT
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account bo‘yicha fraud alertlarni hisoblash
--    fraud_alerts jadvalidan
-- 3. Account mavjud bo‘lmasa
--    0 qaytarish
-- 4. Fraud alert sonini COUNT(id) orqali olish
-- RETURN:
-- INT
create function calculate_total_fraud_alerts (@account_id int) 
returns int
as begin 
declare @alert_count int;

if not exists (select 1 from accounts where id=@account_id) 
return 0 ;

select @alert_count=count(id) from fraud_alerts where account_id=@account_id;
return @alert_count;
end;










-- TASK 29 — get_account_transaction_count FUNCTION
-- Создать FUNCTION:
-- * количество транзакций по счету
create function get_account_transaction_count (@account_id int) 
returns int 
as begin 
declare @tx_count int;

if not exists (select 1 from accounts where id =@account_id)
return 0;

select @tx_count=count(t.id) from transactions t join accounts a on t.from_account_id=a.id or t.to_account_id=a.id where a.id =@account_id;

return @tx_count;
end;





-- TASK 30 — calculate_balance_change_rate FUNCTION
-- Создать FUNCTION:
-- * скорость изменения баланс
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @total_change DECIMAL(12,2)
-- @days_count INT
-- @change_rate DECIMAL(12,2)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account balans o‘zgarishlarini olish
--    ledger_entries jadvalidan
-- 3. Umumiy balans o‘zgarishini hisoblash
--    credit va debit farqi orqali
-- 4. O‘zgarish davridagi kunlar sonini hisoblash
-- 5. Agar account mavjud bo‘lmasa
--    0 qaytarish
-- 6. Balans o‘zgarish tezligini hisoblash
--    umumiy o‘zgarish / kunlar soni
-- RETURN:
-- DECIMAL(12,2)


create function calculate_balance_change_rate (@account_id int)
returns decimal(12,2)
as begin 
declare @total_cange decimal(12,2);
declare @days_count int;
declare @change_rate decimal(12,2);

if not exists (select 1 from accounts where id=@account_id) 
return 0;

select @total_cange=sum(amount) from ledger_entries where account_id=@account_id;

select @days_count=DATEDIFF(day, min(created_at),max(created_at)) from ledger_entries where account_id=@account_id;

if @days_count is null or @days_count=0
return 0;

set @change_rate =@total_cange/@days_count;

return @change_rate;
end;








-- TASK 31 — get_customer_notification_count FUNCTION
-- Создать FUNCTION:
-- * количество уведомлений у клиента
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @notification_count INT
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Customer notificationlarini hisoblash
--    notifications jadvalidan
-- 3. Customer mavjud bo‘lmasa
--    0 qaytarish
-- 4. Notification sonini COUNT(id) orqali olish
-- RETURN:
-- INT


create function get_customer_notification_count (@customer_id int) 
returns int
as begin 
declare @notifation_count int;

if not exists (select 1 from customers where id =@customer_id)
return 0;

select @notifation_count=count(id) from notifications where customer_id=@customer_id;

if @notifation_count is null or @notifation_count=0
return 0;

return @notifation_count;
end;






-- TASK 32 — calculate_auth_fail_rate FUNCTION
-- Создать FUNCTION:
-- * процент неудачных входов
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @total_login INT
-- @failed_login INT
-- @fail_rate DECIMAL(12,2)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Login urinishlarini hisoblash
--    login_history jadvalidan
-- 3. Umumiy login sonini olish
-- 4. Failed login sonini olish
-- 5. Agar customer mavjud bo‘lmasa
--    0 qaytarish
-- 6. Agar login mavjud bo‘lmasa
--    0 qaytarish
-- 7. Failed foizini hisoblash
--    (failed login / total login) * 100
-- RETURN:
-- DECIMAL(12,2)


create function calculate_auth_fail_rate(@customer_id int)
returns decimal(12,2) 
as begin 
declare @total_login int;
declare @failed_login int; 
declare @fail_rate decimal(12,2);

if not exists (select 1 from customers where id =@customer_id)
return 0;

select @total_login=count(id) from login_history where customer_id=@customer_id;

select @failed_login=count(fa.id) from fraud_alerts fa join accounts a on a.id=fa.account_id where a.customer_id=@customer_id and fa.alert_type='multiple_failed_logins';

if @failed_login is null or @failed_login=0
return 0;

set @fail_rate=(@failed_login * 1.0 /@total_login)*100.0;

return coalesce(@fail_rate,0);
end;


-- TASK 33 — get_loan_payment_count FUNCTION
-- Создать FUNCTION:
-- * количество платежей по кредиту
-- PARAMETER
-- @loan_id INT
-- DECLARE
-- @payment_count INT
-- 1. Loan mavjudligini tekshirish
--    loans jadvalidan
-- 2. Kredit bo‘yicha to‘lovlarni hisoblash
--    loan_payments jadvalidan
-- 3. Loan mavjud bo‘lmasa
--    0 qaytarish
-- 4. Payment sonini COUNT(id) orqali olish
-- RETURN:
-- INT

create function get_loan_payment_count(@loan_id int) 
returns int
as begin 
declare @payment_count int;

if not exists (select 1 from loans where id=@loan_id)
return 0;

select @payment_count=count(id) from loan_payments where loan_id=@loan_id;

if @payment_count is null or @payment_count=0
return 0;

return @payment_count;
end;




-- TASK 34 — calculate_card_expiry_days FUNCTION
-- Создать FUNCTION:
-- * дней до истечения карты
-- PARAMETER
-- @card_id INT
-- DECLARE
-- @expiry_days INT
-- 1. Card mavjudligini tekshirish
--    cards jadvalidan
-- 2. Card expiry_date olish
-- 3. Bugungi sana bilan expiry_date orasidagi kunlarni hisoblash
-- 4. Card mavjud bo‘lmasa
--    0 qaytarish
-- 5. Agar karta muddati o‘tgan bo‘lsa
--    0 qaytarish
-- RETURN:
-- INT
create function calculate_card_expiry_days(@card_id int) 
returns int 
as begin 
declare @expiry_days int;

if not exists(select 1 from cards where id =@card_id)
return 0;


select @expiry_days=datediff(day, GETDATE(), expiry_date) from cards where id=@card_id

if @expiry_days is null or @expiry_days=0
return 0;

return @expiry_days;
end;




-- TASK 35 — get_beneficiary_count FUNCTION
-- Создать FUNCTION:
-- * количество получателей у клиента
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @beneficiary_count INT
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Customer beneficiarylarini hisoblash
--    beneficiaries jadvalidan
-- 3. Customer mavjud bo‘lmasa
--    0 qaytarish
-- 4. Beneficiary sonini COUNT(id) orqali olish
-- RETURN:
-- INT
create function get_beneficiary_count(@customer_id int) 
returns int 
as begin 
declare @BENEFICIARY_count int;

if not exists (select 1 from customers where id=@customer_id)
return 0;

select @BENEFICIARY_count=count(id) from beneficiaries where customer_id=@customer_id;
return @BENEFICIARY_count;
end;



-- TASK 36 — calculate_daily_avg_balance FUNCTION
-- Создать FUNCTION:
-- * средний дневной баланс
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @avg_balance DECIMAL(12,2)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account balanslarini olish
--    ledger_entries yoki accounts jadvalidan
-- 3. Kunlik o‘rtacha balansni hisoblash
--    AVG(balance)
-- 4. Account mavjud bo‘lmasa
--    0 qaytarish
-- 5. Natijani qaytarish
-- RETURN:
-- DECIMAL(12,2)

create function calculate_daily_avg_balance(@account_id int) 
returns decimal(12,2)
as begin 
declare @avg_balance decimal(12,2);

if not exists (select 1 from accounts where id=@account_id)
return 0;

select @avg_balance=avg(daily_balance) from (select cast(created_at as date) tx_date, sum(amount) daily_balance from ledger_entries where account_id=@account_id group by cast(created_at as date))x; 

if @avg_balance is null 
return 0;

return @avg_balance;
end;

select dbo.calculate_daily_avg_balance (6)

-- TASK 37 — get_freeze_duration FUNCTION
-- Создать FUNCTION:
-- * продолжительность заморозки
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @freeze_duration INT
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Account freeze boshlangan sanani olish
-- 3. Freeze boshlangan sanadan bugungi kungacha bo‘lgan kunlarni hisoblash
-- 4. Account mavjud bo‘lmasa
--    0 qaytarish
-- 5. Agar freeze holati bo‘lmasa
--    0 qaytarish
-- RETURN:
-- INT
create function get_freeze_duration(@account_id int) 
returns int
as begin 
declare @freeze_duration int;

if not exists (select 1 from accounts where id=@account_id) 
return 0;

select @freeze_duration=datediff(day, frozen_at,getdate()) from account_freeze where account_id=@account_id;

if @freeze_duration is null 
return 0;

return @freeze_duration;
end;

select dbo.get_freeze_duration ()


-- TASK 38 — calculate_transaction_success_rate FUNCTION
-- Создать FUNCTION:
-- * процент успешных транзакций
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @total_tx INT
-- @success_tx INT
-- @success_rate DECIMAL(12,2)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Umumiy tranzaksiyalar sonini hisoblash
--    transactions jadvalidan
-- 3. Successful tranzaksiyalar sonini hisoblash
--    status='completed'
-- 4. Account mavjud bo‘lmasa
--    0 qaytarish
-- 5. Transaction mavjud bo‘lmasa
--    0 qaytarish
-- 6. Foiz hisoblash
--    (success_tx / total_tx) * 100
-- RETURN:
-- DECIMAL(12,2)

create function calculate_transaction_success_rate(@account_id int) 
returns decimal(12,2)
as begin 
declare @total_tx int;
declare @success_tx int;
declare @success_rate decimal(12,2);

if not exists (select 1 from accounts where id=@account_id)
return 0;

select @total_tx=count(id) from transactions where from_account_id=@account_id or to_account_id=@account_id;

select @success_tx=count(id) from transactions where status='success' and (from_account_id=@account_id or to_account_id=@account_id);
if @total_tx =0 
return 0;
set @success_rate=coalesce(@success_tx * 1.0/nullif(@total_tx, 0)*100, 0);
return @success_rate;
end;





-- TASK 39 — get_customer_accounts_count FUNCTION
-- Создать FUNCTION:
-- * количество счетов у клиента
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @account_count INT
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Customer accountlarini hisoblash
--    accounts jadvalidan
-- 3. Customer mavjud bo‘lmasa
--    0 qaytarish
-- RETURN:
-- INT
create function get_customer_accounts_count(@customer_id int) 
returns int
as begin 
declare @account_count int;

if not exists (select 1 from customers where id = @customer_id)
return 0;

select @account_count=count(id) from accounts where customer_id=@customer_id;

return @account_count;
end;











-- TASK 40 — calculate_risk_trend FUNCTION
-- Создать FUNCTION:
-- * тренд изменения risk_score
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @old_risk INT
-- @current_risk INT
-- @risk_trend NVARCHAR(20)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Hozirgi risk_score olish
--    customers jadvalidan
-- 3. Oldingi risk_score olish
--    risk_history jadvalidan
-- 4. Agar eski risk yuqori bo‘lsa
--    'DECREASING' qaytarish
-- 5. Agar yangi risk yuqori bo‘lsa
--    'INCREASING' qaytarish
-- 6. Risk o‘zgarmasa
--    'STABLE' qaytarish
-- 7. Customer mavjud bo‘lmasa
--    'NOT_FOUND' qaytarish
-- RETURN:
-- NVARCHAR(20)
create function calculate_risk_trend (@customer_id int) 
returns int

as begin 
declare @current_risk int;
declare @risk_trend int;
declare @old_risk int;

if not exists (select 1 from customers where id=@customer_id)
return 0;

select @current_risk= risk_score from customers where id=@customer_id;

select @old_risk= risk_score from (select risk_score, row_number() over(order by created_at desc ) rn from customers where id=@customer_id)x where rn=2



select * from customers 

-- TASK 41 — get_currency_balance FUNCTION
-- Создать FUNCTION:
-- * баланс по валюте
-- PARAMETER
-- @customer_id INT
-- @currency NVARCHAR(10)
-- DECLARE
-- @balance DECIMAL(12,2)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Berilgan valuta bo‘yicha account balanslarini olish
--    accounts jadvalidan
-- 3. Account mavjud bo‘lmasa
--    0 qaytarish
-- 4. Valuta bo‘yicha jami balansni hisoblash
--    SUM(balance)
-- RETURN:
-- DECIMAL(12,2)
create function get_currency_balance
(@customer_id int, @currency nvarchar(20)) 
returns decimal(12,2)
as begin 
declare @balance decimal(12,2);

if not exists (select 1 from customers where id=@customer_id) 
return 0;

select @balance=sum(balance) from accounts where customer_id =@customer_id and currency=@currency

if @balance is null 
return 0;

return @balance;
end;




-- TASK 42 — calculate_loan_utilization FUNCTION
-- Создать FUNCTION:
-- * использование кредитной суммы
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @loan_amount DECIMAL(12,2)
-- @total_loan DECIMAL(12,2)
-- @utilization DECIMAL(12,2)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Customer umumiy kredit summasini olish
--    loans jadvalidan SUM(amount) orqali
-- 3. Faol kredit summasini olish
--    loans jadvalidan status='active' orqali
-- 4. Formula:
--    (active_loan_amount / total_loan_amount) * 100
-- 5. Umumiy kredit summasi 0 bo‘lsa
--    0 qaytarish
-- RETURN:
-- DECIMAL(12,2)


create function calculate_loan_utilization(@customer_id int)
returns decimal(12,2) 
as begin 
declare @loan_amount decimal(12,2);
declare @total_loan decimal(12,2);
declare @utilization decimal(12,2);

if not exists (select 1 from customers where id=@customer_id)
return 0 ;

select @total_loan=sum(amount) from loans where customer_id= @customer_id;

select @loan_amount=sum(amount) from loans where customer_id =@customer_id and status='active';
if @total_loan is null or @total_loan=0
return 0;


set @utilization=coalesce(@loan_amount *1.0/nullif(@total_loan, 0)*100,0) ;

return @utilization;
end;



-- TASK 43 — get_fraud_severity_level FUNCTION
-- Создать FUNCTION:
-- * уровень серьезности fraud
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @fraud_count INT
-- @severity NVARCHAR(20)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Customer fraud alert sonini hisoblash
--    fraud_alerts va accounts jadvallaridan
-- 3. Fraud alert soniga qarab severity belgilash:
--    0 ta alert  -> LOW
--    1-5 ta alert -> MEDIUM
--    5 dan ko‘p -> HIGH
-- RETURN:
-- NVARCHAR(20)
create function get_fraud_severity_level(@customer_id int) 
returns nvarchar(20)
as begin 
declare @fraud_count int;
declare @severty nvarchar(20);

if not exists (select 1 from customers where id=@customer_id)
return 'not found';

select @fraud_count=count (fa.id) from fraud_alerts fa join accounts a on fa.account_id=a.id where a.customer_id=@customer_id;

if @fraud_count =0 
set @severty ='low';

if @fraud_count between 1 and 5 
set @severty ='medium';


set @severty='high';

return @severty;
end;



-- TASK 44 — calculate_account_health_index FUNCTION
-- Создать FUNCTION:
-- * индекс здоровья счета
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @balance DECIMAL(12,2)
-- @status NVARCHAR(20)
-- @fail_count INT
-- @transaction_count INT
-- @fraud_count INT
-- @health_index INT
declare @status nvarchar(20);
declare @fail_count int;
declare @tx_count int;
declare	@fraud_count int ;
declare @balance decimal(12,2);

-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Agar account mavjud bo‘lmasa
--    0 qaytarish
-- 3. Account ma'lumotlarini olish:
--    - balance
--    - status
--    - fail_count
-- 4. Account transaction faoliyatini hisoblash
--    transactions jadvalidan:
--    - from_account_id
--    - to_account_id
-- 5. Account fraud alert sonini hisoblash
--    fraud_alerts jadvalidan
-- 6. Boshlang‘ich health index:
--    100
-- 7. Agar status = 'blocked' yoki status = 'closed'
--    -40 ball
-- 8. Agar status = 'frozen' yoki status = 'dormant'
--    -20 ball
-- 9. Agar balance = 0
--    -10 ball
-- 10. Har bir fail_count uchun
--     -5 ball
-- 11. Agar fraud_count:
--     1-3 ta alert -> -20 ball
--     4-5 ta alert -> -40 ball
--     5 dan ko‘p -> -60 ball
-- 12. Agar transaction_count > 0
--     +10 ball
-- 13. Health index:
--     0 dan kichik bo‘lsa 0 qilish
-- 14. Health index:
--     100 dan katta bo‘lsa 100 qilish
-- RETURN:
-- INT

create function calculate_account_health_index (@account_id int) 
returns int
as begin 
declare @health_index int;
declare @status nvarchar(20);
declare @fail_count int;
declare @tx_count int;
declare	@fraud_count int ;
declare @balance decimal(12,2);

if not exists (select 1 from accounts where id=@account_id) 
return 0;


select @status= status, @balance=balance,@fail_count=fail_count  from accounts where id =@account_id;

select @tx_count=count(id) from transactions where from_account_id=@account_id or to_account_id=@account_id
select @fraud_count=count(id) from fraud_alerts where account_id=@account_id;

set @health_index=100;

if @status in ('blocked', 'closed')
set @health_index=@health_index-40;

if @status in('frozen', 'dormant')
set @health_index=@health_index-20;

if @balance=0
set @health_index=@health_index-10;

set @health_index=@health_index-(@fail_count*5)

if @fraud_count between 1 and 3
set @health_index=@health_index-20;

if @fraud_count between 4 and 5
set @health_index=@health_index-40;

if @fraud_count >5 
set @health_index=@health_index-60;

if @tx_count>0
set @health_index=@health_index+10;


if @health_index<0


set @health_index=0;

if @health_index >100
set @health_index=100;

return @health_index;
end;



-- TASK 45 — get_device_usage_count FUNCTION
-- Создать FUNCTION:
-- * количество использований устройства
-- PARAMETER
-- @customer_id INT
-- @device NVARCHAR(MAX)
-- DECLARE
-- @usage_count INT
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Agar customer mavjud bo‘lmasa
--    0 qaytarish
-- 3. Customer qurilmasidan foydalanish sonini hisoblash
--    login_history jadvalidan:
--    - customer_id
--    - device
-- 4. Device qiymati bo‘yicha filter qilish
-- 5. Agar device topilmasa
--    0 qaytarish
-- RETURN:
-- INT
create function get_device_usage_count(@customer_id int, @device nvarchar(max)) 
returns int
as begin 
declare @usage_count int;

if not exists (select 1 from customers where id=@customer_id)
return 0;

select @usage_count= count(id)  from login_history where customer_id =@customer_id and device=@device;

if @usage_count is null 
return 0;

return @usage_count;
end;







-- TASK 46 — calculate_login_frequency FUNCTION
-- Создать FUNCTION:
-- * частота входов в систему
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @login_count INT
-- @frequency NVARCHAR(20)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Agar customer mavjud bo‘lmasa
--    0 qaytarish
-- 3. Customer login sonini hisoblash
--    login_history jadvalidan:
--    - customer_id
-- 4. Login soniga qarab frequency aniqlash:
--    0 ta login -> LOW
--    1-10 ta login -> MEDIUM
--    10 dan ko‘p login -> HIGH
-- 5. Natijani qaytarish
-- RETURN:
-- NVARCHAR(20)
create function calculate_login_frequency(@customer_id int)
returns nvarchar(20) 
as begin 
declare @login_count int;
declare @frequency nvarchar(20);

if not exists (select 1 from customers where id =@customer_id)
return 'not found customer';

select @login_count=count(id) from login_history where customer_id =@customer_id;

if @login_count =0
set @frequency='low';
else if @login_count between 1 and 10
set @frequency ='medium';
else if @login_count>10
set @frequency='high';

return @frequency;
end;





-- TASK 47 — get_customer_risk_level FUNCTION
-- Создать FUNCTION:
-- * уровень риска (LOW/MEDIUM/HIGH)
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @risk_score INT
-- @risk_level NVARCHAR(20)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Agar customer mavjud bo‘lmasa
--    'NOT_FOUND' qaytarish
-- 3. Customer risk score olish
--    customers jadvalidan:
--    - risk_score
-- 4. Risk score qiymatiga qarab risk level aniqlash:
--    0-30 ball  -> LOW
--    31-70 ball -> MEDIUM
--    71-100 ball -> HIGH
-- 5. Natijani qaytarish
-- RETURN:
-- NVARCHAR(20)

create function get_customer_risk_level (@customer_id int) 
returns nvarchar(20) 
as begin 
declare @risk_score int;
declare @risk_level nvarchar(20);

if not exists (select 1 from customers where id=@customer_id) 
return 'not found customer';

select @risk_score=risk_score from customers where id =@customer_id;

if @risk_score between 0 and 30
set @risk_level ='low';
else if @risk_score between 31 and 70 
set @risk_level ='medium' ;
else if @risk_score between 71 and 100
set @risk_level='high';

return @risk_level;
end;

select * from customers 







-- TASK 48 — calculate_balance_growth_rate FUNCTION
-- Создать FUNCTION:
-- * темп роста баланса
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @current_balance DECIMAL(12,2)
-- @previous_balance DECIMAL(12,2)
-- @growth_rate DECIMAL(12,2)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Agar account mavjud bo‘lmasa
--    0 qaytarish
-- 3. Hozirgi balance olish
--    accounts jadvalidan:
--    - balance
-- 4. Oldingi balance ni aniqlash
--    transactions jadvalidan:
--    - account transactionlari asosida
-- 5. Growth rate hisoblash:
--    ((current_balance - previous_balance) / previous_balance) * 100
-- 6. Agar previous_balance = 0 bo‘lsa
--    0 qaytarish
-- RETURN:
-- DECIMAL(12,2)


create function  calculate_balance_growth_rate(@account_id int)
returns decimal(12,2)
as begin 
declare @current_balance decimal(12,2);
declare @previos_balance decimal(12,2);
declare @growth_rate decimal(12,2);

if not exists (select 1 from accounts where id =@account_id)
return 0;

select @current_balance=balance from accounts where id=@account_id;
select @previos_balance=@current_balance-coalesce(sum(case when from_account_id=@account_id then -amount when to_account_id=@account_id then amount else 0 end),0) from transactions where from_account_id=@account_id or to_account_id=@account_id;

set @growth_rate=coalesce((@current_balance-@previos_balance)*1.0/nullif(@previos_balance,0)*100,0);
return @growth_rate;
end;




-- TASK 49 — get_notification_read_rate FUNCTION
-- Создать FUNCTION:
-- * процент прочитанных уведомлений
-- PARAMETER
-- @customer_id INT
-- DECLARE
-- @total_notifications INT
-- @read_notifications INT
-- @read_rate DECIMAL(12,2)
-- 1. Customer mavjudligini tekshirish
--    customers jadvalidan
-- 2. Agar customer mavjud bo‘lmasa
--    0 qaytarish
-- 3. Customer notification sonini hisoblash
--    notifications jadvalidan:
--    - customer_id
-- 4. O‘qilgan notification sonini hisoblash
--    notifications jadvalidan:
--    - customer_id
--    - is_read = 1
-- 5. Agar notification mavjud bo‘lmasa
--    0 qaytarish
-- 6. Read rate hisoblash:
--    (read_notifications / total_notifications) * 100
-- 7. Natijani qaytarish
-- RETURN:
-- DECIMAL(12,2)

create function get_notification_read_rate(@customer_id int)
returns decimal(12,2)
as begin 
declare @total_notification int;
declare @read_notification int;
declare @read_rate decimal(12,2);

if not exists (select 1 from customers where id=@customer_id)
return 0;

select @total_notification=count(id) from notifications where customer_id =@customer_id;

select @read_notification=count(id) from notifications where customer_id =@customer_id and is_read=1;

if @read_notification is null 
return 0;

set @read_rate=coalesce(@read_notification*1.0/nullif(@total_notification, 0) *100, 0);
return @read_rate;
end;






-- TASK 50 — calculate_account_score FUNCTION
-- Создать FUNCTION:
-- * общий счет аккаунта
-- PARAMETER
-- @account_id INT
-- DECLARE
-- @account_score INT
-- @balance DECIMAL(12,2)
-- @transaction_count INT
-- @fraud_count INT
-- @status NVARCHAR(20)

-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Agar account mavjud bo‘lmasa
--    0 qaytarish
-- 3. Account ma'lumotlarini olish:
--    accounts jadvalidan:
--    - balance
--    - status
-- 4. Account transaction sonini hisoblash
--    transactions jadvalidan:
--    - from_account_id
--    - to_account_id
-- 5. Fraud alert sonini hisoblash
--    fraud_alerts jadvalidan:
--    - account_id
-- 6. Account score boshlang‘ich qiymatini berish
--    100
-- 7. Balance bo‘yicha score o‘zgartirish:
--    balance = 0  -> -20
--    balance > 0  -> +10
-- 8. Status bo‘yicha score o‘zgartirish:
--    blocked/closed -> -40
--    frozen/dormant -> -20
-- 9. Transaction soniga qarab:
--    transaction > 10 -> +10
-- 10. Fraud alert soniga qarab:
--    1-3 ta -> -20
--    4-5 ta -> -40
--    5 dan ko‘p -> -60
-- 11. Score 0 dan past bo‘lsa
--    0 qilish
-- 12. Score 100 dan katta bo‘lsa
--    100 qilish
-- RETURN:
-- INT


create function calculate_account_score(@account_id int)
returns int
as begin 
declare @account_score int;
declare @balance decimal(12,2);
declare @tx_count int ;
declare @fraud_count int;
declare @status nvarchar(20);

if not exists (select 1 from accounts where id=@account_id) 
return 0;

select @balance=balance, @status=status from accounts where id =@account_id;
select @tx_count=count(id) from transactions where from_account_id=@account_id or to_account_id=@account_id;
select @fraud_count=count(id) from fraud_alerts where account_id=@account_id;

set @account_score=100;

if @balance=0
set @account_score=@account_score-20;
else if @balance>0
set @account_score=@account_score+10;

if @status in('blocked', 'closed')
set @account_score=@account_score-40
else if @status in ('frozen', 'dormant')
set @account_score=@account_score-20;

if @tx_count>10
set @account_score=@account_score+10;

if @fraud_count between 1 and 3
set @account_score=@account_score-20;
else if @fraud_count between 4 and 5 
set @account_score=@account_score-40;
else if @fraud_count >5
set @account_score=@account_score-60;


if @account_score<0
set @account_score=0
else if @account_score>100
set @account_score=100;

return @account_score;
end;





-- ============================================================
-- PROCEDURE (51-75)
-- ============================================================

-- TASK 51 — update_account_status PROCEDURE
-- Создать PROCEDURE:
-- * обновление статуса счета
-- PARAMETER
-- @account_id INT
-- @new_status NVARCHAR(20)
-- DECLARE
-- @current_status NVARCHAR(20)
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Agar account mavjud bo‘lmasa
--    THROW qaytarish
-- 3. Yangi status validligini tekshirish:
--    active
--    frozen
--    closed
--    blocked
--    dormant
--    pending
-- 4. Hozirgi statusni olish
--    accounts jadvalidan
-- 5. Agar yangi status hozirgi status bilan bir xil bo‘lsa
--    THROW qaytarish
-- 6. Transaction boshlash
-- 7. Account statusini yangilash
--    accounts jadvalida
-- 8. update_at maydonini yangilash
--    GETDATE()
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish

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





-- TASK 52 — add_fraud_alert PROCEDURE
-- Создать PROCEDURE:
-- * добавление fraud алерта
-- PARAMETER
-- @account_id INT
-- @alert_type NVARCHAR(50)
-- @severity INT
-- DECLARE
-- @customer_id INT
-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan
-- 2. Agar account mavjud bo‘lmasa
--    THROW qaytarish
-- 3. Account egasining customer_id sini olish
--    accounts jadvalidan
-- 4. Alert type validligini tekshirish
--    fraud_alerts jadvalidagi mavjud type lar:
--    suspicious_amount
--    rapid_transactions
--    multiple_failed_logins
--    usual_location
--    new_device_login
--    vilocity_check
--    blacklist_ip
--    card_not_present
--    hogh_risk_country
--    account_takeover
-- 5. Severity qiymatini tekshirish
--    1-10 oralig‘ida bo‘lishi kerak
-- 6. Transaction boshlash
-- 7. fraud_alerts jadvaliga yangi alert qo‘shish:
--    account_id
--    alert_type
--    severity
-- 8. Commit qilish
-- 9. Xatolik bo‘lsa rollback qilish
-- 10. THROW qaytarish

create procedure add_fraud_alert
@account_id int,
@alert_type nvarchar(50),
@severty int
as begin 
declare @customer_id int;
begin try begin tran;

if not exists(select 1 from accounts where id =@account_id) 



-- TASK 53 — log_failed_transaction PROCEDURE
-- Создать PROCEDURE:
-- * запись failed транзакции

-- TASK 54 — update_customer_risk PROCEDURE
-- Создать PROCEDURE:
-- * обновление risk_score клиента

-- TASK 55 — send_notification PROCEDURE
-- Создать PROCEDURE:
-- * отправка уведомления клиенту

-- TASK 56 — close_expired_cards PROCEDURE
-- Создать PROCEDURE:
-- * закрытие просроченных карт

-- TASK 57 — archive_old_transactions PROCEDURE
-- Создать PROCEDURE:
-- * архивация старых транзакций

-- TASK 58 — generate_monthly_statement PROCEDURE
-- Создать PROCEDURE:
-- * генерация месячной выписки

-- TASK 59 — update_loan_status PROCEDURE
-- Создать PROCEDURE:
-- * обновление статуса кредита

-- TASK 60 — record_login_history PROCEDURE
-- Создать PROCEDURE:
-- * запись истории входов

-- TASK 61 — apply_interest_to_loans PROCEDURE
-- Создать PROCEDURE:
-- * начисление процентов на кредиты

-- TASK 62 — calculate_daily_interest PROCEDURE
-- Создать PROCEDURE:
-- * расчет дневных процентов

-- TASK 63 — generate_audit_report PROCEDURE
-- Создать PROCEDURE:
-- * генерация аудит отчета

-- TASK 64 — update_balance PROCEDURE
-- Создать PROCEDURE:
-- * обновление баланса счета

-- TASK 65 — process_loan_payment PROCEDURE
-- Создать PROCEDURE:
-- * обработка платежа по кредиту

-- TASK 66 — create_account PROCEDURE
-- Создать PROCEDURE:
-- * создание нового счета

-- TASK 67 — close_dormant_accounts PROCEDURE
-- Создать PROCEDURE:
-- * закрытие неактивных счетов

-- TASK 68 — reset_failed_count PROCEDURE
-- Создать PROCEDURE:
-- * сброс счетчика ошибок

-- TASK 69 — migrate_customer_data PROCEDURE
-- Создать PROCEDURE:
-- * миграция данных клиента

-- TASK 70 — generate_risk_report PROCEDURE
-- Создать PROCEDURE:
-- * генерация отчета по рискам

-- TASK 71 — cleanup_audit_logs PROCEDURE
-- Создать PROCEDURE:
-- * очистка старых аудит логов

-- TASK 72 — import_customers PROCEDURE
-- Создать PROCEDURE:
-- * импорт клиентов из файла

-- TASK 73 — export_transactions PROCEDURE
-- Создать PROCEDURE:
-- * экспорт транзакций в файл

-- TASK 74 — update_currency_rate PROCEDURE
-- Создать PROCEDURE:
-- * обновление курса валют

-- TASK 75 — reconcile_accounts PROCEDURE
-- Создать PROCEDURE:
-- * сверка счетов


-- ============================================================
-- TRIGGER (76-100)
-- ============================================================

-- TASK 76 — prevent_negative_balance_trigger
-- Создать TRIGGER:
-- * запрет отрицательного баланса

-- TASK 77 — log_account_status_changes_trigger
-- Создать TRIGGER:
-- * лог изменения статуса счета

-- TASK 78 — update_risk_score_on_failed_login_trigger
-- Создать TRIGGER:
-- * обновление risk_score при failed login

-- TASK 79 — auto_freeze_on_fraud_alert_trigger
-- Создать TRIGGER:
-- * автоматическая заморозка при fraud

-- TASK 80 — validate_card_expiry_trigger
-- Создать TRIGGER:
-- * валидация срока действия карты

-- TASK 81 — update_account_update_at_trigger
-- Создать TRIGGER:
-- * обновление update_at при изменении

-- TASK 82 — prevent_duplicate_beneficiaries_trigger
-- Создать TRIGGER:
-- * запрет дубликатов получателей

-- TASK 83 — auto_create_audit_log_trigger
-- Создать TRIGGER:
-- * автоматическое создание аудит лога

-- TASK 84 — check_loan_limit_trigger
-- Создать TRIGGER:
-- * проверка лимита кредита

-- TASK 85 — update_notification_status_trigger
-- Создать TRIGGER:
-- * обновление статуса уведомления

-- TASK 86 — validate_transaction_amount_trigger
-- Создать TRIGGER:
-- * валидация суммы транзакции

-- TASK 87 — auto_update_risk_score_trigger
-- Создать TRIGGER:
-- * автоматическое обновление risk_score

-- TASK 88 — prevent_self_transfer_trigger
-- Создать TRIGGER:
-- * запрет перевода самому себе

-- TASK 89 — check_account_status_before_transaction_trigger
-- Создать TRIGGER:
-- * проверка статуса счета перед транзакцией

-- TASK 90 — update_last_activity_trigger
-- Создать TRIGGER:
-- * обновление последней активности

-- TASK 91 — auto_close_expired_cards_trigger
-- Создать TRIGGER:
-- * автоматическое закрытие просроченных карт

-- TASK 92 — validate_phone_format_trigger
-- Создать TRIGGER:
-- * валидация формата телефона

-- TASK 93 — check_email_uniqueness_trigger
-- Создать TRIGGER:
-- * проверка уникальности email

-- TASK 94 — update_balance_on_transaction_trigger
-- Создать TRIGGER:
-- * обновление баланса при транзакции

-- TASK 95 — auto_block_suspicious_accounts_trigger
-- Создать TRIGGER:
-- * автоматическая блокировка подозрительных счетов

-- TASK 96 — log_failed_transactions_trigger
-- Создать TRIGGER:
-- * лог failed транзакций

-- TASK 97 — prevent_duplicate_transactions_trigger
-- Создать TRIGGER:
-- * запрет дубликатов транзакций

-- TASK 98 — update_customer_risk_trigger
-- Создать TRIGGER:
-- * обновление риска клиента

-- TASK 99 — check_minimum_balance_trigger
-- Создать TRIGGER:
-- * проверка минимального баланса

-- TASK 100 — auto_generate_card_number_trigger
-- Создать TRIGGER:
-- * автоматическая генерация номера карты