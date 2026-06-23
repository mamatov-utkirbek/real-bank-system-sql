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

select n.customer_id, count(n.id), sum(case when n.is_read=1 then 1 else 0 end )read_notifacation , 
coalesce(sum(case when n.is_read=1 then 1 else 0 end ), 0)*100.0/nullif(COUNT(n.id),0), 0 from notifications n
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


select c.id, c.full_name,count(t.id )  count_tx, case when count(t.id)>0 then 'active' else 'inactive' end status_customer, max(t.created_at) last_tx
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
-- * возраст счета в днях

-- TASK 27 — get_customer_loan_count FUNCTION
-- Создать FUNCTION:
-- * количество кредитов у клиента

-- TASK 28 — calculate_total_fraud_alerts FUNCTION
-- Создать FUNCTION:
-- * общее количество fraud алертов по счету

-- TASK 29 — get_account_transaction_count FUNCTION
-- Создать FUNCTION:
-- * количество транзакций по счету

-- TASK 30 — calculate_balance_change_rate FUNCTION
-- Создать FUNCTION:
-- * скорость изменения баланса

-- TASK 31 — get_customer_notification_count FUNCTION
-- Создать FUNCTION:
-- * количество уведомлений у клиента

-- TASK 32 — calculate_auth_fail_rate FUNCTION
-- Создать FUNCTION:
-- * процент неудачных входов

-- TASK 33 — get_loan_payment_count FUNCTION
-- Создать FUNCTION:
-- * количество платежей по кредиту

-- TASK 34 — calculate_card_expiry_days FUNCTION
-- Создать FUNCTION:
-- * дней до истечения карты

-- TASK 35 — get_beneficiary_count FUNCTION
-- Создать FUNCTION:
-- * количество получателей у клиента

-- TASK 36 — calculate_daily_avg_balance FUNCTION
-- Создать FUNCTION:
-- * средний дневной баланс

-- TASK 37 — get_freeze_duration FUNCTION
-- Создать FUNCTION:
-- * продолжительность заморозки

-- TASK 38 — calculate_transaction_success_rate FUNCTION
-- Создать FUNCTION:
-- * процент успешных транзакций

-- TASK 39 — get_customer_accounts_count FUNCTION
-- Создать FUNCTION:
-- * количество счетов у клиента

-- TASK 40 — calculate_risk_trend FUNCTION
-- Создать FUNCTION:
-- * тренд изменения risk_score

-- TASK 41 — get_currency_balance FUNCTION
-- Создать FUNCTION:
-- * баланс по валюте

-- TASK 42 — calculate_loan_utilization FUNCTION
-- Создать FUNCTION:
-- * использование кредитного лимита

-- TASK 43 — get_fraud_severity_level FUNCTION
-- Создать FUNCTION:
-- * уровень серьезности fraud

-- TASK 44 — calculate_account_health_index FUNCTION
-- Создать FUNCTION:
-- * индекс здоровья счета

-- TASK 45 — get_device_usage_count FUNCTION
-- Создать FUNCTION:
-- * количество использований устройства

-- TASK 46 — calculate_login_frequency FUNCTION
-- Создать FUNCTION:
-- * частота входов в систему

-- TASK 47 — get_customer_risk_level FUNCTION
-- Создать FUNCTION:
-- * уровень риска (LOW/MEDIUM/HIGH)

-- TASK 48 — calculate_balance_growth_rate FUNCTION
-- Создать FUNCTION:
-- * темп роста баланса

-- TASK 49 — get_notification_read_rate FUNCTION
-- Создать FUNCTION:
-- * процент прочитанных уведомлений

-- TASK 50 — calculate_account_score FUNCTION
-- Создать FUNCTION:
-- * общий счет аккаунта


-- ============================================================
-- PROCEDURE (51-75)
-- ============================================================

-- TASK 51 — update_account_status PROCEDURE
-- Создать PROCEDURE:
-- * обновление статуса счета

-- TASK 52 — add_fraud_alert PROCEDURE
-- Создать PROCEDURE:
-- * добавление fraud алерта

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