
-- ## 💎 REAL BANK SYSTEM — 100 TASK (YANGILANGAN)

-- ---

-- ## VIEW (1-25)

-- TASK 1 — Customer financial snapshot VIEW
-- Создать VIEW:
-- * общий баланс
-- * количество активных счетов
-- * risk score



-- TASK 1 — Customer financial snapshot VIEW

-- PARAMETER
-- TABLE: customers, accounts
create view fin_snapshop as

-- COLUMNS:
-- customer_id
-- full_name
-- total_balance (SUM accounts.balance)
-- active_accounts_count (COUNT accounts.id WHERE status='active')
-- risk_score-
select c.id customer_id,c.full_name,sum(a.balance) total_balance, sum(case when a.status='active' then 1 else 0 end) active_accounts_count,
c.risk_score  from customers c
left join accounts a on a.customer_id=c.id 
group by c.id, c.full_name, c.risk_score


-- 1. customers jadvali bilan accounts jadvalini LEFT JOIN qilish
-- 2. customer_id, full_name, risk_score bo'yicha GROUP BY qilish
-- 3. total_balance uchun SUM(balance) hisoblash, NULL bo'lsa 0
-- 4. active_accounts_count uchun COUNT(id) hisoblash, faqat status='active'
-- 5. Natijalarni customer_id bo'yicha sort qilish










use RealBankSystem
-- TASK 2 — Active accounts VIEW
-- Создать VIEW:
-- * только активные счета
-- * баланс > 0

create view active_accounts_balance as 
select id, status, balance   from accounts where status='active'

select * from active_accounts_balance

-- TASK 3 — Enriched transactions VIEW
-- Создать VIEW:
-- * транзакции + счета + клиенты

create view enriched_tx as 

select c.id, c.full_name,a.id, t.id, t.type, t.amount, t.status, t.created_at   from customers c
 join accounts a on a.customer_id=c.id
join transactions t on t.from_account_id=a.id 

union all
select c.id, c.full_name,a.id, t.id, t.type, t.amount, t.status, t.created_at   from customers c
 join accounts a on a.customer_id=c.id
join transactions t on t.to_account_id=a.id 


-- TASK 4 — Daily customer flow VIEW
-- Создать VIEW:
-- * дневной приход
-- * дневной расход
-- * net flow

-- TASK 4 — Daily customer flow VIEW

-- PARAMETER
-- TABLE: customers, accounts, transactions

-- 1. customers jadvali bilan accounts jadvalini LEFT JOIN qilish
-- 2. accounts jadvali bilan transactions jadvalini LEFT JOIN qilish (from_account_id va to_account_id orqali)
-- 3. transaction created_at dan DATE olish (kun bo‘yicha guruhlash)
-- 4. from_account_id bo‘yicha total_sent hisoblash (SUM amount)
-- 5. to_account_id bo‘yicha total_received hisoblash (SUM amount)
-- 6. net_flow = total_received - total_sent hisoblash
-- 7. customer_id va date bo‘yicha GROUP BY qilish
-- 8. NULL qiymatlarni 0 ga aylantirish (COALESCE)
-- 9. Natijalarni customer_id va date bo‘yicha tartiblash

select c.id customer_id, cast(t.created_at as date) as day, sum(case when t.from_account_id=a.id then t.amount else 0 end) total_sent, 
sum(case when t.to_account_id =a.id then t.amount else 0 end) total_recived from customers c
left join accounts a on a.customer_id=c.id 
left join transactions t on t.from_account_id=a.id or t.to_account_id=a.id
group by c.id, CAST(t.created_at as date) 










-- TASK 5 — Fraud signals VIEW
-- Создать VIEW:
-- * неуспешные транзакции
-- * большие суммы
create view fraud_signal as 
select *  from transactions 
where status ='failed'
and amount>10000



select *from transactions


-- TASK 6 — Dormant accounts VIEW
-- Создать VIEW:
-- * нет активности 30 дней
-- * баланс > 0
create view unactive_account as
select a.customer_id, sum(balance) total_balane from accounts a
left join transactions t on t.from_account_id=a.id or t.to_account_id=a.id 
group by a.customer_id, a.id, a.balance 
having sum(case when t.created_at>=dateadd(day,-30, GETDATE()) then 1 else 0 end) = 0 and a.balance>0




-- TASK 7 — High risk customers VIEW
-- Создать VIEW:
-- * risk score > 70

create view high_score_cus  as select id, full_name, phone, email, risk_score from customers where risk_score>70


-- TASK 8 — System liquidity VIEW
-- Создать VIEW:
-- * inflow vs outflow

create view sys_liquid as
select cast(created_at as date) as day,  sum(case when from_account_id is not null  then amount else 0 end)sent_total, 
sum(case when to_account_id is not null then amount else 0 end)recived_total,
sum(case when to_account_id is not null then amount else 0 end) -sum(case when from_account_id is not null then amount else 0 end) net_flow
from transactions 
group by cast(created_at as date) 

-- TASK 9 — Loan exposure VIEW
-- Создать VIEW:
-- * активные кредиты

create view acitve_loans as

select customer_id, amount, status, created_at from loans 
where status='active'



-- TASK 10 — Card status VIEW
-- Создать VIEW:
-- * active / blocked / expired



create view status_cards as

select account_id, status, card_number, expiry_date, created_at from cards 
where status in('active', 'expired', 'blocked')



-- TASK 11 — Customer lifetime value VIEW
-- Создать VIEW:
-- * общая сумма пополнений клиента
-- * общая сумма снятий
-- * показатель пожизненной ценности

-- PARAMETER
-- TABLE: customers, accounts, transactions

-- 1. customers jadvalini accounts bilan JOIN qilish
-- 2. accounts jadvalini transactions bilan JOIN qilish
-- 3. customer bo'yicha barcha deposit transactionlarni topish
-- 4. total_deposit uchun SUM(amount) hisoblash
-- 5. customer bo'yicha barcha withdraw transactionlarni topish
-- 6. total_withdraw uchun SUM(amount) hisoblash
-- 7. customer_id bo'yicha GROUP BY qilish
-- 8. NULL qiymatlarni COALESCE orqali 0 ga aylantirish
-- 9. lifetime_value = total_deposit - total_withdraw hisoblash
-- 10. Natijalarni customer_id bo'yicha tartiblash
create view lifetime_volue
select c.id,  sum(case when t.type='deposit' then t.amount else 0 end) total_deposit, sum(case when t.type='withdraw' then t.amount else 0 end) total_withdraw  
from customers c  
join accounts a on c.id=a.customer_id
join transactions t on t.from_account_id=a.id or t.to_account_id=a.id 
group by c.id


-- TASK 12 — Account health score VIEW
-- Создать VIEW:
-- * стабильность баланса
-- * регулярность транзакций
-- * оценка здоровья счета

-- PARAMETER
-- TABLE: accounts, transactions

-- 1. accounts jadvalini transactions jadvali bilan JOIN qilish
-- 2. har bir account uchun transactionlar sonini hisoblash
-- 3. har bir account uchun oxirgi transaction sanasini topish
-- 4. balance qiymatini olish
-- 5. transaction_count orqali transaction regularity hisoblash
-- 6. balance orqali balance stability ko‘rsatkichini hisoblash
-- 7. account_id bo‘yicha GROUP BY qilish
-- 8. NULL qiymatlarni COALESCE orqali 0 ga aylantirish
-- 9. health_score hisoblash (balance stability + transaction regularity)
-- 10. natijani account_id bo‘yicha tartiblash

create view account_health_score as 

select a.id, a.balance,  count(t.id) count_tx, max(t.created_at) last_date_tx,
case when a.balance>1000 then 50 else 0 end + case when count(t.id)>10 then 50 else 0 end as health_score
from accounts a
left join transactions t on t.from_account_id=a.id or t.to_account_id=a.id 
 group by a.id, a.balance


 select * from account_health_score
-- TASK 13 — Multi-account relationship VIEW
-- Создать VIEW:
-- * анализ нескольких счетов одного клиента

-- PARAMETER
-- TABLE: customers, accounts, transactions

-- 1. customers jadvalini accounts bilan LEFT JOIN qilish
-- 2. har bir customer uchun barcha accounts larni yig‘ish
-- 3. account count hisoblash (customer nechta accountga ega)
-- 4. account balance lar yig‘indisini hisoblash (total balance)
-- 5. har bir account bo‘yicha transaction count hisoblash
-- 6. accountlar orasidagi aktivlikni tahlil qilish
-- 7. customer_id bo‘yicha GROUP BY qilish
-- 8. NULL qiymatlarni COALESCE bilan 0 qilish
-- 9. multi-account relationship score hisoblash
-- 10. natijani customer_id bo‘yicha tartiblash

create view multi_account as
select c.id, c.full_name ,count(a.id), isnull(sum(a.balance), 0) from customers c
left join accounts a on a.customer_id=c.id 
group by c.id, c.full_name


-- TASK 14 — Transaction risk segmentation VIEW
-- Создать VIEW:
-- * tranzaksiyalarni risk darajalariga ajratish (low / medium / high)

-- PARAMETER
-- TABLE: transactions

-- 1. transactions jadvalidan barcha yozuvlarni olish
-- 2. amount bo‘yicha risk level aniqlash
-- 3. status ni hisobga olish (failed = higher risk)
-- 4. CASE WHEN orqali risk segmentation qilish
-- 5. created_at ni saqlash
-- 6. transaction_id bo‘yicha natijani tartiblash


select id, amount, status, created_at,
case when status='failed' then 'high' when amount>10000 then 'high' when amount>1000 then 'Medium' else 'low' end as level_tx 
from transactions 
group by id, amount, status, created_at







-- TASK 15 — Card usage intensity VIEW
-- Создать VIEW:
-- * karta ishlatilish intensivligini tahlil qilish

-- PARAMETER
-- TABLE: cards, transactions

-- 1. cards jadvalini transactions bilan JOIN qilish (card orqali bog‘lanadi)
-- 2. har bir card uchun transaction count hisoblash
-- 3. har bir card uchun total amount hisoblash
-- 4. created_at bo‘yicha oxirgi foydalanish sanasini olish
-- 5. usage intensity (low / medium / high) aniqlash
-- 6. card_id bo‘yicha GROUP BY qilish
-- 7. NULL qiymatlarni COALESCE bilan 0 qilish
-- 8. natijani card_id bo‘yicha tartiblash


select c.id, count(t.id) tx_count, max(t.created_at)last_tx_date,coalesce(sum(t.amount), 0) total_amoun,
case when count(t.id)=0 then 'low' when count(t.id) between 1 and 10 then 'medium' else 'high' end as use_card

from cards c
join accounts a on c.account_id=a.id 
join transactions t on t.from_account_id=a.id or t.to_account_id=a.id 
group by c.id 


-- TASK 16 — Loan repayment behavior VIEW
-- Создать VIEW:
-- * loan to‘lovlarining o‘z vaqtida yoki kechikkanligini tahlil qilish

-- PARAMETER
-- TABLE: loans, loan_payments, customers

-- 1. loans jadvalini loan_payments bilan LEFT JOIN qilish
-- 2. har bir payment uchun created_at ni tekshirish
-- 3. payment status ni aniqlash (on_time / late)
-- 4. har bir loan uchun payment count hisoblash
-- 5. har bir loan uchun total paid amount hisoblash
-- 6. overdue paymentlar sonini hisoblash
-- 7. customer_id bo‘yicha GROUP BY qilish
-- 8. NULL qiymatlarni COALESCE bilan 0 qilish
-- 9. natijani customer_id bo‘yicha tartiblash


select l.id,  l.customer_id,  count(lp.id) count_payment, ISNULL(sum(lp.amount),0), max(lp.created_at) last_date_payment,
case when count(lp.id)=0 then 'no payment' when max(lp.created_at)>=l.created_at then 'on time' else 'late' end 
from loans l 
left join loan_payments lp on lp.loan_id=l.id 
group by l.id, l.customer_id, l.created_at



-- TASK 17 — Customer inactivity risk VIEW
-- Создать VIEW:
-- * прогнозируемая неактивность

-- TASK 18 — System bottleneck accounts VIEW
-- Создать VIEW:
-- * счета, создающие высокую нагрузку

-- TASK 19 — Fraud correlation VIEW
-- Создать VIEW:
-- * связь мошенничества + входов + транзакций

-- TASK 20 — Currency exposure VIEW
-- Создать VIEW:
-- * валютный риск (пользователи с большим объёмом USD)

-- TASK 21 — Overdraft VIEW
-- Создать VIEW:
-- * отрицательный баланс

-- TASK 22 — Fraud alerts VIEW
-- Создать VIEW:
-- * fraud alerts

-- TASK 23 — System health VIEW
-- Создать VIEW:
-- * состояние системы

-- TASK 24 — Account activity summary VIEW
-- Создать VIEW:
-- * общая активность

-- TASK 25 — Cashflow heat VIEW
-- Создать VIEW:
-- * активность по времени

-- ---

-- ## FUNCTION (26-50)

-- TASK 26 — get_account_balance FUNCTION

-- PARAMETER
-- @account_id INT

-- 1. accounts jadvalidan berilgan @account_id bo‘yicha account qidirish
-- 2. account mavjudligini tekshirish
-- 3. agar account topilsa uning balance qiymatini olish
-- 4. agar account topilmasa NULL qaytishini oldini olish
-- 5. NULL bo‘lsa 0 qaytarish (COALESCE ishlatish)
-- 6. faqat bitta scalar qiymat (balance) qaytarish
-- 7. function faqat SELECT ishlatadi (read-only)

create function get_account_balance (@account_id int) 

returns decimal(12,2)
as begin 
declare @balance decimal(12,2);

select @balance=balance from accounts where id =@account_id;

return coalesce(@balance, 0);
end;


-- TASK 27 — get_risk_score FUNCTION
-- Создать FUNCTION:
-- * customer uchun risk score hisoblash

-- PARAMETER
-- @customer_id INT

-- 1. customers jadvalidan customer ma’lumotini olish
-- 2. accounts sonini hisoblash
-- 3. transactions sonini hisoblash (from + to)
-- 4. failed transactions sonini hisoblash
-- 5. umumiy balance ni hisoblash
-- 6. risk score uchun basic logic aniqlash
-- 7. NULL qiymatlarni COALESCE bilan 0 qilish
-- 8. natijada 0–100 oralig‘ida score qaytarish
-- 9. function faqat scalar value qaytaradi

create function get_risk_score (@customer_id int) 
returns int
as begin 
declare @account_count int;
declare @tx_count int;
declare @total_balance decimal(12,2);
declare @count_failed_tx int ;
declare @risk_score int;

select @account_count= count(id) from accounts where customer_id =@customer_id;
select @tx_count=count(t.id) from accounts a
left join  transactions t on t.from_account_id=a.id or t.to_account_id=a.id where a.customer_id=@customer_id;
select @total_balance=coalesce(sum(balance),0) from accounts where customer_id=@customer_id;
select @count_failed_tx=count(t.id) from accounts a left join transactions t on t.from_account_id=a.id or t.to_account_id=a.id where a.customer_id=@customer_id
and t.status='failed';


set @risk_score=(case when @account_count>3 then 20 else 0 end )+(case when @tx_count>50 then 20 else 0 end)+(case when @count_failed_tx>5 then 40 else 0 end) +(case when @total_balance<1000 then 20 else 0 end);
return coalesce(@risk_score, 0);
end;



select dbo.get_risk_score(1)
where dbo.get_risk_score(1) between 1 and 40;

select dbo.get_risk_score between 1 and 40





-- TASK 28 — get_net_flow FUNCTION
-- Создать FUNCTION:
-- * customer uchun kirim va chiqim mablag‘lar farqini hisoblash (net flow)
-- PARAMETER
-- @customer_id INT
-- TABLE: customers, accounts, transactions
-- 1. customers jadvalidan customer ma’lumotini olish
-- 2. DECLARE orqali oraliq o‘zgaruvchilar yaratish:
--    @incoming DECIMAL(12,2) → kirim summa
--    @outgoing DECIMAL(12,2) → chiqim summa
--    @net_flow DECIMAL(12,2) → yakuniy natija
-- 3. accounts jadvali bilan customer_id bo‘yicha ishlash
-- 4. kirim (incoming) tranzaksiyalarni hisoblash (to_account_id orqali)
-- 5. chiqim (outgoing) tranzaksiyalarni hisoblash (from_account_id orqali)
-- 6. umumiy kirim summasini hisoblash (SUM amount)
-- 7. umumiy chiqim summasini hisoblash (SUM amount)
-- 8. net_flow = incoming - outgoing hisoblash
-- 9. NULL qiymatlarni COALESCE bilan 0 qilish
-- 10. faqat bitta scalar value qaytarish (net_flow)

create function get_net_flow (@customer_id int)
returns decimal(12,2)
as begin 
declare @incoming decimal(12,2);
declare @outcoming decimal(12,2); 
declare @net decimal(12,2);

select @incoming=coalesce(sum(t.amount),0) from accounts a left join transactions t on  t.to_account_id=a.id
where a.customer_id=@customer_id;

select @outcoming=coalesce(sum(t.amount),0) from accounts a left join transactions t on t.from_account_id=a.id  where a.customer_id=@customer_id;

set @net=@incoming - @outcoming;

return coalesce(@net, 0);
end;







-- TASK 29 — detect_duplicate_transfer FUNCTION
-- Создать FUNCTION:
-- * 60 sekund ichida takrorlangan transferlarni aniqlash (duplicate detection)
-- PARAMETER
-- @account_id INT
-- TABLE: transactions
-- 1. accounts bo‘yicha transactionlarni olish (from_account_id va to_account_id)
-- 2. DECLARE orqali oraliq o‘zgaruvchilar yaratish:
--    @tx_count INT → umumiy transactionlar soni
--    @duplicate_count INT → duplicate transactionlar soni
--    @risk_flag INT → natijaviy flag (0/1)
-- 3. transactions jadvalidan account_id bo‘yicha barcha operatsiyalarni olish
-- 4. har bir transaction uchun amount va created_at ni hisobga olish
-- 5. bir xil amount bilan 60 sekund ichida takrorlangan transactionlarni aniqlash
-- 6. vaqt farqini hisoblash (LAG yoki self join orqali)
-- 7. duplicate transactionlarni hisoblash (count)
-- 8. duplicate bo‘lmasa 0 qaytarish (COALESCE bilan)
-- 9. risk_flag = 1 agar duplicate_count > 0 bo‘lsa, aks holda 0
-- 10. faqat bitta scalar value qaytarish (risk_flag yoki duplicate_count) mana kordinga endi qolganlarini ham shunday qilasan

create function detect_duplicate_transfer(@account_id int)
returns int 
as begin 
declare @tx_count int;
declare @duplicate_count int;
declare @risk_flag int;

select @tx_count=count(t.id) from accounts a left join transactions t on t.from_account_id=a.id or t.to_account_id=a.id where a.id=@account_id;
select @duplicate_count= count(*) from transactions t1 join transactions t2 on (t1.from_account_id=t2.from_account_id or t1.to_account_id=t2.to_account_id) and
t1.amount=t2.amount and abs(datediff (SECOND, t1.created_at, t2.created_at))<=60
where (t1.from_account_id=@account_id or t1.to_account_id=@account_id) and t1.id<>t2.id;

set @risk_flag=case when isnull(@duplicate_count,0)>0 then 1 else 0 end 
return @risk_flag;
end;



-- TASK 30 — get_failed_ratio FUNCTION
-- Создать FUNCTION:
-- * failed transactionlar foizini hisoblash
-- PARAMETER
-- @account_id INT
-- TABLE: accounts, transactions
-- 1. account bo‘yicha barcha transactionlarni olish (from_account_id va to_account_id)
-- 2. DECLARE orqali oraliq o‘zgaruvchilar yaratish:
--    @total_tx INT → umumiy transactionlar soni
--    @failed_tx INT → failed transactionlar soni
--    @failed_ratio DECIMAL(5,2) → xatolik foizi
-- 3. umumiy transactionlar sonini hisoblash
-- 4. status = 'failed' bo‘lgan transactionlar sonini hisoblash
-- 5. NULL qiymatlarni ISNULL yoki COALESCE bilan 0 qilish
-- 6. total_tx = 0 holatini tekshirish
-- 7. failed_ratio = (failed_tx * 100.0) / total_tx hisoblash
-- 8. natijani foiz ko‘rinishida olish
-- 9. faqat bitta scalar value qaytarish (failed_ratio)

create function get_failed_ratio (@account_id  int)
returns decimal(12,2) 
as begin 
declare @total_tx int;
declare @failed_tx int;
declare @failed_ratio decimal(12,2);


select @total_tx=count(id) from transactions t
where (t.from_account_id=@account_id or t.to_account_id=@account_id );

select @failed_tx=count(id) from transactions where status='failed' and  (from_account_id=@account_id or to_account_id=@account_id);
set @failed_ratio=coalesce((@failed_tx*100.0)/nullif(@total_tx, 0),0);
return @failed_ratio;
end;





-- TASK 31 — get_activity_score FUNCTION
-- Создать FUNCTION:
-- * customerning activity score (faollik darajasi) hisoblash
-- PARAMETER
-- @customer_id INT
-- TABLE: customers, accounts, transactions
-- 1. customers jadvalidan customer ma’lumotini olish
-- 2. DECLARE orqali oraliq o‘zgaruvchilar yaratish:
--    @account_count INT → accountlar soni
--    @tx_count INT → transactionlar soni
--    @active_days INT → activity kunlari soni
--    @activity_score INT → yakuniy score
-- 3. accounts jadvali orqali customer_id bo‘yicha accountlarni olish
-- 4. transactions jadvalidan incoming + outgoing transactionlarni hisoblash
-- 5. DISTINCT created_at (kun bo‘yicha) activity kunlarini aniqlash
-- 6. NULL qiymatlarni COALESCE bilan 0 qilish
-- 7. activity score uchun basic formula aniqlash (accounts + tx + active_days)
-- 8. score 0–100 oralig‘ida normallashtirish
-- 9. faqat bitta scalar value qaytarish (activity_score)

create function get_activity_score(@customer_id int) 
returns int
as begin 
declare @account_count int;
declare @tx_count int;
declare @active_days int;
declare @activity_score int;

select @account_count=count(id) from accounts where customer_id=@customer_id;
select @tx_count=count(t.id) from transactions t where  t.from_account_id in (select id from accounts where customer_id=@customer_id)
or t.to_account_id in (select id from accounts where customer_id=@customer_id)

select @active_days=count(distinct cast(t.created_at as date)) from transactions t where  
t.from_account_id in (select id from accounts where customer_id=@customer_id)
or t.to_account_id in (select id from accounts where customer_id=@customer_id)

set @activity_score=coalesce(@account_count, 0) +coalesce(@active_days,0) +coalesce(@tx_count, 0)

return @activity_score;
end;




-- TASK 32 — calculate_account_velocity FUNCTION
-- Создать FUNCTION:
-- * account transaction velocity (ma'lum vaqt ichida tranzaksiya tezligi)
-- PARAMETER
-- @account_id INT
-- TABLE: accounts, transactions
-- 1. accounts jadvalidan account ma’lumotini olish
-- 2. DECLARE orqali oraliq o‘zgaruvchilar yaratish:
--    @tx_count INT → umumiy transactionlar soni
--    @time_span INT → vaqt oralig‘i (kunlarda)
--    @velocity DECIMAL(12,2) → transaction tezligi
-- 3. transactions jadvalidan account_id bo‘yicha barcha operatsiyalarni olish
-- 4. from_account_id va to_account_id bo‘yicha filter qilish
-- 5. MIN(created_at) va MAX(created_at) orqali vaqt oralig‘ini topish
-- 6. time_span = DATEDIFF(day, min_date, max_date)
-- 7. time_span = 0 bo‘lsa 1 qilish (division by zero oldini olish)
-- 8. velocity = tx_count / time_span hisoblash
-- 9. NULL qiymatlarni COALESCE bilan 0 qilish
-- 10. faqat bitta scalar value qaytarish (velocity)

create function calculate_account_velocity (@account_id int) 
returns decimal(12,2)
as begin 
declare @tx_count int;
declare @time_span int;
declare @velocity decimal(12,2);


select @tx_count=count(id) from transactions where from_account_id=@account_id or to_account_id=@account_id;

select @time_span=  datediff(day, MIN(created_at), max(created_at)) from transactions t 
where from_account_id=@account_id or to_account_id=@account_id;

set @velocity=@tx_count*1.0/ nullif(@time_span, 0);
return coalesce(@velocity, 0) 
end ;

-- TASK 33 — detect_balance_instability FUNCTION
-- Создать FUNCTION:
-- * detect balance instability (balance o‘zgarishining beqarorligi)
-- PARAMETER
-- @account_id INT
-- TABLE: accounts, transactions

-- 1. accounts jadvalidan accountni olish
-- 2. DECLARE variables:
--    @balance_changes INT → balans o‘zgarishlar soni
--    @total_tx INT → umumiy transactionlar
--    @instability_score DECIMAL(12,2)

-- 3. transactions jadvalidan account bo‘yicha barcha operatsiyalarni olish
-- 4. from_account_id va to_account_id bo‘yicha filter
-- 5. CASE ishlatib balance impact aniqlash:
--    - incoming (+)
--    - outgoing (-)

-- 6. LAG() orqali oldingi balance bilan solishtirish
-- 7. ABS() bilan katta o‘zgarishlarni topish
-- 8. instability = katta balance jumps soni

-- 9. NULL qiymatlarni COALESCE bilan 0 qilish

-- 10. faqat bitta scalar value qaytarish (instability_score)



create function detect_balance_instability(@account_id int)
returns int
as begin 
declare @instability_count int;
with tx as (
select id, amount, created_at, case when to_account_id =@account_id then amount else -amount end as balance_change from transactions 
where from_account_id=@account_id or to_account_id=@account_id),

ordered as (
select * , lag(balance_change) over(order by created_at) as prev_amount from tx )

select @instability_count=count(*) from ordered where abs(balance_change-prev_amount)>1000;

return coalesce(@instability_count, 0);

end;

select dbo.detect_balance_instability (5)

-- TASK 34 — get_login_risk_score FUNCTION
-- Создать FUNCTION:
-- * login risk score (kirish xavfi darajasi)
-- PARAMETER @customer_id INT
-- TABLE: login_history, customers
-- 1. customers bo‘yicha login history olish
-- 2. DECLARE variables:
-- @total_logins INT, @unique_devices INT, @unique_ips INT, @risk_score DECIMAL(12,2)
-- 3. login_history dan customer_id bo‘yicha barcha loglarni olish
-- 4. status yo‘q (failed login yo‘q)
-- 5. DISTINCT device bo‘yicha unique devices hisoblash
-- 6. DISTINCT ip_address bo‘yicha IP diversity hisoblash
-- 7. login frequency (oxirgi 7 yoki 30 kun) created_at orqali
-- 8. risk = login frequency + device diversity + IP diversity
-- 9. NULL qiymatlar COALESCE bilan 0 qilinadi
-- 10. bitta scalar value qaytariladi (risk_score)



create function get_login_risk_score (@customer_id int)
returns decimal(12,2) 
as begin 
declare @unique_ips int ;
declare @total_logins int;
declare @unique_devices int;
declare @risk_score decimal(12,2);

select @unique_ips = count(distinct ip_address) from login_history where customer_id=@customer_id and created_at>=DATEADD(day, -30, GETDATE());
select @total_logins=count(id) from login_history where customer_id=@customer_id and created_at>=DATEADD(day, -30, GETDATE());
select @unique_devices=count(distinct device) from login_history where customer_id =@customer_id and created_at>=DATEADD(day, -30, GETDATE());

set @risk_score=coalesce(@unique_devices, 0)+ coalesce(@unique_ips, 0 ) + coalesce(@total_logins, 0);
return coalesce(@risk_score, 0);
end;




select * from login_history


-- TASK 35 — detect_account_farming FUNCTION
-- Создать FUNCTION:
-- * выявление фейковых аккаунтов

-- PARAMETER
-- @customer_id INT

-- TABLE: accounts, transactions

-- 1. customers bo‘yicha account history olish
-- 2. DECLARE variables:
--    @account_count INT → customer accounts soni
--    @tx_count INT → customer transactions soni
--    @farming_score INT

-- 3. accounts dan customer_id bo‘yicha barcha accounts olish
-- 4. transactions dan customer_id ga tegishli barcha tx larni hisoblash
-- 5. account + transaction activity asosida farming detection
-- 6. score = account_count + tx_count
-- 7. NULL qiymatlar COALESCE bilan 0 qilinadi
-- 8. bitta scalar value qaytariladi (farming_score)


create function detect_account_farming (@customer_id int)

returns int 
as begin 

declare @account_count int;
declare @tx_count int;
declare @farming_score int;

select @account_count=count(*) from accounts where customer_id =@customer_id;
select @tx_count=count(*) from transactions t 
where t.from_account_id in (select id from accounts where customer_id=@customer_id) or 
t.to_account_id in (select id from accounts where customer_id=@customer_id);

set @farming_score=coalesce(@account_count, 0) + coalesce(@tx_count, 0 );

return coalesce(@farming_score, 0);
end;





-- TASK 36 — calculate_transaction_density FUNCTION
-- Создать FUNCTION:
-- * плотность транзакций в час / день

-- PARAMETER
-- @account_id INT

-- TABLE: transactions

-- 1. account bo‘yicha barcha transactionlarni olish
-- 2. DECLARE variables:
--    @tx_count INT
--    @time_span INT
--    @density DECIMAL(12,2)

-- 3. from_account_id yoki to_account_id bo‘yicha transactionlarni hisoblash
-- 4. MIN(created_at) va MAX(created_at) orasidagi vaqtni topish
-- 5. DATEDIFF(hour) yoki DATEDIFF(day) ishlatish
-- 6. density = tx_count / time_span
-- 7. division by zero dan NULLIF bilan himoyalanish
-- 8. NULL qiymatlarni COALESCE bilan 0 qilish
-- 9. bitta scalar value qaytarish (density)

create function calculate_transaction_density (@account_id int)
returns decimal(12,2)
as begin 
declare @tx_count int; 
declare @time_span int;
declare @density decimal(12,2);

select @tx_count=COUNT(*) from transactions where from_account_id=@account_id or to_account_id=@account_id;
select @time_span=datediff(day, min(created_at), max(created_at)) from transactions where from_account_id=@account_id or to_account_id=@account_id;

set @density=coalesce(@tx_count*1.0 / nullif(@time_span,0), 0);return coalesce (@density, 0);
end;



-- TASK 37 — detect_money_cycling FUNCTION
-- Создать FUNCTION:
-- * обнаружение круговых движений средств

-- PARAMETER
-- @account_id INT

-- TABLE: transactions

-- 1. account bo‘yicha transactionlarni olish
-- 2. DECLARE variables:
--    @outgoing_count INT
--    @incoming_count INT
--    @cycling_score DECIMAL(12,2)

-- 3. from_account_id = @account_id bo‘yicha outgoing transactionlarni hisoblash
-- 4. to_account_id = @account_id bo‘yicha incoming transactionlarni hisoblash
-- 5. incoming va outgoing activity nisbatini hisoblash
-- 6. cycling_score = incoming_count * 1.0 / NULLIF(outgoing_count,0)
-- 7. NULL qiymatlarni COALESCE bilan 0 qilish
-- 8. bitta scalar value qaytarish (cycling_score)

create function detect_money_cycling(@account_id int) 
returns decimal(12,2) 
as begin 
declare @outing_count int;
declare @incoming_count int;
declare @cycling_score decimal(12,2);

select @outing_count=count(*) from transactions where from_account_id=@account_id;
select @incoming_count=count(*) from transactions where to_account_id=@account_id;

set @cycling_score=coalesce(@incoming_count *1.0/ nullif(@outing_count, 0),0);
return coalesce(@cycling_score, 0);
end;




-- TASK 38 — predict_account_failure FUNCTION
-- Создать FUNCTION:
-- * риск будущего отказа счета

-- PARAMETER
-- @account_id INT

-- TABLE: accounts, transactions

-- 1. account bo‘yicha ma'lumotlarni olish
-- 2. DECLARE variables:
--    @failed_tx_count INT
--    @total_tx_count INT
--    @failure_risk DECIMAL(12,2)

-- 3. account ga tegishli barcha transactionlarni olish
-- 4. status = 'failed' bo‘yicha transactionlarni hisoblash
-- 5. umumiy transactionlar sonini hisoblash
-- 6. risk = failed_tx_count * 1.0 / NULLIF(total_tx_count,0)
-- 7. NULL qiymatlarni COALESCE bilan 0 qilish
-- 8. bitta scalar value qaytarish (failure_risk)


create function predict_account_failure(@account_id int)
returns decimal(12,2 )  
as begin 
declare @failed_tx_count int;
declare @total_tx_count int;
declare @failture_risk decimal(12,2);

select @failed_tx_count=count(*) from transactions where (from_account_id=@account_id or to_account_id=@account_id) and status='failed';
select @total_tx_count=count(*) from transactions where from_account_id=@account_id or to_account_id=@account_id;
set @failture_risk=coalesce(@failed_tx_count*1.0/nullif(@total_tx_count, 0),0) ;
return coalesce(@failture_risk,0);
end;


-- TASK 39 — calculate_customer_stability FUNCTION
-- Создать FUNCTION:
-- * индекс финансовой стабильности

-- PARAMETER
-- @customer_id INT

-- TABLE: accounts, transactions

-- 1. customer ga tegishli accountlarni olish
-- 2. DECLARE variables:
--    @account_count INT
--    @total_tx_count INT
--    @stability_score DECIMAL(12,2)

-- 3. accounts dan customer accountlarini hisoblash
-- 4. shu accountlarga tegishli transactionlarni hisoblash
-- 5. stability = total_tx_count * 1.0 / NULLIF(account_count,0)
-- 6. NULL qiymatlarni COALESCE bilan 0 qilish
-- 7. bitta scalar value qaytarish (stability_score)

create function calculate_customer_stability(@customer_id int)
returns decimal(12,2)

as begin 

declare @account_count int;
declare @total_tx_count int;
declare @stability_score decimal(12,2);


select @account_count=count(*) from accounts where customer_id=@customer_id;

select @total_tx_count=count(*) from  transactions t where t.from_account_id in(select id from accounts where customer_id =@customer_id )
or t.to_account_id in (select id from accounts where customer_id = @customer_id);
set @stability_score=coalesce(@total_tx_count * 1.0 / nullif(@account_count,0),0) ;
return coalesce(@stability_score,0);
end;








-- TASK 40 — detect_card_sharing FUNCTION
-- Создать FUNCTION:
-- * использование одной карты на нескольких счетах

-- PARAMETER
-- @card_id INT

-- TABLE: cards, accounts

-- 1. card bo‘yicha barcha accountlarni olish
-- 2. DECLARE variables:
--    @linked_accounts INT
--    @sharing_score INT

-- 3. cards table dan card_id bo‘yicha accountlarni tekshirish
-- 4. DISTINCT account_count hisoblash
-- 5. card sharing detection = multiple accounts usage
-- 6. sharing_score = linked_accounts
-- 7. NULL qiymatlar COALESCE bilan 0 qilinadi
-- 8. bitta scalar value qaytarish (sharing_score)

create function datect_card_sharing(@card_id int) 
returns int 
as begin 
declare @linked_accounts int ;
declare @sharing_score int;
select @linked_accounts=count(distinct account_id) from cards where id=@card_id;
set @sharing_score=coalesce(@linked_accounts, 0);
return @sharing_score;
end;

select * from cards






-- TASK 41 — calculate_system_risk_index FUNCTION
-- Создать FUNCTION:
-- * глобальный риск системы

-- TABLES: customers, accounts, transactions, login_history

-- 1. system bo‘yicha overall metrics hisoblash
-- 2. DECLARE variables:
--    @total_customers INT
--    @total_accounts INT
--    @total_transactions INT
--    @total_logins INT
--    @risk_index DECIMAL(12,2)

-- 3. customers soni
-- 4. accounts soni
-- 5. transactions soni
-- 6. login_history soni
-- 7. risk formula:
--    risk_index = total_transactions + total_logins + total_accounts - total_customers
-- 8. NULL qiymatlar COALESCE bilan 0 qilinadi
-- 9. bitta scalar value qaytariladi (risk_index)


create function calculate_system_risk_index ()
returns decimal(12,2)
as begin 
declare @total_customrs  int;
declare @total_accounts int ;
declare @total_tx int;
declare @total_logins int;
declare @risk_index decimal(12,2);

select @total_accounts=count(*) from accounts ;
select @total_customrs=count(*) from customers;
select @total_tx=count(*) from transactions;
select @total_logins= count(*) from login_history;

set @risk_index=coalesce(@total_accounts, 0) +coalesce(@total_customrs, 0)+coalesce(@total_tx, 0)+ coalesce(@total_logins,0);

return coalesce(@risk_index,0);
end;



-- TASK 42 — calculate_fees FUNCTION
-- Создать FUNCTION:
-- * расчет комиссии

-- PARAMETER
-- @transaction_id INT

-- TABLE: transactions

-- 1. transaction bo‘yicha data olish
-- 2. DECLARE variables:
--    @amount DECIMAL(12,2)
--    @fee_rate DECIMAL(12,2)
--    @fee DECIMAL(12,2)

-- 3. amount ni transactions dan olish
-- 4. fee_rate = 0.02 (default 2%)
-- 5. fee = amount * fee_rate
-- 6. NULL qiymatlar COALESCE bilan 0 qilinadi
-- 7. bitta scalar value qaytariladi (fee)
create function calculate_fees (@transaction_id int) 
returns decimal(12,2)
as begin 
declare @amount decimal(12,2);
declare @fee_rate decimal(12,2);
declare @fee decimal(12,2);

select @amount= amount from transactions where id = @transaction_id;
set @fee_rate=0.02;
set @fee=coalesce(@amount,0)*@fee_rate;
return coalesce(@fee,0);
end;




-- TASK 43 — calculate_cashback FUNCTION
-- Создать FUNCTION:
-- * расчет cashback

-- PARAMETER
-- @transaction_id INT

-- TABLE: transactions

-- 1. transaction bo‘yicha amount olish
-- 2. DECLARE variables:
--    @amount DECIMAL(12,2)
--    @cashback_rate DECIMAL(12,2)
--    @cashback DECIMAL(12,2)

-- 3. amount ni transactions dan olish
-- 4. cashback_rate = 0.01 (default 1%)
-- 5. cashback = amount * cashback_rate
-- 6. NULL qiymatlar COALESCE bilan 0 qilinadi
-- 7. bitta scalar value qaytariladi (cashback)

create function calculate_cashback (@transaction_id int) 
returns decimal(12,2)
as begin 
declare @amount decimal(12,2);
declare @cashback_rate decimal(12,2);
declare @cashback decimal(12,2);

select @amount=amount from transactions where id=@transaction_id;
set @cashback_rate=0.01;

set @cashback=coalesce(@amount , 0)*@cashback_rate;
return coalesce(@cashback,0);
end;


create procedure add_cashbak 
@transactions int
as begin 






if @amount<=0 begin 
throw 50002, N'Mablag yetarli emas',1;
end;

select  @balance= balance from accounts where id =@account_id;

if @balance<@amount begin 
throw 50003,N'Balance yetarli emas',1;
end;

update accounts set balance=balance+@amount where id = @account_id  and status='active';

insert into transactions (from_account_id, to_account_id, type, status, amount) values
(null, @account_id, 'deposit', 'success', @amount);

commit;

end try 
begin catch 
rollback;
throw;
end catch 
end;




-- ADD CASHBACK PROCEDURE (IMPROVED TEMPLATE)

-- PARAMETER
-- @account_id INT
-- @amount DECIMAL(12,2)

-- DECLARE
-- @balance DECIMAL(12,2)
-- @tx_id INT
-- @cashback DECIMAL(12,2)


create procedure add_cashbak 
@account_id int,
@amount decimal(12,2)

as begin 
declare @balance decimal(12,2);
declare @tx_id int;
declare @cashback decimal(12,2);

begin try begin tran;

if not exists (select 1 from accounts where id=@account_id and status='active') begin 
throw 50001, N'Account mavjud emas', 1;
end;

if @amount<=0 begin 
throw 50002, N'Mablag yetarli emas',1;
end;

select @balance=balance from accounts where id =@account_id;

if @balance<@amount begin 
throw 50003, N'Balance yetarli emas', 1;
end;


declare @tx_table table(id int);

insert into transactions(from_account_id, to_account_id, type, status, amount) output inserted.id into @tx_table
values 
(null, @account_id, 'deposit', 'success', @amount);

select @tx_id=id from @tx_table;

set @cashback=dbo.calculate_cashback(@tx_id);

update accounts set balance=balance+@amount+coalesce(@cashback,0)
where id =@account_id;

commit;
end try 
begin catch 
rollback;
throw;
end catch
end;


exec add_cashbak 5, 1000


select * from accounts 
where status='active'



1. CHECK ACCOUNT
   - accounts mavjudmi va status = 'active'

2. VALIDATE AMOUNT
   - @amount > 0

3. GET BALANCE
   - accounts dan current balance olish

4. CHECK BALANCE
   - balance >= amount bo‘lishi shart

5. BEGIN TRANSACTION

6. UPDATE ACCOUNT
   - balance = balance + amount

7. INSERT TRANSACTION
   - deposit yozish (to_account_id = account_id)

8. GET TX_ID
   - scope_identity()

9. APPLY FUNCTION
   - cashback = dbo.calculate_cashback(@tx_id)

10. UPDATE CASHBACK
    - balance = balance + cashback

11. COMMIT TRANSACTION

12. ERROR HANDLING
    - rollback + throw



select dbo.fr



-- TASK 44 — detect_fraud_pattern FUNCTION

-- Создать FUNCTION:
-- * выявление fraud паттернов

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @high_value_tx INT
-- @failed_tx INT
-- @total_tx INT
-- @fraud_score DECIMAL(12,2)

-- TABLES
-- transactions

-- 1. account ga tegishli barcha transactionlarni olish
--    (from_account_id yoki to_account_id)

-- 2. amount > 1000 bo‘lgan transactionlar sonini hisoblash
--    -> @high_value_tx

-- 3. status = 'failed' bo‘lgan transactionlar sonini hisoblash
--    -> @failed_tx

-- 4. jami transactionlar sonini hisoblash
--    -> @total_tx

-- 5. fraud activity score hisoblash
--    fraud_score =
--    (@high_value_tx + @failed_tx) * 1.0 / NULLIF(@total_tx,0)

-- 6. barcha NULL qiymatlarni COALESCE bilan 0 qilish

-- 7. scalar value qaytarish
--    RETURN @fraud_score

create function detect_froud_pattern(@account_id int)
returns decimal(12,2)
as begin 
declare @high_volue_tx int;
declare @failed_tx int;
declare @total_tx int;
declare @froud_score decimal(12,2);

select @failed_tx=count(*) from transactions WHERE status='failed' and (from_account_id=@account_id or to_account_id=@account_id);
select @total_tx=count(*) from transactions where from_account_id=@account_id or to_account_id=@account_id;
select @high_volue_tx= count(*) from transactions where amount>10000 and (from_account_id=@account_id or to_account_id=@account_id);

set @froud_score=(@high_volue_tx+@failed_tx)*1.0 /nullif(@total_tx, 0) ;

return coalesce(@froud_score,0);

end ;






-- TASK 45 — detect_velocity_risk FUNCTION

-- Создать FUNCTION:
-- * риск скорости операций

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @recent_tx INT
-- @total_tx INT
-- @velocity_risk DECIMAL(12,2)

-- TABLES
-- transactions

-- 1. account ga tegishli barcha transactionlarni olish
--    (from_account_id yoki to_account_id)

-- 2. oxirgi 24 soat ichidagi transactionlar sonini hisoblash
--    -> @recent_tx

-- 3. jami transactionlar sonini hisoblash
--    -> @total_tx

-- 4. velocity_risk hisoblash
--    velocity_risk =
--    @recent_tx * 1.0 / NULLIF(@total_tx,0)

-- 5. COALESCE bilan NULL qiymatlarni 0 qilish

-- 6. scalar value qaytarish
--    RETURN @velocity_risk

create function detect_velocity_risk (@account_id int)
returns decimal(12,2) 
as begin 
declare @recent_tx int;
declare @total_tx int;
declare @veloity_risk decimal(12,2);

select @recent_tx=COUNT(*) from transactions where created_at>= dateadd(hour, -24, getdate()) and (from_account_id=@account_id or to_account_id=@account_id);
select @total_tx=count(*) from transactions where from_account_id=@account_id or to_account_id=@account_id;
set @veloity_risk=@recent_tx*1.0/nullif(@total_tx, 0) ;
return coalesce(@veloity_risk,0);
end;








-- TASK 46 — detect_laundering FUNCTION

-- Создать FUNCTION:
-- * подозрительные цепочки (suspicious chains)

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @outgoing_tx INT
-- @incoming_tx INT
-- @laundering_score DECIMAL(12,2)

-- TABLES
-- transactions

-- 1. account dan chiqgan transactionlar sonini hisoblash
--    -> @outgoing_tx

-- 2. account ga kirgan transactionlar sonini hisoblash
--    -> @incoming_tx

-- 3. laundering_score hisoblash
--    laundering_score =
--    @outgoing_tx * 1.0 / NULLIF(@incoming_tx,0)

-- 4. barcha NULL qiymatlarni COALESCE bilan 0 qilish

-- 5. scalar value qaytarish
--    RETURN @laundering_score

create function detect_laundering (@account_id int)
returns decimal(12,2)
as begin 
declare @outing_tx int;
declare @incoming_tz int;
declare @laundering_score decimal(12,2);

select @outing_tx=COUNT(*) from transactions where from_account_id=@account_id;
select @incoming_tz=count(*) from transactions where to_account_id=@account_id;
set @laundering_score=@outing_tx*1.0/nullif(@incoming_tz, 0);
return coalesce(@laundering_score, 0);
end;











-- TASK 47 — get_total_assets FUNCTION

-- Создать FUNCTION:
-- * активы клиента

-- PARAMETER
-- @customer_id INT

-- DECLARE
-- @total_assets DECIMAL(12,2)
-- @account_balance DECIMAL(12,2)

-- TABLES
-- accounts

-- 1. customer ga tegishli barcha accounts balansini yig‘ish
--    SUM(balance)

-- 2. NULL bo‘lsa 0 qaytarish (COALESCE)

-- 3. result ni return qilish

-- FORMULA:
-- total_assets = SUM(accounts.balance) WHERE customer_id = @customer_id

-- 4. scalar value return

create function get_total_assets (@customer_id int )
returns decimal(12,2)
as begin 
declare @total_assets decimal(12,2);

select @total_assets=coalesce(sum(balance),0) from accounts where customer_id=@customer_id;

return coalesce(@total_assets,0);
end;



-- TASK 48 — predict_risk_level FUNCTION
create function  predict_risk_level (@account_id int) 
returns nvarchar(10)
as begin 
declare @froud_score decimal(12,2);
declare @velocity_risk decimal(12,2);
declare @laundering_score decimal(12,2);
declare @risk_score decimal(12,2);
declare @risk_level nvarchar(10);


set @froud_score=dbo.detect_froud_pattern(@account_id);
set @velocity_risk=dbo.detect_velocity_risk(@account_id);
set @laundering_score=dbo.detect_laundering(@account_id);
set @risk_score=(@froud_score+@velocity_risk+@laundering_score)/3;

if @risk_score<0.3
set @risk_level='low';
else if @risk_score<0.7 
set @risk_level='medium';
else set @risk_level='high';

return @risk_level;
end;

drop function predict_risk_level

select dbo.predict_risk_level(23);

SELECT * FROM sys.objects WHERE type = 'FN'


-- Создать FUNCTION:
-- * LOW / MEDIUM / HIGH risk classification

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @fraud_score DECIMAL(12,2)
-- @velocity_risk DECIMAL(12,2)
-- @laundering_score DECIMAL(12,2)
-- @risk_level VARCHAR(10)

-- 1. fraud score olish
--    detect_fraud_pattern(@account_id)

-- 2. velocity risk olish
--    detect_velocity_risk(@account_id)

-- 3. laundering score olish
--    detect_laundering(@account_id)

-- 4. combined risk score hisoblash
--    risk_score =
--    (fraud_score + velocity_risk + laundering_score) / 3

-- 5. classification:
--    IF risk_score < 0.3  => LOW
--    IF risk_score < 0.7  => MEDIUM
--    ELSE => HIGH

-- 6. return @risk_level








-- TASK 49 — get_loan_exposure FUNCTION

-- Создать FUNCTION:
-- * credit/loan exposure (кредитный риск клиента)

-- PARAMETER
-- @customer_id INT

-- DECLARE
-- @total_loans DECIMAL(12,2)
-- @active_loans DECIMAL(12,2)
-- @overdue_loans DECIMAL(12,2)
-- @loan_risk DECIMAL(12,2)

-- TABLES
-- loans

-- 1. customer ga tegishli barcha loans yig‘indisi
--    SUM(amount) → @total_loans

-- 2. active loans yig‘indisi
--    status = 'active'

-- 3. overdue loans yig‘indisi
--    status = 'overdue'

-- 4. risk formula:
--    loan_risk =
--    (active_loans + overdue_loans * 2) / NULLIF(total_loans, 0)

-- 5. NULL bo‘lsa COALESCE bilan 0 qilish

-- 6. scalar return decimal(12,2)


create function get_loan_exposure(@customer_id int)
returns decimal (12,2) 
as begin 
declare @total_loans decimal(12,2);
declare @active_loans decimal(12,2);
declare @loan_risk decimal(12,2);

select @active_loans=sum(amount) from loans where status='active' and customer_id=@customer_id;
select @total_loans= sum(amount)  from loans where customer_id=@customer_id;
set @loan_risk=@active_loans*1.0/nullif(@total_loans, 0);
return coalesce(@loan_risk,0);
end;





-- TASK 50 — get_account_status_safe FUNCTION
-- Создать FUNCTION:
-- * безопасный статус

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @status NVARCHAR(20)
-- @risk_level NVARCHAR(10)
-- @is_safe NVARCHAR(20)

-- 1. Account mavjudligini tekshirish
--    accounts jadvalidan

-- 2. Account status olish
--    active / blocked / closed ...

-- 3. Risk level olish
--    dbo.predict_risk_level(@account_id)

-- 4. Agar account mavjud bo‘lmasa
--    'NOT_FOUND' qaytarish

-- 5. Agar account status <> 'active'
--    'UNSAFE' qaytarish

-- 6. Agar risk_level = 'HIGH'
--    'UNSAFE' qaytarish

-- 7. Agar risk_level = 'MEDIUM'
--    'WARNING' qaytarish

-- 8. Agar account active va risk_level = 'LOW'
--    'SAFE' qaytarish

-- RETURN:
-- NVARCHAR(20)
create function get_account_status_safe(@account_id int )
returns nvarchar(20)
as begin 

declare @status nvarchar(20);
declare @risk_level nvarchar(10);
declare @is_safe nvarchar(20);

select @status =status from accounts where id = @account_id;

set @risk_level= coalesce(dbo.predict_risk_level(@account_id),'HIGH')


if @status is null
set @is_safe='NOT_FOUND';
else if @status<>'active'
set @is_safe='UNSAFE';
else if @risk_level='HIGH'
set @is_safe='UNSAFE';
ELSE if @risk_level='MEDIUM'
set @is_safe='WARNING';
else set @is_safe ='SAFE';

return @is_safe;
end ;

-- ---

-- ## PROCEDURE (51-75)

-- TASK 51 — safe_transfer_money PROCEDURE (TEMPLATE)

-- PARAMETER
-- @from_account_id INT
-- @to_account_id INT
-- @amount DECIMAL(12,2)
-- DECLARE
-- @from_balance DECIMAL(12,2)
-- 1. from_account mavjudligini tekshirish
-- 2. to_account mavjudligini tekshirish
-- 3. ikkala account active ekanini tekshirish
-- 4. Amount > 0 validation qilish
-- 5. Transaction boshlash
-- 6. from_account balance ni olish
-- 7. balance yetarliligini tekshirish
-- 8. same account transfer tekshirish
-- 9. from_account balance dan amount ayirish
-- 10. to_account balance ga amount qo‘shish
-- 11. transactions table ga log yozish (debit/credit)
-- 12. Commit qilish
-- 13. Xatolik bo‘lsa rollback qilish
-- 14. THROW qaytarish

create procedure safe_transfer_money_account (@from int, @to int, @amount decimal(12,2))
as begin 
declare @from_balance decimal(12,2);
begin try  BEGIN TRAN;

if not exists (select 1 from accounts where id=@from )
throw 50001, N'From account mavjud emas', 1;

if  exists (select 1 from accounts where id=@from and status<>'active')
throw 50002, N'Active account mavjud emas', 1;

if not exists (select 1 from accounts where id=@to )
throw 50003, N'To account mavjud emas', 1;

if  exists (select 1 from accounts where id=@to and status<>'active')
throw 50004, N'Active account mavjud emas', 1;

if @amount<=0 
throw 50005, N'Mablag` notog`ri', 1;


select @from_balance=balance from accounts where id = @from;

if @from_balance<@amount 
throw 50006, N'Balance yetarli emas',1;

if @from=@to 
throw 50007, N'O`ziga transfer qilish mumkin emas', 1;

update accounts set balance=balance-@amount
where id = @from;

update accounts set balance = balance+@amount
where id =@to;

insert into transactions(from_account_id, to_account_id, type, status, amount) values 
(@from, @to, 'transfer', 'success', @amount);

commit 
end try 
begin catch 
rollback;
throw;
end catch 
end ;


exec safe_transfer_money_account 52,54,1321


select * from accounts
where status='active'


select * from transactions
order by id desc



-- TASK 52 — safe_withdraw PROCEDURE
-- Создать PROCEDURE:
-- * xavfsiz pul yechish (withdraw)
-- * balance check + rollback safety

-- PARAMETER
-- @account_id INT
-- @amount DECIMAL(12,2)

-- DECLARE
-- @balance DECIMAL(12,2)

-- 1. Account mavjudligini tekshirish (accounts table)
-- 2. Account active ekanini tekshirish
-- 3. @amount > 0 validation

-- 4. BEGIN TRANSACTION

-- 5. Account balance ni olish

-- 6. Balance yetarliligini tekshirish
--    (balance < amount → ERROR)

-- 7. Balance dan amount ayirish (withdraw)

-- 8. transactions table ga log yozish:
--    type = 'withdraw'
--    status = 'success'
--    account_id = @account_id
--    amount = @amount

-- 9. COMMIT qilish

-- 10. Xatolik bo‘lsa ROLLBACK qilish

-- 11. THROW orqali error qaytarish


create procedure safe_withdraw (@from int, @amount decimal(12,2)) 
as begin 
declare @balance decimal(12,2);
begin try
begin tran;

if not exists(select 1 from accounts where id = @from) 
throw 50001, N'Account mavjud emas',1;


if exists (select 1 from accounts where id = @from and status<>'active')
throw 50002, N'Active account mavjud emas', 1;

select @balance=balance from accounts where id=@from;

if @balance<@amount 
throw 50003, N'Balance yetarli emas',1;


update accounts set balance =  balance-@amount
where id =@from;

insert into transactions (from_account_id, to_account_id, type, status, amount) values 
(@from, null, 'withdraw', 'success', @amount)

commit;
end try
begin catch 
rollback;
throw;
end catch 
end;





-- TASK 53 — safe_deposit PROCEDURE
-- Создать PROCEDURE:
-- * пополнение счета

create procedure safe_deposit_balance(@to int, @amount decimal(12,2))
as begin 
declare @balance decimal(12,2);
begin try begin tran;

if not exists (select 1 from accounts where id = @to)
throw 50001, N'To account mavjud emas ekan', 1;

if not exists (select 1 from accounts where id =@to and status='active')
throw 50002,N'Active account mavjud emas', 1;

select @balance=balance from accounts where id =@to;

if @balance<@amount 
throw 50003, N'Balance yetarli emas', 1;

update accounts set balance=balance+@amount
where id = @to;

insert into transactions(from_account_id, to_account_id, type,status, amount) values 
(null, @to,'deposit', 'success', @amount);
commit;
end try 
begin catch 
rollback;
throw;
end catch
end;



select type, count(*) from transactions
group by type



-- TASK 54 — generate_statement PROCEDURE
-- Создать PROCEDURE:
-- * выписка по счету

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @exists BIT

-- 1. Account mavjudligini tekshirish
-- 2. Account active ekanini tekshirish
-- 3. Account yo‘qligini THROW qilish

-- 4. transactions table’dan ma’lumot olish

-- 5. WHERE:
--    from_account_id = @account_id
--    OR to_account_id = @account_id

-- 6. SELECT columns:
--    transaction_id
--    from_account_id
--    to_account_id
--    type
--    amount
--    status
--    created_at

-- 7. ORDER BY created_at DESC

-- 8. RETURN result set

-- 9. TRY / CATCH:
--    rollback + throw


create procedure generate_statement(@account_id int)
as begin 
declare @exists bit ;
begin try 

if not exists (select 1 from accounts where id = @account_id) 
throw 50001, N'Account mavjud emas', 1;
if not exists (select 1 from accounts where id=@account_id and status='active')
throw 50002, N'Active account emas', 1;

select from_account_id, to_account_id, type, amount, status, created_at from transactions where from_account_id=@account_id or to_account_id=@account_id
order by created_at desc;
end try 

begin catch 
throw;
end catch 
end;

-- TASK 55 — rollback_transaction PROCEDURE
-- Создать PROCEDURE:
-- * откат транзакции
-- PARAMETER
-- @transaction_id INT
-- DECLARE
-- @from_account_id INT
-- @to_account_id INT
-- @amount DECIMAL(12,2)
-- @type NVARCHAR(20)
-- @status NVARCHAR(20)
-- 1. transaction mavjudligini tekshirish (transactions table)
-- 2. transaction ma’lumotlarini olish: from_account_id, to_account_id, amount, type, status
-- 3. agar transaction topilmasa THROW 'Transaction not found'
-- 4. transaction type bo‘yicha rollback:
-- transfer: from_account + amount, to_account - amount
-- deposit: to_account - amount
-- withdraw: from_account + amount
-- 5. accounts table update qilish
-- 6. transactions table ga log yozish: type='rollback', status='reversed'
-- 7. COMMIT
-- 8. ERROR bo‘lsa ROLLBACK

create procedure rollback_transaction(@transaction_id int) 
as begin 
declare @from int;
declare @to int;
declare @amount decimal(12,2);
declare @type nvarchar(20);
declare @status nvarchar(20);

begin try begin tran;

if not exists (select 1 from transactions where id = @transaction_id)
throw 50001, N'Tx mavjud emas', 1;

select from_account_id=@from, to_account_id=@to, type=@type, status=@status, amount=@amount from transactions where id = @transaction_id;







-- TASK 56 — freeze_account PROCEDURE
-- Создать PROCEDURE:
-- * заморозка счета

create procedure frezee_account (@account_id int) 
as begin 
declare @status nvarchar(20);
begin try begin tran;


if not exists (select 1 from accounts where id=@account_id) 
throw 50001, N'Not found account', 1;




select @status=status from accounts where id =@account_id;

if @status='closed'
throw 50002, N'Cannot freeze acoount',1;

if @status='frozen'
throw 50003, N'Account alredy frozen',1;


update accounts set status='frozen'
where id =@account_id;

commit;

end try 
begin catch 
rollback;
throw;
end catch 
end;









-- TASK 57 — unfreeze_account PROCEDURE
-- Создать PROCEDURE:
-- * разблокировка счета

-- PARAMETER
-- @account_id INT

-- DECLARE
-- @status NVARCHAR(20)

-- 1. Account mavjudligini tekshirish (accounts table)

-- 2. Agar account topilmasa:
--    THROW 'Account not found'

-- 3. Account status olish

-- 4. Agar account status = 'closed':
--    THROW 'Cannot unfreeze closed account'

-- 5. Agar account status <> 'frozen':
--    THROW 'Only frozen accounts can be unfreezed'

-- 6. Account ni unfreeze qilish:
--    status = 'active'

-- 7. accounts table update qilish

-- 8. transactions table ga log yozish:
--    type = 'unfreeze'
--    status = 'success'
--    amount = 0

-- 9. COMMIT

-- 10. ERROR bo‘lsa ROLLBACK


create procedure unfreze_account (@account_id int)
as begin 
declare @status nvarchar(20);

begin try begin tran;


if not exists (select 1 from accounts where id=@account_id) 
throw 50001, N'Not found account', 1;


select @status=status from accounts where id =@account_id;

if @status='closed'
throw 50002, N'Cannot freeze acoount',1;

if @status<>'frozen'
throw 50003, N'Only frozen accounts can be unfreezed',1;

update accounts set status='active' where id=@account_id;

commit;

end try begin catch rollback;throw;end catch end;

exec unfreze_account 23


select id, status from accounts





-- TASK 58 — create_loan PROCEDURE
-- Создать PROCEDURE:
-- * создание кредита


-- PARAMETER
-- @customer_id INT
-- @amount DECIMAL(12,2)


-- DECLARE
-- @loan_id INT


-- 1. Customer mavjudligini tekshirish
-- 2. Customer uchun active loan mavjudligini tekshirish

-- 3. Amount > 0 validation qilish

-- 4. Transaction boshlash

-- 5. loans table ga yangi kredit yozish
--    customer_id = @customer_id
--    amount = @amount
--    status = default active

-- 6. Yaratilgan loan_id olish

-- 7. Commit qilish

-- 8. Xatolik bo‘lsa rollback qilish

-- 9. THROW qaytarish


create procedure add_loans (@customer_id int, @amount decimal(12,2))
as begin 
declare @loan_id int;

begin try begin tran;

if not exists (select 1 from customers where id =@customer_id) throw 50001, N'Not found  customer',1;

if exists (select 1 from loans where status='active' and customer_id=@customer_id) throw 50002, N'Loan alredy active', 1;

if @amount<=0
throw 50003,N'Amount incorrect', 1;


insert into loans (customer_id, status, amount) values
(@customer_id, 'active', @amount);

commit; end try begin catch rollback;throw; end catch end;


drop procedure add_loans

exec add_loans 25, 1

select * from loans
where id =25

update loans set amount=amount+100 where id =25



-- TASK 59 — repay_loan PROCEDURE
-- Создать PROCEDURE:
-- * погашение кредита

-- PARAMETER
-- @loan_id INT
-- @amount DECIMAL(12,2)

-- DECLARE
-- @loan_amount DECIMAL(12,2)
-- @loan_status NVARCHAR(20)

-- 1. Loan mavjudligini tekshirish
-- 2. Loan active ekanini tekshirish
-- 3. Amount > 0 validation qilish
-- 4. Transaction boshlash
-- 5. Loan amount ni olish
-- 6. To‘lov summasi kredit summasidan oshib ketmasligini tekshirish
-- 7. Loan amount dan to‘lov summasini ayirish
-- 8. Agar amount 0 bo‘lsa loan status = 'closed' qilish
-- 9. Commit qilish
-- 10. Xatolik bo‘lsa rollback qilish
-- 11. THROW qaytarish

create procedure reppay_loan (@loan_id int, @amount decimal(12,2))
as begin 
declare @loan_amount decimal(12,2);

begin try begin tran;

if not exists (select 1 from loans where id = @loan_id ) 
throw 50001, N'Loan not found', 1;

if not exists (select 1 from loans where status='active' and id=@loan_id)
throw 50002, N'Loan is bot active', 1;

if @amount<=0 
throw 50003, N'Amount incorrect', 1;

select @loan_amount=amount from loans where id=@loan_id;

if @loan_amount<@amount
throw 50004, N'Balance incorrect', 1; 


update loans set amount=amount-@amount
where id = @loan_id;

if @loan_amount-@amount=0 
begin 

update loans set status='closed' where id =@loan_id;
end
commit;

end try begin catch rollback; throw; end catch end;





/*-- TASK 60 — add_beneficiary PROCEDURE
-- Создать PROCEDURE:
-- * добавление получателя
-- PARAMETER
-- @customer_id INT
-- @beneficiary_account_id INT
-- @nickname NVARCHAR(50)
-- DECLARE
-- @account_status NVARCHAR(20)
-- 1. Customer mavjudligini tekshirish
-- 2. Beneficiary account mavjudligini tekshirish
-- 3. Beneficiary account active ekanini tekshirish
-- 4. Customer o‘z accountini beneficiary sifatida qo‘shmayotganini tekshirish
-- 5. Transaction boshlash
-- 6. Beneficiary oldin qo‘shilganligini tekshirish
-- 7. Beneficiary account statusini olish
-- 8. Status='active' ekanini tekshirish
-- 9. Beneficiary ni qo‘shish
-- 10. Commit qilish
-- 11. Xatolik bo‘lsa rollback qilish
-- 12. THROW qaytarish
*/

create procedure add_beneficiary (@customer_id int, @beneficiary_account_id int, @nickname nvarchar(50)) 
as begin 
declare @account_status nvarchar(20)
begin try begin tran;

if not exists (select 1 from customers where id =@customer_id)
throw 50001, N'Customer not found', 1;

if not exists (select 1 from accounts where id =@beneficiary_account_id)
throw 50002,N'Account not found', 1;

if not exists (select 1 from accounts where id =@beneficiary_account_id and status='active')
throw 50003, N'Account is not active', 1;

if exists (select 1 from accounts where id = @beneficiary_account_id and customer_id =@customer_id )
throw 50004, N'Cannot add own account as benefiaciary', 1;

if EXISTS(SELECT 1 from beneficiaries where beneficiary_account_id =@beneficiary_account_id and customer_id = @customer_id)
throw 50005, N'Benefiary alredy exists', 1;

select @account_status=status from accounts where id = @beneficiary_account_id

insert into beneficiaries(customer_id, beneficiary_account_id, nickname) values 
(@customer_id, @beneficiary_account_id, @nickname);

commit;
end try begin catch rollback;throw;end catch end;





-- TASK 61 — safe_card_creation PROCEDURE
-- Создать PROCEDURE:
-- * создание карты




-- TASK 62 — smart_transfer_with_risk_check PROCEDURE
-- Создать PROCEDURE:
-- * перевод только при низком риске

-- TASK 63 — adaptive_withdraw_limit PROCEDURE
-- Создать PROCEDURE:
-- * динамический лимит снятия

-- TASK 64 — risk_based_account_block PROCEDURE
-- Создать PROCEDURE:
-- * автоматическая блокировка на основе скора

-- TASK 65 — account_reputation_update PROCEDURE
-- Создать PROCEDURE:
-- * обновление репутационного скора

-- TASK 66 — fraud_case_creation PROCEDURE
-- Создать PROCEDURE:
-- * создание дела для расследования

-- TASK 67 — smart_deposit_validation PROCEDURE
-- Создать PROCEDURE:
-- * правила валидации пополнения

-- TASK 68 — emergency_fund_lock PROCEDURE
-- Создать PROCEDURE:
-- * заморозка средств при кризисе

-- TASK 69 — account_recovery_engine PROCEDURE
-- Создать PROCEDURE:
-- * восстановление подозрительных счетов

-- TASK 70 — transaction_reconciliation PROCEDURE
-- Создать PROCEDURE:
-- * исправление несоответствий балансов

-- TASK 71 — customer_risk_recalculation PROCEDURE
-- Создать PROCEDURE:
-- * полный пересчет рисков

-- TASK 72 — emergency_lockdown PROCEDURE
-- Создать PROCEDURE:
-- * аварийная блокировка

-- TASK 73 — batch_settlement PROCEDURE
-- Создать PROCEDURE:
-- * массовые операции

-- TASK 74 — reconcile_accounts PROCEDURE
-- Создать PROCEDURE:
-- * сверка счетов

-- TASK 75 — fraud_report_generator PROCEDURE
-- Создать PROCEDURE:
-- * отчет по fraud

-- ---

-- ## TRIGGER (76-100)

-- TASK 76 — Prevent negative balance trigger
-- Создать TRIGGER:
-- * баланс < 0 запрет

-- TASK 77 — Prevent self transfer trigger
-- Создать TRIGGER:
-- * перевод самому себе

-- TASK 78 — Audit log trigger
-- Создать TRIGGER:
-- * лог всех операций

-- TASK 79 — Fraud alert trigger
-- Создать TRIGGER:
-- * fraud alerts

-- TASK 80 — Data integrity check trigger
-- Создать TRIGGER:
-- * проверка целостности данных

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
-- * просрочка кредита


 