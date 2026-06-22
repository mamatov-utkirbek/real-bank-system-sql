

CREATE DATABASE RealBankSystem;

use RealBankSystem;


create table customers (
id int identity(1,1) primary key,
full_name nvarchar(120) not null,
phone nvarchar(20) not null,
email nvarchar(120) not null,
address nvarchar(max),
risk_score int default 0,
created_at datetime2 default getdate(),
);



create table accounts (
id int identity(1, 1) primary key,
customer_id int not null,
balance decimal(12,2) not null default 0,
status nvarchar(20) default N'active',
currency nvarchar(3) not null default N'USD',
fail_count int default 0,
created_at datetime2 default getdate(),
update_at datetime2 default getdate(),
constraint fk_accounts_customer foreign key (customer_id) references customers(id) on delete cascade,
constraint chk_accounts_balance check(balance>=0),
constraint chk_accounts_status check(status in(N'active', N'frozen', N'closed', N'blocked', N'dormant', N'pending'))
);


DROP TABLE IF EXISTS transactions;


create table transactions (
id int identity(1,1) primary key,
type nvarchar(20) not null ,
amount decimal(12,2) not null,
from_account_id int ,
to_account_id int,
status nvarchar(20) default N'success',
created_at datetime2 default getdate(),
constraint fk_transactions_from_account foreign key(from_account_id) references accounts(id),
constraint fk_transactions_to_account foreign key(to_account_id) references accounts(id),
constraint chk_transactions_type check(type in(N'deposit', N'credit', N'loan')),
constraint chk_transactions_status check( status in (N'success', N'failed', N'pending' )),
constraint chk_transactions_amount check(amount>=0)
);

alter table transactions --drop CONSTRAINT chk_transactions_type

add constraint chk_transactions_type CHECK (type IN ('deposit','credit','loan','transfer','withdraw'))


ALTER TABLE transactions DROP CONSTRAINT chk_transactions_status;

ALTER TABLE transactions ADD CONSTRAINT chk_transactions_status CHECK ( status IN ( N'success', N'failed', N'pending', N'reversed' ) );

SELECT * from transactions
where type ='credit'



use RealBankSystem

ALTER TABLE transactions DROP CONSTRAINT chk_transactions_status;
ALTER TABLE transactions DROP CONSTRAINT chk_transactions_type;



ALTER TABLE transactions ADD CONSTRAINT chk_transactions_status CHECK (status IN (N'success', N'failed', N'pending'));
ALTER TABLE transactions ADD CONSTRAINT chk_transactions_type CHECK (type IN (N'deposit', N'credit', N'loan', N'transfer'));


create table ledger_entries (
id int identity(1,1) primary key,
transaction_id int not null,
account_id int not null,
entry_type nvarchar(10) not null,
amount decimal(12,2) not null,
created_at datetime2 default getdate(),

constraint fk_ledger_transaction foreign key(transaction_id) references transactions (id),
constraint fk_ledger_account foreign key (account_id) references accounts (id),
constraint chk_ledger_entry_type check( entry_type in (N'debit', N'credit')),
constraint chk_ledger_amount check(amount>0) 
);

create table loans(
id int identity(1,1) primary key,
customer_id int not null,
amount decimal(12,2) not null,
status nvarchar(20) DEFAULT N'active',
created_at datetime2 default getdate(),
constraint fk_loans_customer foreign key (customer_id) references customers(id),
constraint chk_loans_status check(status in (N'active', N'closed'))
);

CREATE TABLE loan_payments ( 
    id int IDENTITY(1,1) PRIMARY KEY,
    loan_id int NOT NULL,
    amount decimal(12,2) NOT NULL,
    created_at datetime2 DEFAULT getdate(),
    CONSTRAINT fk_loan_payments_loan FOREIGN KEY (loan_id) REFERENCES loans(id),
    CONSTRAINT chk_loan_payments_amount CHECK (amount > 0)
)

create table cards (
id int identity(1,1) primary key,
account_id int not null,
status NVARCHAR(20) default N'active',
card_number nvarchar(16) not null unique, 
expiry_date date not null,
created_at datetime2 default getdate(),
constraint fk_cards_account foreign key (account_id) references accounts(id),
CONSTRAINT chk_cards_status check ( status in (N'active', N'blocked', N'expired'))
)


alter table cards 
alter column card_number nvarchar(20) not null

CREATE TABLE beneficiaries (
id int identity(1,1) primary key,
customer_id int not null,
beneficiary_account_id int not null,
nickname nvarchar(50) not null,
created_at datetime2 default getdate(),
constraint fk_beneficiaries_customer foreign key (customer_id) references customers(id),
constraint fk_beneficiaries_account foreign key (beneficiary_account_id) references accounts(id)
)



SELECT * FROM beneficiaries 


create table account_freeze (
id int identity(1,1) primary key,
account_id int not null,
reason nvarchar(max) not null, 
frozen_at datetime2 default getdate(),
unfrozen_at datetime2,
constraint fk_account_freeze_account foreign key (account_id) references accounts(id)
)


create table failed_transactions (
id int identity(1,1) primary key,
from_account_id int not null,
to_account_id int not null,
amount decimal(12,2) not null,
error_message nvarchar(max) ,
created_at datetime2 default getdate(), 
customer_id int,
constraint fk_failed_transactions_customer foreign key (customer_id) references customers(id),
)


create table audit_logs (
id int identity(1,1) primary key, 
transaction_id int not null,
from_account_id int,
to_account_id int,
customer_id int,
amount decimal(12,2) not null,
action_type nvarchar(20) not null,
details nvarchar(max),
created_at datetime2  default getdate(),
constraint fk_audit_transaction foreign key(transaction_id) references transactions(id) on delete cascade,
CONSTRAINT fk_audit_customer_ FOREIGN key (customer_id) references customers(id) on delete set null,
constraint chk_audit_action check(action_type in(N'loan', N'deposit', N'transfer')) ,
constraint chk_audit_amoun check(amount>=0)
)


create TABLE risk_scores (
id int identity(1,1) primary key,
customer_id int not null,
score int not null,
updated_at datetime2 default getdate(),
constraint fk_risk_scores_customer foreign key (customer_id) references customers(id) on delete cascade,
CONSTRAINT chk_risk_scores_score check(score between 0 and 100)
)

create table fraud_alerts (
id int identity(1,1) primary key,           
account_id int not null,
alert_type nvarchar(20) not null,
severity int,
created_at datetime2 default getdate(),
constraint fk_fraud_alerts_account foreign key (account_id) references accounts(id),
CONSTRAINT chk_fraud_alerts_type check(alert_type in(N'suspicios_amount', N'rapid_transactions', N'multiple_failed_logins', N'usual_location', N'new_device_login', N'vilocity_check', N'blacklist_ip',N'card_not_present', N'hogh_risk_country', N'account_takeover')))

alter table fraud_alerts
alter column alert_type nvarchar(50) not null
SELECT * from fraud_alerts

EXEC sp_rename 'dbo.fraud_alerts.severty', 'severity', 'COLUMN';

select * from fraud_alerts


create table login_history (
id int identity(1,1) primary key,
customer_id int not null,
ip_address nvarchar(45) not null,
device NVARCHAR(MAX) not null,
created_at datetime2 default getdate(),
constraint fk_login_history_customer foreign key (customer_id) references customers(id)
)

create table notifications (
id int identity(1,1) primary key,
customer_id int not null,
message nvarchar(max) not null,
is_read bit default 0,
created_at datetime2 default getdate(),
constraint fk_notifications_customer foreign key (customer_id) references customers(id)
)














insert into customers (full_name, phone, email, address, risk_score)
values
('Ali Valiyev', '+992901110001', 'ali.valiyev1@mail.com', 'Dushanbe, Rudaki 12', 12),
('Sohib Rahmonov', '+992901110002', 'sohib.rahmonov@mail.com', 'Khujand, Somoni 5', 22),
('Farid Karimov', '+992901110003', 'farid.karimov@mail.com', 'Dushanbe, Sino', 18),
('Malika Umarova', '+992901110004', 'malika.umarova@mail.com', 'Bokhtar, Center', 7),
('Jamshed Saidov', '+992901110005', 'jamshed.saidov@mail.com', 'Kulob, Vose', 30),
('Dilnoza Rakhimova', '+992901110006', 'dilnoza.rakhimova@mail.com', 'Dushanbe, Yakkachinor', 9),
('Rustam Nazarov', '+992901110007', 'rustam.nazarov@mail.com', 'Khujand, 34 mkr', 15),
('Shabnam Mirzoeva', '+992901110008', 'shabnam.mirzoeva@mail.com', 'Dushanbe, Firdavsi', 11),
('Bakhtiyor Gafurov', '+992901110009', 'bakhtiyor.gafurov@mail.com', 'Istaravshan, Center', 25),
('Madina Sharipova', '+992901110010', 'madina.sharipova@mail.com', 'Dushanbe, Sino 10', 14),

('Navruz Khurshedov', '+992901110011', 'navruz.khurshedov@mail.com', 'Khujand, Buston', 19),
('Zarina Ismailova', '+992901110012', 'zarina.ismailova@mail.com', 'Dushanbe, Rudaki', 8),
('Kamoliddin Yusufov', '+992901110013', 'kamol.yusufov@mail.com', 'Kulob, Center', 27),
('Gulnoza Shodieva', '+992901110014', 'gulnoza.shodieva@mail.com', 'Dushanbe, Sino 5', 10),
('Firdavs Akramov', '+992901110015', 'firdavs.akramov@mail.com', 'Khujand, 20 mkr', 16),
('Munira Habibova', '+992901110016', 'munira.habibova@mail.com', 'Bokhtar, Street 3', 6),
('Shahrom Yodgorov', '+992901110017', 'shahrom.yodgorov@mail.com', 'Dushanbe, Rudaki 2', 21),
('Aziza Qodirova', '+992901110018', 'aziza.qodirova@mail.com', 'Khujand, Center', 5),
('Dilshod Ganiev', '+992901110019', 'dilshod.ganiev@mail.com', 'Dushanbe, 102 mkr', 28),
('Nilufar Tursunova', '+992901110020', 'nilufar.tursunova@mail.com', 'Kulob, Vose', 13),

('Sherzod Kholikov', '+992901110021', 'sherzod.kholikov@mail.com', 'Dushanbe, Sino 3', 17),
('Malohat Rasulova', '+992901110022', 'malohat.rasulova@mail.com', 'Khujand, Somoni 2', 9),
('Javlon Karimov', '+992901110023', 'javlon.karimov@mail.com', 'Bokhtar, Center', 23),
('Madina Rakhmonova', '+992901110024', 'madina.rakhmonova@mail.com', 'Dushanbe, Rudaki 7', 12),
('Sardor Komilov', '+992901110025', 'sardor.komilov@mail.com', 'Khujand, 12 mkr', 20),
('Gulbahor Saidova', '+992901110026', 'gulbahor.saidova@mail.com', 'Dushanbe, Firdavsi', 5),
('Rustam Murodov', '+992901110027', 'rustam.murodov@mail.com', 'Kulob, Center 2', 24),
('Shahnoza Abdurozikova', '+992901110028', 'shahnoza.abdurozikova@mail.com', 'Dushanbe, Yakkachinor', 10),
('Farrukh Makhmudov', '+992901110029', 'farrukh.makhmudov@mail.com', 'Khujand, Buston', 26),
('Zuhra Rasulova', '+992901110030', 'zuhra.rasulova@mail.com', 'Bokhtar, Street 5', 8),

('Jahongir Safarov', '+992901110031', 'jahongir.safarov@mail.com', 'Dushanbe, Sino', 19),
('Nilufar Umarova', '+992901110032', 'nilufar.umarova@mail.com', 'Khujand, Center', 11),
('Kamron Gafurov', '+992901110033', 'kamron.gafurov@mail.com', 'Dushanbe, Rudaki', 22),
('Shabnam Akhmedova', '+992901110034', 'shabnam.akhmedova@mail.com', 'Kulob, Vose', 7),
('Dilshod Yuldoshev', '+992901110035', 'dilshod.yuldoshev@mail.com', 'Khujand, 5 mkr', 18),
('Malika Qodirova', '+992901110036', 'malika.qodirova@mail.com', 'Dushanbe, Somoni', 13),
('Sardor Tursunov', '+992901110037', 'sardor.tursunov@mail.com', 'Bokhtar, Center', 27),
('Aziza Karimova', '+992901110038', 'aziza.karimova@mail.com', 'Dushanbe, Sino 8', 6),
('Rustam Saidov', '+992901110039', 'rustam.saidov@mail.com', 'Khujand, Buston 4', 21),
('Madina Ganieva', '+992901110040', 'madina.ganieva@mail.com', 'Dushanbe, Firdavsi', 10),

('Navruz Yusupov', '+992901110041', 'navruz.yusupov@mail.com', 'Kulob, Center', 15),
('Shahnoza Mirzoeva', '+992901110042', 'shahnoza.mirzoeva@mail.com', 'Khujand, Somoni', 9),
('Farrukh Saidov', '+992901110043', 'farrukh.saidov@mail.com', 'Dushanbe, Rudaki 15', 23),
('Zarina Karimova', '+992901110044', 'zarina.karimova@mail.com', 'Bokhtar, Street', 8),
('Jamshed Rahmonov', '+992901110045', 'jamshed.rahmonov@mail.com', 'Dushanbe, Sino 12', 29),
('Malika Habibova', '+992901110046', 'malika.habibova@mail.com', 'Khujand, Center', 12),
('Sherzod Nazarov', '+992901110047', 'sherzod.nazarov@mail.com', 'Dushanbe, Somoni', 17),
('Gulnoza Karimova', '+992901110048', 'gulnoza.karimova@mail.com', 'Kulob, Vose', 5),
('Dilnoza Rasulova', '+992901110049', 'dilnoza.rasulova@mail.com', 'Khujand, Buston', 14),
('Bakhtiyor Yodgorov', '+992901110050', 'bakhtiyor.yodgorov@mail.com', 'Dushanbe, Firdavsi', 25),

('Anvar Tursunov', '+992901110051', 'anvar.tursunov@mail.com', 'Khujand, Center 2', 16),
('Mavluda Karimova', '+992901110052', 'mavluda.karimova@mail.com', 'Dushanbe, Sino', 7),
('Fayzullo Gafurov', '+992901110053', 'fayzullo.gafurov@mail.com', 'Kulob, Vose 3', 20),
('Shahlo Mirzoeva', '+992901110054', 'shahlo.mirzoeva@mail.com', 'Bokhtar, Center', 9),
('Rustam Qodirov', '+992901110055', 'rustam.qodirov@mail.com', 'Dushanbe, Rudaki', 18),
('Nilufar Saidova', '+992901110056', 'nilufar.saidova@mail.com', 'Khujand, Somoni', 11),
('Javohir Nazarov', '+992901110057', 'javohir.nazarov@mail.com', 'Dushanbe, Yakkachinor', 24),
('Madina Tursunova', '+992901110058', 'madina.tursunova@mail.com', 'Kulob, Center', 10),
('Sardor Karimov', '+992901110059', 'sardor.karimov@mail.com', 'Khujand, Buston', 22),
('Aziza Rahmonova', '+992901110060', 'aziza.rahmonova@mail.com', 'Dushanbe, Sino', 6);


SELECT * from accounts




INSERT INTO accounts (customer_id, balance, status, currency, fail_count, created_at, update_at)
VALUES
(1, 1500.00, 'active', 'USD', 0, '2024-01-15 10:30:00', '2024-01-15 10:30:00'),
(2, 2500.50, 'active', 'USD', 0, '2024-01-20 14:45:00', '2024-02-10 09:20:00'),
(3, 5000.75, 'frozen', 'EUR', 1, '2023-11-05 08:15:00', '2024-03-01 16:30:00'),
(4, 3200.00, 'active', 'EUR', 0, '2024-02-01 11:00:00', '2024-02-01 11:00:00'),
(5, 10000.00, 'active', 'GBP', 0, '2023-09-10 09:45:00', '2024-01-25 13:20:00'),
(6, 750.25, 'dormant', 'UZS', 0, '2023-12-20 16:20:00', '2023-12-20 16:20:00'),
(7, 8900.00, 'active', 'RUB', 0, '2024-01-05 12:10:00', '2024-02-18 10:15:00'),
(8, 4300.30, 'blocked', 'KZT', 3, '2023-08-15 10:00:00', '2024-03-10 15:45:00'),
(9, 1200.00, 'active', 'USD', 0, '2024-02-10 09:30:00', '2024-02-10 09:30:00'),
(10, 6700.80, 'active', 'EUR', 0, '2023-10-25 14:00:00', '2024-01-30 11:25:00'),
(11, 3400.00, 'pending', 'GBP', 0, '2024-03-01 08:45:00', '2024-03-01 08:45:00'),
(12, 5500.60, 'active', 'UZS', 0, '2023-11-30 13:15:00', '2024-02-20 09:00:00'),
(13, 2800.00, 'closed', 'RUB', 2, '2023-07-10 11:30:00', '2024-01-05 16:40:00'),
(14, 9100.00, 'active', 'KZT', 0, '2024-01-25 15:20:00', '2024-03-05 10:10:00'),
(15, 4700.50, 'active', 'USD', 0, '2023-12-01 10:00:00', '2024-02-25 14:30:00'),
(16, 8200.00, 'frozen', 'EUR', 1, '2023-09-20 09:15:00', '2024-03-12 12:00:00'),
(17, 3600.75, 'active', 'GBP', 0, '2024-02-15 16:45:00', '2024-02-15 16:45:00'),
(18, 12900.00, 'active', 'UZS', 0, '2023-08-05 12:30:00', '2024-01-20 08:50:00'),
(19, 5400.00, 'dormant', 'RUB', 0, '2023-11-12 14:10:00', '2023-11-12 14:10:00'),
(20, 6700.25, 'active', 'KZT', 0, '2024-03-10 11:55:00', '2024-03-10 11:55:00'),
(21, 2100.00, 'active', 'USD', 0, '2024-01-18 13:20:00', '2024-01-18 13:20:00'),
(22, 8300.50, 'active', 'EUR', 0, '2024-02-05 09:45:00', '2024-02-20 14:30:00'),
(23, 1200.75, 'frozen', 'GBP', 2, '2023-10-12 11:10:00', '2024-03-15 10:25:00'),
(24, 6700.00, 'active', 'UZS', 0, '2024-01-28 16:00:00', '2024-01-28 16:00:00'),
(25, 4500.25, 'active', 'RUB', 0, '2023-11-20 08:30:00', '2024-02-28 13:45:00'),
(26, 9800.00, 'dormant', 'KZT', 0, '2023-12-15 14:50:00', '2023-12-15 14:50:00'),
(27, 3400.60, 'active', 'USD', 0, '2024-02-18 10:15:00', '2024-03-08 11:30:00'),
(28, 7200.80, 'blocked', 'EUR', 1, '2023-09-05 09:20:00', '2024-03-18 15:20:00'),
(29, 5600.00, 'active', 'GBP', 0, '2024-03-05 12:40:00', '2024-03-05 12:40:00'),
(30, 1900.50, 'pending', 'UZS', 0, '2023-08-25 15:10:00', '2024-01-15 09:00:00'),
(31, 11000.00, 'active', 'RUB', 0, '2024-02-12 11:25:00', '2024-02-25 16:35:00'),
(32, 4300.00, 'active', 'KZT', 0, '2023-10-30 09:55:00', '2024-03-20 10:50:00'),
(33, 7800.25, 'frozen', 'USD', 1, '2023-11-18 14:30:00', '2024-03-22 13:15:00'),
(34, 2500.75, 'active', 'EUR', 0, '2024-01-10 08:40:00', '2024-01-10 08:40:00'),
(35, 6200.00, 'active', 'GBP', 0, '2023-12-28 16:15:00', '2024-02-05 11:20:00'),
(36, 8900.50, 'dormant', 'UZS', 0, '2023-09-15 10:05:00', '2023-09-15 10:05:00'),
(37, 3700.00, 'active', 'RUB', 0, '2024-03-12 13:30:00', '2024-03-12 13:30:00'),
(38, 15400.00, 'active', 'KZT', 0, '2024-01-22 09:15:00', '2024-03-01 14:40:00'),
(39, 4800.60, 'closed', 'USD', 3, '2023-07-20 12:20:00', '2024-02-18 10:25:00'),
(40, 9300.00, 'active', 'EUR', 0, '2024-02-20 15:45:00', '2024-02-20 15:45:00'),
(41, 2100.25, 'active', 'GBP', 0, '2023-11-08 11:35:00', '2024-01-28 09:50:00'),
(42, 7600.00, 'frozen', 'UZS', 1, '2023-10-02 13:50:00', '2024-03-25 16:10:00'),
(43, 5100.75, 'active', 'RUB', 0, '2024-03-15 08:25:00', '2024-03-15 08:25:00'),
(44, 3450.00, 'pending', 'KZT', 0, '2023-12-10 14:15:00', '2024-02-22 11:55:00'),
(45, 8700.50, 'active', 'USD', 0, '2024-01-30 10:40:00', '2024-03-10 13:20:00'),
(46, 6300.00, 'active', 'EUR', 0, '2023-09-28 09:10:00', '2024-01-12 15:30:00'),
(47, 2900.25, 'blocked', 'GBP', 2, '2023-08-08 16:30:00', '2024-03-28 09:45:00'),
(48, 10500.00, 'active', 'UZS', 0, '2024-02-25 12:00:00', '2024-02-25 12:00:00'),
(49, 4100.00, 'active', 'RUB', 0, '2023-11-25 11:15:00', '2024-03-05 14:55:00'),
(50, 7200.75, 'dormant', 'KZT', 0, '2023-10-15 15:40:00', '2023-10-15 15:40:00'),
(51, 9500.00, 'active', 'USD', 0, '2024-01-05 09:35:00', '2024-02-15 10:05:00'),
(52, 3800.50, 'active', 'EUR', 0, '2023-12-05 13:25:00', '2024-03-18 12:30:00'),
(53, 12500.00, 'frozen', 'GBP', 1, '2023-09-12 10:45:00', '2024-03-30 14:20:00'),
(54, 5600.00, 'active', 'UZS', 0, '2024-03-20 11:50:00', '2024-03-20 11:50:00'),
(55, 8300.25, 'active', 'RUB', 0, '2024-02-08 14:35:00', '2024-03-12 09:15:00'),
(56, 2700.00, 'pending', 'KZT', 0, '2023-10-20 08:55:00', '2024-01-25 15:40:00'),
(57, 6400.75, 'active', 'USD', 0, '2024-03-08 16:20:00', '2024-03-08 16:20:00'),
(58, 11800.00, 'active', 'EUR', 0, '2023-11-15 12:45:00', '2024-02-28 10:35:00'),
(59, 4900.00, 'closed', 'GBP', 2, '2023-08-18 14:10:00', '2024-03-25 11:00:00'),
(60, 7900.50, 'active', 'UZS', 0, '2024-03-25 09:20:00', '2024-03-25 09:20:00');


SELECT * from customers 
select * from accounts


insert into transactions (type, amount, from_account_id, to_account_id, status)
values
('deposit', 120.50, null, 1, 'success'),
('transfer', 4500.75, 3, 15, 'success'),
('transfer', 89.20, 8, 22, 'success'),
('loan', 15000.00, null, 5, 'pending'),
('transfer', 320.10, 11, 2, 'success'),

('transfer', 7800.55, 7, 19, 'success'),
('deposit', 60.00, null, 6, 'success'),
('transfer', 1400.30, 14, 9, 'success'),
('transfer', 999.99, 21, 3, 'failed'),
('transfer', 250.00, 2, 18, 'success'),

('loan', 5000.00, null, 12, 'success'),
('transfer', 670.40, 4, 27, 'success'),
('transfer', 12300.00, 10, 33, 'success'),
('transfer', 45.90, 6, 14, 'success'),
('deposit', 3000.00, null, 8, 'pending'),

('transfer', 880.10, 18, 25, 'success'),
('transfer', 150.25, 30, 1, 'success'),
('transfer', 7600.00, 9, 21, 'success'),
('transfer', 340.80, 5, 16, 'success'),
('transfer', 99.99, 12, 7, 'success'),

('loan', 22000.00, null, 20, 'success'),
('transfer', 430.50, 22, 11, 'success'),
('transfer', 5600.75, 15, 4, 'success'),
('transfer', 120.00, 28, 13, 'success'),
('transfer', 980.90, 19, 26, 'success'),

('deposit', 750.00, null, 10, 'success'),
('transfer', 2100.60, 23, 29, 'success'),
('transfer', 670.10, 31, 17, 'success'),
('transfer', 15000.00, 3, 12, 'success'),
('transfer', 85.75, 27, 6, 'success'),

('loan', 9000.00, null, 14, 'pending'),
('transfer', 340.00, 16, 24, 'success'),
('transfer', 770.25, 20, 8, 'success'),
('transfer', 560.00, 25, 2, 'failed'),
('transfer', 1300.90, 13, 30, 'success'),

('transfer', 45.50, 9, 18, 'success'),
('transfer', 8900.00, 1, 22, 'success'),
('transfer', 120.75, 26, 11, 'success'),
('transfer', 650.40, 7, 28, 'success'),
('deposit', 2000.00, null, 15, 'success');


select * from transactions 
SELECT* FROM accounts

--truncate  table transactions 

DELETE FROM ledger_entries;

DBCC CHECKIDENT ('ledger_entries', RESEED, 0);
--truncate table transactions restart identity cascade;

select * from customers

INSERT INTO transactions (type, amount, from_account_id, to_account_id, status) VALUES
('deposit', 11046.39, 15, 42, 'success'),
('deposit', 16502.00, 8, 33, 'success'),
('deposit', 45975.10, 27, 11, 'success'),
('deposit', 39087.15, 44, 19, 'success'),
('deposit', 44933.12, 3, 56, 'success'),
('loan', 31472.57, 29, 38, 'success'),
('loan', 29135.49, 51, 7, 'pending'),
('loan', 13210.80, 16, 49, 'success'),
('loan', 11153.72, 60, 23, 'success'),
('loan', 9125.10, 35, 14, 'success'),
('transfer', 46237.10, 12, 45, 'success'),
('transfer', 22178.34, 9, 31, 'success'),
('transfer', 48899.07, 22, 58, 'failed'),
('transfer', 17570.72, 41, 17, 'pending'),
('transfer', 30174.37, 6, 52, 'success'),
('transfer', 34316.63, 37, 26, 'success'),
('transfer', 18804.35, 54, 13, 'success'),
('transfer', 37153.09, 2, 47, 'success'),
('transfer', 972.31, 48, 36, 'success'),
('transfer', 16844.35, 25, 59, 'success'),
('transfer', 26309.84, 39, 4, 'pending'),
('transfer', 41789.71, 18, 53, 'success'),
('transfer', 6228.54, 60, 21, 'success'),
('transfer', 18228.38, 5, 43, 'success'),
('transfer', 8899.55, 34, 28, 'success'),
('transfer', 50031.89, 46, 30, 'failed'),
('transfer', 27448.64, 20, 55, 'success'),
('transfer', 16714.54, 57, 10, 'pending'),
('transfer', 23093.24, 32, 40, 'success'),
('transfer', 31759.52, 1, 60, 'success'),
('transfer', 2777.15, 50, 24, 'success'),
('transfer', 11774.14, 14, 48, 'success'),
('transfer', 5117.60, 42, 2, 'success'),
('transfer', 42181.97, 28, 60, 'success'),
('transfer', 45923.31, 56, 32, 'pending'),
('transfer', 4267.59, 7, 44, 'success'),
('transfer', 19955.81, 53, 16, 'success'),
('transfer', 28761.43, 23, 39, 'success'),
('transfer', 9381.89, 38, 12, 'failed'),
('transfer', 3223.28, 31, 54, 'success'),
('transfer', 23602.82, 47, 5, 'success'),
('transfer', 45759.82, 19, 51, 'pending'),
('transfer', 49008.42, 59, 27, 'success'),
('transfer', 40810.49, 4, 34, 'success'),
('transfer', 6123.93, 33, 20, 'success'),
('transfer', 34352.15, 10, 57, 'success'),
('transfer', 19625.94, 52, 29, 'success'),
('transfer', 14643.84, 21, 46, 'success'),
('transfer', 9136.53, 45, 18, 'pending'),
('transfer', 30072.88, 26, 37, 'success'),
('transfer', 8982.63, 40, 15, 'success'),
('transfer', 19295.06, 11, 60, 'failed'),
('transfer', 12164.18, 49, 1, 'success'),
('transfer', 30681.97, 24, 55, 'success'),
('transfer', 987.39, 58, 36, 'success'),
('transfer', 2115.41, 13, 41, 'pending'),
('transfer', 12122.18, 43, 17, 'success'),
('transfer', 14078.94, 30, 60, 'success'),
('transfer', 24542.72, 55, 4, 'success'),
('transfer', 5916.49, 36, 19, 'success');



INSERT INTO ledger_entries (transaction_id, account_id, entry_type, amount, created_at) VALUES
(1, 15, 'credit', 11046.39, '2026-06-03 10:05:09.156472'),
(1, 42, 'debit', 11046.39, '2026-06-03 10:05:09.156472'),
(2, 8, 'credit', 16502.00, '2026-06-03 10:05:09.156472'),
(2, 33, 'debit', 16502.00, '2026-06-03 10:05:09.156472'),
(3, 27, 'credit', 45975.10, '2026-06-03 10:05:09.156472'),
(3, 11, 'debit', 45975.10, '2026-06-03 10:05:09.156472'),
(4, 44, 'credit', 39087.15, '2026-06-03 10:05:09.156472'),
(4, 19, 'debit', 39087.15, '2026-06-03 10:05:09.156472'),
(5, 3, 'credit', 44933.12, '2026-06-03 10:05:09.156472'),
(5, 56, 'debit', 44933.12, '2026-06-03 10:05:09.156472'),
(6, 29, 'credit', 31472.57, '2026-06-03 10:05:09.156472'),
(6, 38, 'debit', 31472.57, '2026-06-03 10:05:09.156472'),
(7, 51, 'credit', 29135.49, '2026-06-03 10:05:09.156472'),
(7, 7, 'debit', 29135.49, '2026-06-03 10:05:09.156472'),
(8, 16, 'credit', 13210.80, '2026-06-03 10:05:09.156472'),
(8, 49, 'debit', 13210.80, '2026-06-03 10:05:09.156472'),
(9, 60, 'credit', 11153.72, '2026-06-03 10:05:09.156472'),
(9, 23, 'debit', 11153.72, '2026-06-03 10:05:09.156472'),
(10, 35, 'credit', 9125.10, '2026-06-03 10:05:09.156472'),
(10, 14, 'debit', 9125.10, '2026-06-03 10:05:09.156472'),
(11, 12, 'debit', 46237.10, '2026-06-03 10:05:09.156472'),
(11, 45, 'credit', 46237.10, '2026-06-03 10:05:09.156472'),
(12, 9, 'debit', 22178.34, '2026-06-03 10:05:09.156472'),
(12, 31, 'credit', 22178.34, '2026-06-03 10:05:09.156472'),
(13, 22, 'debit', 48899.07, '2026-06-03 10:05:09.156472'),
(13, 58, 'credit', 48899.07, '2026-06-03 10:05:09.156472'),
(14, 41, 'debit', 17570.72, '2026-06-03 10:05:09.156472'),
(14, 17, 'credit', 17570.72, '2026-06-03 10:05:09.156472'),
(15, 6, 'debit', 30174.37, '2026-06-03 10:05:09.156472'),
(15, 52, 'credit', 30174.37, '2026-06-03 10:05:09.156472'),
(16, 37, 'debit', 34316.63, '2026-06-03 10:05:09.156472'),
(16, 26, 'credit', 34316.63, '2026-06-03 10:05:09.156472'),
(17, 54, 'debit', 18804.35, '2026-06-03 10:05:09.156472'),
(17, 13, 'credit', 18804.35, '2026-06-03 10:05:09.156472'),
(18, 2, 'debit', 37153.09, '2026-06-03 10:05:09.156472'),
(18, 47, 'credit', 37153.09, '2026-06-03 10:05:09.156472'),
(19, 48, 'debit', 972.31, '2026-06-03 10:05:09.156472'),
(19, 36, 'credit', 972.31, '2026-06-03 10:05:09.156472'),
(20, 25, 'debit', 16844.35, '2026-06-03 10:05:09.156472'),
(20, 59, 'credit', 16844.35, '2026-06-03 10:05:09.156472'),
(21, 39, 'debit', 26309.84, '2026-06-03 10:05:09.156472'),
(21, 4, 'credit', 26309.84, '2026-06-03 10:05:09.156472'),
(22, 18, 'debit', 41789.71, '2026-06-03 10:05:09.156472'),
(22, 53, 'credit', 41789.71, '2026-06-03 10:05:09.156472'),
(23, 60, 'debit', 6228.54, '2026-06-03 10:05:09.156472'),
(23, 21, 'credit', 6228.54, '2026-06-03 10:05:09.156472'),
(24, 5, 'debit', 18228.38, '2026-06-03 10:05:09.156472'),
(24, 43, 'credit', 18228.38, '2026-06-03 10:05:09.156472'),
(25, 34, 'debit', 8899.55, '2026-06-03 10:05:09.156472'),
(25, 28, 'credit', 8899.55, '2026-06-03 10:05:09.156472'),
(26, 46, 'debit', 50031.89, '2026-06-03 10:05:09.156472'),
(26, 30, 'credit', 50031.89, '2026-06-03 10:05:09.156472'),
(27, 20, 'debit', 27448.64, '2026-06-03 10:05:09.156472'),
(27, 55, 'credit', 27448.64, '2026-06-03 10:05:09.156472'),
(28, 57, 'debit', 16714.54, '2026-06-03 10:05:09.156472'),
(28, 10, 'credit', 16714.54, '2026-06-03 10:05:09.156472'),
(29, 32, 'debit', 23093.24, '2026-06-03 10:05:09.156472'),
(29, 40, 'credit', 23093.24, '2026-06-03 10:05:09.156472'),
(30, 1, 'debit', 31759.52, '2026-06-03 10:05:09.156472'),
(30, 60, 'credit', 31759.52, '2026-06-03 10:05:09.156472');


select * from ledger_entries

INSERT INTO loans (customer_id, amount, status, created_at) VALUES
(1, 11046.39, 'active', '2026-06-03 10:05:09.156472'),
(2, 16502.00, 'active', '2026-06-03 10:05:09.156472'),
(3, 45975.10, 'closed', '2026-06-03 10:05:09.156472'),
(4, 39087.15, 'active', '2026-06-03 10:05:09.156472'),
(5, 44933.12, 'active', '2026-06-03 10:05:09.156472'),
(6, 31472.57, 'closed', '2026-06-03 10:05:09.156472'),
(7, 29135.49, 'active', '2026-06-03 10:05:09.156472'),
(8, 13210.80, 'active', '2026-06-03 10:05:09.156472'),
(9, 11153.72, 'closed', '2026-06-03 10:05:09.156472'),
(10, 9125.10, 'active', '2026-06-03 10:05:09.156472'),
(11, 46237.10, 'active', '2026-06-03 10:05:09.156472'),
(12, 22178.34, 'closed', '2026-06-03 10:05:09.156472'),
(13, 48899.07, 'active', '2026-06-03 10:05:09.156472'),
(14, 17570.72, 'active', '2026-06-03 10:05:09.156472'),
(15, 30174.37, 'active', '2026-06-03 10:05:09.156472'),
(16, 34316.63, 'closed', '2026-06-03 10:05:09.156472'),
(17, 18804.35, 'active', '2026-06-03 10:05:09.156472'),
(18, 37153.09, 'active', '2026-06-03 10:05:09.156472'),
(19, 972.31, 'active', '2026-06-03 10:05:09.156472'),
(20, 16844.35, 'closed', '2026-06-03 10:05:09.156472'),
(21, 26309.84, 'active', '2026-06-03 10:05:09.156472'),
(22, 41789.71, 'active', '2026-06-03 10:05:09.156472'),
(23, 6228.54, 'active', '2026-06-03 10:05:09.156472'),
(24, 18228.38, 'closed', '2026-06-03 10:05:09.156472'),
(25, 8899.55, 'active', '2026-06-03 10:05:09.156472'),
(26, 50031.89, 'active', '2026-06-03 10:05:09.156472'),
(27, 27448.64, 'active', '2026-06-03 10:05:09.156472'),
(28, 16714.54, 'closed', '2026-06-03 10:05:09.156472'),
(29, 23093.24, 'active', '2026-06-03 10:05:09.156472'),
(30, 31759.52, 'active', '2026-06-03 10:05:09.156472'),
(31, 2777.15, 'active', '2026-06-03 10:05:09.156472'),
(32, 11774.14, 'closed', '2026-06-03 10:05:09.156472'),
(33, 5117.60, 'active', '2026-06-03 10:05:09.156472'),
(34, 42181.97, 'active', '2026-06-03 10:05:09.156472'),
(35, 45923.31, 'active', '2026-06-03 10:05:09.156472'),
(36, 4267.59, 'closed', '2026-06-03 10:05:09.156472'),
(37, 19955.81, 'active', '2026-06-03 10:05:09.156472'),
(38, 28761.43, 'active', '2026-06-03 10:05:09.156472'),
(39, 9381.89, 'active', '2026-06-03 10:05:09.156472'),
(40, 3223.28, 'closed', '2026-06-03 10:05:09.156472'),
(41, 23602.82, 'active', '2026-06-03 10:05:09.156472'),
(42, 45759.82, 'active', '2026-06-03 10:05:09.156472'),
(43, 49008.42, 'active', '2026-06-03 10:05:09.156472'),
(44, 40810.49, 'closed', '2026-06-03 10:05:09.156472'),
(45, 6123.93, 'active', '2026-06-03 10:05:09.156472'),
(46, 34352.15, 'active', '2026-06-03 10:05:09.156472'),
(47, 19625.94, 'active', '2026-06-03 10:05:09.156472'),
(48, 14643.84, 'closed', '2026-06-03 10:05:09.156472'),
(49, 9136.53, 'active', '2026-06-03 10:05:09.156472'),
(50, 30072.88, 'active', '2026-06-03 10:05:09.156472'),
(51, 8982.63, 'active', '2026-06-03 10:05:09.156472'),
(52, 19295.06, 'closed', '2026-06-03 10:05:09.156472'),
(53, 12164.18, 'active', '2026-06-03 10:05:09.156472'),
(54, 30681.97, 'active', '2026-06-03 10:05:09.156472'),
(55, 987.39, 'active', '2026-06-03 10:05:09.156472'),
(56, 2115.41, 'closed', '2026-06-03 10:05:09.156472'),
(57, 12122.18, 'active', '2026-06-03 10:05:09.156472'),
(58, 14078.94, 'active', '2026-06-03 10:05:09.156472'),
(59, 24542.72, 'active', '2026-06-03 10:05:09.156472'),
(60, 5916.49, 'closed', '2026-06-03 10:05:09.156472');




INSERT INTO loan_payments (loan_id, amount, created_at) VALUES
(1, 1104.64, '2026-06-10 10:05:09.156472'),
(1, 2209.28, '2026-06-17 10:05:09.156472'),
(2, 1650.20, '2026-06-10 10:05:09.156472'),
(3, 4597.51, '2026-06-05 10:05:09.156472'),
(3, 918.95, '2026-06-12 10:05:09.156472'),
(4, 3908.72, '2026-06-10 10:05:09.156472'),
(5, 4493.31, '2026-06-11 10:05:09.156472'),
(6, 3147.26, '2026-06-08 10:05:09.156472'),
(6, 6294.51, '2026-06-15 10:05:09.156472'),
(7, 2913.55, '2026-06-10 10:05:09.156472'),
(8, 1321.08, '2026-06-09 10:05:09.156472'),
(9, 1115.37, '2026-06-07 10:05:09.156472'),
(9, 2230.74, '2026-06-14 10:05:09.156472'),
(10, 912.51, '2026-06-10 10:05:09.156472'),
(11, 4623.71, '2026-06-10 10:05:09.156472'),
(12, 2217.83, '2026-06-12 10:05:09.156472'),
(12, 4435.67, '2026-06-19 10:05:09.156472'),
(13, 4889.91, '2026-06-10 10:05:09.156472'),
(14, 1757.07, '2026-06-11 10:05:09.156472'),
(15, 3017.44, '2026-06-10 10:05:09.156472'),
(16, 3431.66, '2026-06-13 10:05:09.156472'),
(16, 6863.33, '2026-06-20 10:05:09.156472'),
(17, 1880.44, '2026-06-10 10:05:09.156472'),
(18, 3715.31, '2026-06-09 10:05:09.156472'),
(19, 97.23, '2026-06-10 10:05:09.156472'),
(20, 1684.44, '2026-06-14 10:05:09.156472'),
(20, 3368.87, '2026-06-21 10:05:09.156472'),
(21, 2630.98, '2026-06-10 10:05:09.156472'),
(22, 4178.97, '2026-06-11 10:05:09.156472'),
(23, 622.85, '2026-06-10 10:05:09.156472'),
(24, 1822.84, '2026-06-15 10:05:09.156472'),
(24, 3645.68, '2026-06-22 10:05:09.156472'),
(25, 889.96, '2026-06-10 10:05:09.156472'),
(26, 5003.19, '2026-06-12 10:05:09.156472'),
(27, 2744.86, '2026-06-10 10:05:09.156472'),
(28, 1671.45, '2026-06-16 10:05:09.156472'),
(28, 3342.91, '2026-06-23 10:05:09.156472'),
(29, 2309.32, '2026-06-10 10:05:09.156472'),
(30, 3175.95, '2026-06-11 10:05:09.156472'),
(31, 277.72, '2026-06-10 10:05:09.156472'),
(32, 1177.41, '2026-06-17 10:05:09.156472'),
(32, 2354.83, '2026-06-24 10:05:09.156472'),
(33, 511.76, '2026-06-10 10:05:09.156472'),
(34, 4218.20, '2026-06-09 10:05:09.156472'),
(35, 4592.33, '2026-06-10 10:05:09.156472'),
(36, 426.76, '2026-06-18 10:05:09.156472'),
(36, 853.52, '2026-06-25 10:05:09.156472'),
(37, 1995.58, '2026-06-10 10:05:09.156472'),
(38, 2876.14, '2026-06-11 10:05:09.156472'),
(39, 938.19, '2026-06-10 10:05:09.156472'),
(40, 322.33, '2026-06-19 10:05:09.156472'),
(40, 644.66, '2026-06-26 10:05:09.156472'),
(41, 2360.28, '2026-06-10 10:05:09.156472'),
(42, 4575.98, '2026-06-12 10:05:09.156472'),
(43, 4900.84, '2026-06-10 10:05:09.156472'),
(44, 4081.05, '2026-06-20 10:05:09.156472'),
(44, 8162.10, '2026-06-27 10:05:09.156472'),
(45, 612.39, '2026-06-10 10:05:09.156472'),
(46, 3435.22, '2026-06-11 10:05:09.156472'),
(47, 1962.59, '2026-06-10 10:05:09.156472'),
(48, 1464.38, '2026-06-21 10:05:09.156472'),
(48, 2928.77, '2026-06-28 10:05:09.156472'),
(49, 913.65, '2026-06-10 10:05:09.156472'),
(50, 3007.29, '2026-06-13 10:05:09.156472'),
(51, 898.26, '2026-06-10 10:05:09.156472'),
(52, 1929.51, '2026-06-22 10:05:09.156472'),
(52, 3859.01, '2026-06-29 10:05:09.156472'),
(53, 1216.42, '2026-06-10 10:05:09.156472'),
(54, 3068.20, '2026-06-14 10:05:09.156472'),
(55, 98.74, '2026-06-10 10:05:09.156472'),
(56, 211.54, '2026-06-23 10:05:09.156472'),
(56, 423.08, '2026-06-30 10:05:09.156472'),
(57, 1212.22, '2026-06-10 10:05:09.156472'),
(58, 1407.89, '2026-06-15 10:05:09.156472'),
(59, 2454.27, '2026-06-10 10:05:09.156472'),
(60, 591.65, '2026-06-24 10:05:09.156472'),
(60, 1183.30, '2026-07-01 10:05:09.156472');




















INSERT INTO cards (account_id, card_number, status, expiry_date, created_at) VALUES
(1, '8600 1234 5678 9101', 'active', '2028-12-31', '2026-06-03 10:05:09.156472'),
(2, '8600 2345 6789 1012', 'active', '2028-12-31', '2026-06-03 10:05:09.156472'),
(3, '8600 3456 7890 1213', 'blocked', '2027-06-30', '2026-06-03 10:05:09.156472'),
(4, '8600 4567 8901 2314', 'active', '2029-01-15', '2026-06-03 10:05:09.156472'),
(5, '8600 5678 9012 3415', 'active', '2028-11-20', '2026-06-03 10:05:09.156472'),
(6, '8600 6789 0123 4516', 'expired', '2025-05-10', '2026-06-03 10:05:09.156472'),
(7, '8600 7890 1234 5617', 'active', '2029-03-25', '2026-06-03 10:05:09.156472'),
(8, '8600 8901 2345 6718', 'active', '2028-09-05', '2026-06-03 10:05:09.156472'),
(9, '8600 9012 3456 7819', 'blocked', '2027-12-12', '2026-06-03 10:05:09.156472'),
(10, '8600 0123 4567 8920', 'active', '2029-07-18', '2026-06-03 10:05:09.156472'),
(11, '8600 1122 3344 5566', 'active', '2028-10-30', '2026-06-03 10:05:09.156472'),
(12, '8600 2233 4455 6677', 'active', '2027-08-22', '2026-06-03 10:05:09.156472'),
(13, '8600 3344 5566 7788', 'expired', '2025-02-14', '2026-06-03 10:05:09.156472'),
(14, '8600 4455 6677 8899', 'active', '2029-11-11', '2026-06-03 10:05:09.156472'),
(15, '8600 5566 7788 9900', 'active', '2028-04-28', '2026-06-03 10:05:09.156472'),
(16, '8600 6677 8899 0011', 'blocked', '2027-01-19', '2026-06-03 10:05:09.156472'),
(17, '8600 7788 9900 1122', 'active', '2029-09-07', '2026-06-03 10:05:09.156472'),
(18, '8600 8899 0011 2233', 'active', '2028-06-13', '2026-06-03 10:05:09.156472'),
(19, '8600 9900 1122 3344', 'active', '2027-10-03', '2026-06-03 10:05:09.156472'),
(20, '8600 0011 2233 4455', 'expired', '2025-07-24', '2026-06-03 10:05:09.156472'),
(21, '8600 1234 5678 9102', 'active', '2028-12-15', '2026-06-03 10:05:09.156472'),
(22, '8600 2345 6789 1013', 'active', '2029-02-28', '2026-06-03 10:05:09.156472'),
(23, '8600 3456 7890 1214', 'blocked', '2027-11-09', '2026-06-03 10:05:09.156472'),
(24, '8600 4567 8901 2315', 'active', '2028-08-17', '2026-06-03 10:05:09.156472'),
(25, '8600 5678 9012 3416', 'active', '2029-04-21', '2026-06-03 10:05:09.156472'),
(26, '8600 6789 0123 4517', 'active', '2027-05-06', '2026-06-03 10:05:09.156472'),
(27, '8600 7890 1234 5618', 'expired', '2025-09-30', '2026-06-03 10:05:09.156472'),
(28, '8600 8901 2345 6719', 'active', '2029-01-12', '2026-06-03 10:05:09.156472'),
(29, '8600 9012 3456 7820', 'active', '2028-03-27', '2026-06-03 10:05:09.156472'),
(30, '8600 0123 4567 8921', 'blocked', '2027-07-08', '2026-06-03 10:05:09.156472'),
(31, '8600 1122 3344 5567', 'active', '2029-06-19', '2026-06-03 10:05:09.156472'),
(32, '8600 2233 4455 6678', 'active', '2028-10-14', '2026-06-03 10:05:09.156472'),
(33, '8600 3344 5566 7789', 'active', '2027-04-02', '2026-06-03 10:05:09.156472'),
(34, '8600 4455 6677 8890', 'expired', '2025-12-01', '2026-06-03 10:05:09.156472'),
(35, '8600 5566 7788 9901', 'active', '2029-08-26', '2026-06-03 10:05:09.156472'),
(36, '8600 6677 8899 0012', 'active', '2028-01-04', '2026-06-03 10:05:09.156472'),
(37, '8600 7788 9900 1123', 'blocked', '2027-09-16', '2026-06-03 10:05:09.156472'),
(38, '8600 8899 0011 2234', 'active', '2029-05-23', '2026-06-03 10:05:09.156472'),
(39, '8600 9900 1122 3345', 'active', '2028-07-11', '2026-06-03 10:05:09.156472'),
(40, '8600 0011 2233 4456', 'active', '2027-02-09', '2026-06-03 10:05:09.156472'),
(41, '8600 1234 5678 9103', 'expired', '2025-11-27', '2026-06-03 10:05:09.156472'),
(42, '8600 2345 6789 1014', 'active', '2029-10-05', '2026-06-03 10:05:09.156472'),
(43, '8600 3456 7890 1215', 'active', '2028-05-18', '2026-06-03 10:05:09.156472'),
(44, '8600 4567 8901 2316', 'blocked', '2027-03-07', '2026-06-03 10:05:09.156472'),
(45, '8600 5678 9012 3417', 'active', '2029-12-09', '2026-06-03 10:05:09.156472'),
(46, '8600 6789 0123 4518', 'active', '2028-02-22', '2026-06-03 10:05:09.156472'),
(47, '8600 7890 1234 5619', 'active', '2027-06-30', '2026-06-03 10:05:09.156472'),
(48, '8600 8901 2345 6720', 'expired', '2025-04-16', '2026-06-03 10:05:09.156472'),
(49, '8600 9012 3456 7821', 'active', '2029-03-01', '2026-06-03 10:05:09.156472'),
(50, '8600 0123 4567 8922', 'active', '2028-09-19', '2026-06-03 10:05:09.156472'),
(51, '8600 1122 3344 5568', 'blocked', '2027-12-28', '2026-06-03 10:05:09.156472'),
(52, '8600 2233 4455 6679', 'active', '2029-07-14', '2026-06-03 10:05:09.156472'),
(53, '8600 3344 5566 7790', 'active', '2028-11-08', '2026-06-03 10:05:09.156472'),
(54, '8600 4455 6677 8891', 'active', '2027-01-21', '2026-06-03 10:05:09.156472'),
(55, '8600 5566 7788 9902', 'expired', '2025-08-13', '2026-06-03 10:05:09.156472'),
(56, '8600 6677 8899 0013', 'active', '2029-10-29', '2026-06-03 10:05:09.156472'),
(57, '8600 7788 9900 1124', 'active', '2028-04-05', '2026-06-03 10:05:09.156472'),
(58, '8600 8899 0011 2235', 'blocked', '2027-02-18', '2026-06-03 10:05:09.156472'),
(59, '8600 9900 1122 3346', 'active', '2029-06-10', '2026-06-03 10:05:09.156472'),
(60, '8600 0011 2233 4457', 'active', '2028-12-03', '2026-06-03 10:05:09.156472');




SELECT * from cards

INSERT INTO beneficiaries (customer_id, beneficiary_account_id, nickname, created_at) VALUES
(1, 2, 'Ali', '2026-06-03 10:05:09.156472'),
(2, 3, 'Bekzod', '2026-06-03 10:05:09.156472'),
(3, 4, 'Jamshid', '2026-06-03 10:05:09.156472'),
(4, 5, 'Dilshod', '2026-06-03 10:05:09.156472'),
(5, 6, 'Sardor', '2026-06-03 10:05:09.156472'),
(6, 7, 'Otabek', '2026-06-03 10:05:09.156472'),
(7, 8, 'Jasur', '2026-06-03 10:05:09.156472'),
(8, 9, 'Ulugbek', '2026-06-03 10:05:09.156472'),
(9, 10, 'Shoxrux', '2026-06-03 10:05:09.156472'),
(10, 11, 'Doniyor', '2026-06-03 10:05:09.156472'),
(11, 12, 'Murod', '2026-06-03 10:05:09.156472'),
(12, 13, 'Farrux', '2026-06-03 10:05:09.156472'),
(13, 14, 'Azamat', '2026-06-03 10:05:09.156472'),
(14, 15, 'Bobur', '2026-06-03 10:05:09.156472'),
(15, 16, 'Javohir', '2026-06-03 10:05:09.156472'),
(16, 17, 'Sherzod', '2026-06-03 10:05:09.156472'),
(17, 18, 'Ravshan', '2026-06-03 10:05:09.156472'),
(18, 19, 'Hasan', '2026-06-03 10:05:09.156472'),
(19, 20, 'Husan', '2026-06-03 10:05:09.156472'),
(20, 21, 'Anvar', '2026-06-03 10:05:09.156472'),
(21, 22, 'Akmal', '2026-06-03 10:05:09.156472'),
(22, 23, 'Bahodir', '2026-06-03 10:05:09.156472'),
(23, 24, 'Giyos', '2026-06-03 10:05:09.156472'),
(24, 25, 'Davron', '2026-06-03 10:05:09.156472'),
(25, 26, 'Elyor', '2026-06-03 10:05:09.156472'),
(26, 27, 'Farhod', '2026-06-03 10:05:09.156472'),
(27, 28, 'Golib', '2026-06-03 10:05:09.156472'),
(28, 29, 'Hakim', '2026-06-03 10:05:09.156472'),
(29, 30, 'Ikrom', '2026-06-03 10:05:09.156472'),
(30, 31, 'Jalol', '2026-06-03 10:05:09.156472'),
(31, 32, 'Komil', '2026-06-03 10:05:09.156472'),
(32, 33, 'Laziz', '2026-06-03 10:05:09.156472'),
(33, 34, 'Mansur', '2026-06-03 10:05:09.156472'),
(34, 35, 'Nodir', '2026-06-03 10:05:09.156472'),
(35, 36, 'Odil', '2026-06-03 10:05:09.156472'),
(36, 37, 'Pulat', '2026-06-03 10:05:09.156472'),
(37, 38, 'Qobil', '2026-06-03 10:05:09.156472'),
(38, 39, 'Rustam', '2026-06-03 10:05:09.156472'),
(39, 40, 'Sobir', '2026-06-03 10:05:09.156472'),
(40, 41, 'Temur', '2026-06-03 10:05:09.156472'),
(41, 42, 'Umid', '2026-06-03 10:05:09.156472'),
(42, 43, 'Vali', '2026-06-03 10:05:09.156472'),
(43, 44, 'Xurshid', '2026-06-03 10:05:09.156472'),
(44, 45, 'Yusuf', '2026-06-03 10:05:09.156472'),
(45, 46, 'Zafar', '2026-06-03 10:05:09.156472'),
(46, 47, 'Abror', '2026-06-03 10:05:09.156472'),
(47, 48, 'Bunyod', '2026-06-03 10:05:09.156472'),
(48, 49, 'Chori', '2026-06-03 10:05:09.156472'),
(49, 50, 'Doston', '2026-06-03 10:05:09.156472'),
(50, 51, 'Erkin', '2026-06-03 10:05:09.156472'),
(51, 52, 'Firdavs', '2026-06-03 10:05:09.156472'),
(52, 53, 'Ganisher', '2026-06-03 10:05:09.156472'),
(53, 54, 'Hoshim', '2026-06-03 10:05:09.156472'),
(54, 55, 'Islom', '2026-06-03 10:05:09.156472'),
(55, 56, 'Jahongir', '2026-06-03 10:05:09.156472'),
(56, 57, 'Kamol', '2026-06-03 10:05:09.156472'),
(57, 58, 'Lutfulla', '2026-06-03 10:05:09.156472'),
(58, 59, 'Muhammad', '2026-06-03 10:05:09.156472'),
(59, 60, 'Navruz', '2026-06-03 10:05:09.156472'),
(60, 1, 'Olim', '2026-06-03 10:05:09.156472');

INSERT INTO account_freeze (account_id, reason, frozen_at, unfrozen_at) VALUES
(1, 'Suspicious activity', '2026-06-05 08:00:00.000000', '2026-06-10 09:00:00.000000'),
(2, 'Court order', '2026-06-01 10:30:00.000000', '2026-06-15 16:00:00.000000'),
(3, 'Multiple failed attempts', '2026-06-07 14:20:00.000000', '2026-06-12 10:00:00.000000'),
(4, 'Fraud investigation', '2026-06-02 09:15:00.000000', '2026-06-20 18:00:00.000000'),
(5, 'Customer request', '2026-06-08 11:00:00.000000', '2026-06-18 09:30:00.000000'),
(6, 'Expired documents', '2026-06-03 12:00:00.000000', '2026-06-25 14:00:00.000000'),
(7, 'Unauthorized access', '2026-06-06 16:45:00.000000', NULL),
(8, 'Dormant account', '2026-06-04 13:30:00.000000', '2026-06-22 11:00:00.000000'),
(9, 'KYC pending', '2026-06-09 09:00:00.000000', NULL),
(10, 'Suspicious transaction', '2026-06-10 08:15:00.000000', '2026-06-14 10:00:00.000000'),
(11, 'Regulatory freeze', '2026-06-11 10:00:00.000000', '2026-06-30 17:00:00.000000'),
(12, 'Duplicate account', '2026-06-12 09:30:00.000000', '2026-06-19 12:00:00.000000'),
(13, 'Money laundering risk', '2026-06-13 14:00:00.000000', NULL),
(14, 'Tax issue', '2026-06-14 11:15:00.000000', '2026-07-05 09:00:00.000000'),
(15, 'Identity verification', '2026-06-15 08:45:00.000000', '2026-06-28 16:30:00.000000'),
(16, 'Chargeback dispute', '2026-06-16 13:20:00.000000', '2026-06-23 10:00:00.000000'),
(17, 'Cyber attack alert', '2026-06-17 09:00:00.000000', NULL),
(18, 'Account takeover', '2026-06-18 15:30:00.000000', '2026-07-10 11:00:00.000000'),
(19, 'Invalid signature', '2026-06-19 10:45:00.000000', '2026-06-26 14:00:00.000000'),
(20, 'Beneficiary complaint', '2026-06-20 12:10:00.000000', '2026-07-01 09:30:00.000000'),
(21, 'System error', '2026-06-21 08:00:00.000000', '2026-06-24 18:00:00.000000'),
(22, 'Manual review', '2026-06-22 11:30:00.000000', NULL),
(23, 'Large transaction', '2026-06-23 14:45:00.000000', '2026-06-30 12:00:00.000000'),
(24, 'Foreign currency', '2026-06-24 09:15:00.000000', '2026-07-08 10:00:00.000000'),
(25, 'Technical glitch', '2026-06-25 16:20:00.000000', '2026-06-29 08:00:00.000000'),
(26, 'Wrong beneficiary', '2026-06-26 10:00:00.000000', '2026-07-03 15:00:00.000000'),
(27, 'Duplicate transaction', '2026-06-27 13:35:00.000000', NULL),
(28, 'Timeout error', '2026-06-28 09:50:00.000000', '2026-07-02 11:30:00.000000'),
(29, 'Database issue', '2026-06-29 11:25:00.000000', '2026-07-06 14:00:00.000000'),
(30, 'Network failure', '2026-06-30 15:40:00.000000', '2026-07-07 09:00:00.000000'),
(31, 'Bank policy', '2026-07-01 08:30:00.000000', '2026-07-15 17:00:00.000000'),
(32, 'Government order', '2026-07-02 10:15:00.000000', NULL),
(33, 'Internal audit', '2026-07-03 13:00:00.000000', '2026-07-20 12:00:00.000000'),
(34, 'Risk management', '2026-07-04 09:45:00.000000', '2026-07-18 10:30:00.000000'),
(35, 'Compliance check', '2026-07-05 14:20:00.000000', '2026-07-25 16:00:00.000000'),
(36, 'Sanctions screening', '2026-07-06 11:10:00.000000', NULL),
(37, 'PEP review', '2026-07-07 08:55:00.000000', '2026-07-28 13:00:00.000000'),
(38, 'Source of funds', '2026-07-08 12:30:00.000000', '2026-08-01 09:00:00.000000'),
(39, 'Account restructuring', '2026-07-09 15:15:00.000000', '2026-07-30 11:00:00.000000'),
(40, 'Migration issue', '2026-07-10 09:40:00.000000', '2026-07-22 14:30:00.000000');

select * from account_freeze


DELETE FROM failed_transactions;

DBCC CHECKIDENT ('failed_transactions', RESEED, 0);


INSERT INTO failed_transactions (from_account_id, to_account_id, amount, error_message, created_at, customer_id) VALUES
(13, 58, 48899.07, 'Insufficient funds', '2026-06-03 10:05:09.156472', 1),
(46, 30, 50031.89, 'Account frozen', '2026-06-03 10:05:09.156472', 2),
(38, 12, 9381.89, 'Invalid account number', '2026-06-03 10:05:09.156472', 3),
(11, 60, 19295.06, 'Daily limit exceeded', '2026-06-03 10:05:09.156472', 4),
(22, 15, 45000.00, 'Insufficient funds', '2026-06-04 09:15:00.000000', 5),
(35, 18, 12000.00, 'Account not found', '2026-06-04 11:30:00.000000', 6),
(42, 7, 25000.00, 'Wrong IBAN', '2026-06-05 08:45:00.000000', 7),
(19, 44, 8800.00, 'Technical error', '2026-06-05 14:20:00.000000', 8),
(55, 29, 15500.00, 'Suspicious activity', '2026-06-06 10:10:00.000000', 9),
(31, 52, 6700.00, 'Account blocked', '2026-06-06 13:40:00.000000', 10),
(48, 23, 34000.00, 'Processing error', '2026-06-07 09:55:00.000000', 11),
(12, 36, 9800.00, 'Invalid currency', '2026-06-07 15:25:00.000000', 12),
(27, 41, 21000.00, 'Limit exceeded', '2026-06-08 08:30:00.000000', 13),
(59, 14, 17500.00, 'Account closed', '2026-06-08 12:15:00.000000', 14),
(5, 49, 4300.00, 'Network timeout', '2026-06-09 10:45:00.000000', 15),
(34, 61, 28000.00, 'Invalid account', '2026-06-09 14:50:00.000000', 16),
(50, 17, 36200.00, 'Insufficient balance', '2026-06-10 09:20:00.000000', 17),
(26, 33, 19400.00, 'Duplicate transaction', '2026-06-10 11:35:00.000000', 18),
(9, 56, 7200.00, 'Pending approval', '2026-06-11 08:15:00.000000', 19),
(44, 10, 31000.00, 'Fraud alert', '2026-06-11 13:40:00.000000', 20),
(16, 45, 14600.00, 'Database error', '2026-06-12 10:25:00.000000', 21),
(60, 22, 8700.00, 'System maintenance', '2026-06-12 15:10:00.000000', 22),
(37, 51, 23400.00, 'Invalid signature', '2026-06-13 09:00:00.000000', 23),
(6, 8, 4100.00, 'Account frozen', '2026-06-13 11:45:00.000000', 24),
(47, 25, 29900.00, 'Wrong account type', '2026-06-14 08:55:00.000000', 25),
(53, 39, 18500.00, 'Beneficiary issue', '2026-06-14 14:30:00.000000', 26),
(2, 62, 36700.00, 'Invalid routing number', '2026-06-15 10:15:00.000000', 27),
(40, 28, 12600.00, 'Timeout error', '2026-06-15 13:20:00.000000', 28),
(54, 19, 27900.00, 'Technical glitch', '2026-06-16 09:35:00.000000', 29),
(3, 57, 5400.00, 'Processing failed', '2026-06-16 12:50:00.000000', 30),
(32, 48, 31800.00, 'Insufficient funds', '2026-06-17 08:40:00.000000', 31),
(56, 13, 9400.00, 'Account restricted', '2026-06-17 11:55:00.000000', 32),
(18, 40, 22300.00, 'Invalid amount', '2026-06-18 10:05:00.000000', 33),
(24, 5, 7600.00, 'Missing documents', '2026-06-18 14:45:00.000000', 34),
(49, 31, 14200.00, 'KYC pending', '2026-06-19 09:15:00.000000', 35),
(58, 20, 26400.00, 'Account not verified', '2026-06-19 12:30:00.000000', 36),
(8, 54, 19300.00, 'Monthly limit reached', '2026-06-20 08:50:00.000000', 37),
(33, 4, 8200.00, 'Invalid reference', '2026-06-20 13:25:00.000000', 38),
(51, 37, 35100.00, 'Cancelled by user', '2026-06-21 10:40:00.000000', 39),
(43, 12, 11700.00, 'Bank error', '2026-06-21 15:55:00.000000', 40),
(17, 59, 25600.00, 'Hold placed on account', '2026-06-22 09:10:00.000000', 41),
(41, 2, 18900.00, 'Currency mismatch', '2026-06-22 11:35:00.000000', 42),
(25, 47, 31200.00, 'Suspicious pattern', '2026-06-23 08:25:00.000000', 43),
(61, 11, 4300.00, 'Invalid SWIFT code', '2026-06-23 14:00:00.000000', 44),
(15, 63, 27100.00, 'Account not active', '2026-06-24 10:20:00.000000', 45),
(39, 26, 15900.00, 'Security breach alert', '2026-06-24 13:45:00.000000', 46),
(45, 34, 22400.00, 'Regulatory block', '2026-06-25 09:30:00.000000', 47),
(7, 55, 6800.00, 'Expired card', '2026-06-25 12:15:00.000000', 48),
(52, 16, 30700.00, 'Incorrect OTP', '2026-06-26 08:55:00.000000', 49),
(29, 42, 13800.00, 'Failed authentication', '2026-06-26 11:40:00.000000', 50),
(36, 60, 19800.00, 'Transaction declined', '2026-06-27 10:05:00.000000', 51),
(20, 9, 45600.00, 'Contact bank', '2026-06-27 14:20:00.000000', 52),
(57, 35, 10300.00, 'Invalid date format', '2026-06-28 09:45:00.000000', 53),
(14, 51, 29000.00, 'System upgrade', '2026-06-28 13:10:00.000000', 54),
(23, 1, 17400.00, 'Duplicate payment', '2026-06-29 08:35:00.000000', 55),
(46, 38, 23200.00, 'Insufficient funds', '2026-06-29 12:50:00.000000', 56),
(30, 64, 16500.00, 'Invalid account ID', '2026-06-30 10:15:00.000000', 57),
(10, 27, 8100.00, 'Processing timeout', '2026-06-30 14:40:00.000000', 58);

SELECT * from failed_transactions


INSERT INTO audit_logs (transaction_id, from_account_id, to_account_id, customer_id, action_type, amount, details, created_at) VALUES
(1, 15, 42, 1, 'deposit', 11046.39, '{"source": "ATM", "location": "Dushanbe"}', '2026-06-03 10:05:09.156472'),
(2, 8, 33, 2, 'deposit', 16502.00, '{"source": "branch", "location": "Khujand"}', '2026-06-03 10:05:09.156472'),
(3, 27, 11, 3, 'deposit', 45975.10, '{"source": "online", "location": "web"}', '2026-06-03 10:05:09.156472'),
(4, 44, 19, 4, 'deposit', 39087.15, '{"source": "ATM", "location": "Bokhtar"}', '2026-06-03 10:05:09.156472'),
(5, 3, 56, 5, 'deposit', 44933.12, '{"source": "branch", "location": "Kulob"}', '2026-06-03 10:05:09.156472'),
(6, 29, 38, 6, 'loan', 31472.57, '{"loan_term": 12, "interest_rate": 12.5}', '2026-06-03 10:05:09.156472'),
(7, 51, 7, 7, 'loan', 29135.49, '{"loan_term": 24, "interest_rate": 11.0}', '2026-06-03 10:05:09.156472'),
(8, 16, 49, 8, 'loan', 13210.80, '{"loan_term": 6, "interest_rate": 15.0}', '2026-06-03 10:05:09.156472'),
(9, 60, 23, 9, 'loan', 11153.72, '{"loan_term": 12, "interest_rate": 13.0}', '2026-06-03 10:05:09.156472'),
(10, 35, 14, 10, 'loan', 9125.10, '{"loan_term": 18, "interest_rate": 14.5}', '2026-06-03 10:05:09.156472'),
(11, 12, 45, 11, 'transfer', 46237.10, '{"purpose": "business", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(12, 9, 31, 12, 'transfer', 22178.34, '{"purpose": "family", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(13, 22, 58, 13, 'transfer', 48899.07, '{"purpose": "investment", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(14, 41, 17, 14, 'transfer', 17570.72, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(15, 6, 52, 15, 'transfer', 30174.37, '{"purpose": "medical", "priority": "urgent"}', '2026-06-03 10:05:09.156472'),
(16, 37, 26, 16, 'transfer', 34316.63, '{"purpose": "business", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(17, 54, 13, 17, 'transfer', 18804.35, '{"purpose": "family", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(18, 2, 47, 18, 'transfer', 37153.09, '{"purpose": "investment", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(19, 48, 36, 19, 'transfer', 972.31, '{"purpose": "gift", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(20, 25, 59, 20, 'transfer', 16844.35, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(21, 39, 4, 21, 'transfer', 26309.84, '{"purpose": "business", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(22, 18, 53, 22, 'transfer', 41789.71, '{"purpose": "investment", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(23, 60, 21, 23, 'transfer', 6228.54, '{"purpose": "family", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(24, 5, 43, 24, 'transfer', 18228.38, '{"purpose": "medical", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(25, 34, 28, 25, 'transfer', 8899.55, '{"purpose": "gift", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(26, 46, 30, 26, 'transfer', 50031.89, '{"purpose": "business", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(27, 20, 55, 27, 'transfer', 27448.64, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(28, 57, 10, 28, 'transfer', 16714.54, '{"purpose": "family", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(29, 32, 40, 29, 'transfer', 23093.24, '{"purpose": "investment", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(30, 1, 60, 30, 'transfer', 31759.52, '{"purpose": "business", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(31, 50, 24, 31, 'transfer', 2777.15, '{"purpose": "gift", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(32, 14, 48, 32, 'transfer', 11774.14, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(33, 42, 2, 33, 'transfer', 5117.60, '{"purpose": "family", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(34, 28, 60, 34, 'transfer', 42181.97, '{"purpose": "investment", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(35, 56, 32, 35, 'transfer', 45923.31, '{"purpose": "business", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(36, 7, 44, 36, 'transfer', 4267.59, '{"purpose": "medical", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(37, 53, 16, 37, 'transfer', 19955.81, '{"purpose": "family", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(38, 23, 39, 38, 'transfer', 28761.43, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(39, 38, 12, 39, 'transfer', 9381.89, '{"purpose": "gift", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(40, 31, 54, 40, 'transfer', 3223.28, '{"purpose": "family", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(41, 47, 5, 41, 'transfer', 23602.82, '{"purpose": "business", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(42, 19, 51, 42, 'transfer', 45759.82, '{"purpose": "investment", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(43, 59, 27, 43, 'transfer', 49008.42, '{"purpose": "business", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(44, 4, 34, 44, 'transfer', 40810.49, '{"purpose": "education", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(45, 33, 20, 45, 'transfer', 6123.93, '{"purpose": "family", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(46, 10, 57, 46, 'transfer', 34352.15, '{"purpose": "medical", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(47, 52, 29, 47, 'transfer', 19625.94, '{"purpose": "family", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(48, 21, 46, 48, 'transfer', 14643.84, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(49, 45, 18, 49, 'transfer', 9136.53, '{"purpose": "gift", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(50, 26, 37, 50, 'transfer', 30072.88, '{"purpose": "business", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(51, 40, 15, 51, 'transfer', 8982.63, '{"purpose": "family", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(52, 11, 60, 52, 'transfer', 19295.06, '{"purpose": "investment", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(53, 49, 1, 53, 'transfer', 12164.18, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(54, 24, 55, 54, 'transfer', 30681.97, '{"purpose": "business", "priority": "high"}', '2026-06-03 10:05:09.156472'),
(55, 58, 36, 55, 'transfer', 987.39, '{"purpose": "gift", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(56, 13, 41, 56, 'transfer', 2115.41, '{"purpose": "family", "priority": "low"}', '2026-06-03 10:05:09.156472'),
(57, 43, 17, 57, 'transfer', 12122.18, '{"purpose": "medical", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(58, 30, 60, 58, 'transfer', 14078.94, '{"purpose": "education", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(59, 55, 4, 59, 'transfer', 24542.72, '{"purpose": "business", "priority": "normal"}', '2026-06-03 10:05:09.156472'),
(60, 36, 19, 60, 'transfer', 5916.49, '{"purpose": "family", "priority": "low"}', '2026-06-03 10:05:09.156472');

INSERT INTO risk_scores (customer_id, score, updated_at) VALUES
(1, 12, '2026-06-03 10:05:09.156472'),
(2, 22, '2026-06-03 10:05:09.156472'),
(3, 18, '2026-06-03 10:05:09.156472'),
(4, 7, '2026-06-03 10:05:09.156472'),
(5, 30, '2026-06-03 10:05:09.156472'),
(6, 9, '2026-06-03 10:05:09.156472'),
(7, 15, '2026-06-03 10:05:09.156472'),
(8, 11, '2026-06-03 10:05:09.156472'),
(9, 25, '2026-06-03 10:05:09.156472'),
(10, 14, '2026-06-03 10:05:09.156472'),
(11, 19, '2026-06-03 10:05:09.156472'),
(12, 8, '2026-06-03 10:05:09.156472'),
(13, 27, '2026-06-03 10:05:09.156472'),
(14, 10, '2026-06-03 10:05:09.156472'),
(15, 16, '2026-06-03 10:05:09.156472'),
(16, 6, '2026-06-03 10:05:09.156472'),
(17, 21, '2026-06-03 10:05:09.156472'),
(18, 5, '2026-06-03 10:05:09.156472'),
(19, 28, '2026-06-03 10:05:09.156472'),
(20, 13, '2026-06-03 10:05:09.156472'),
(21, 17, '2026-06-03 10:05:09.156472'),
(22, 9, '2026-06-03 10:05:09.156472'),
(23, 23, '2026-06-03 10:05:09.156472'),
(24, 12, '2026-06-03 10:05:09.156472'),
(25, 20, '2026-06-03 10:05:09.156472'),
(26, 5, '2026-06-03 10:05:09.156472'),
(27, 24, '2026-06-03 10:05:09.156472'),
(28, 10, '2026-06-03 10:05:09.156472'),
(29, 26, '2026-06-03 10:05:09.156472'),
(30, 8, '2026-06-03 10:05:09.156472'),
(31, 19, '2026-06-03 10:05:09.156472'),
(32, 11, '2026-06-03 10:05:09.156472'),
(33, 22, '2026-06-03 10:05:09.156472'),
(34, 7, '2026-06-03 10:05:09.156472'),
(35, 18, '2026-06-03 10:05:09.156472'),
(36, 13, '2026-06-03 10:05:09.156472'),
(37, 27, '2026-06-03 10:05:09.156472'),
(38, 6, '2026-06-03 10:05:09.156472'),
(39, 21, '2026-06-03 10:05:09.156472'),
(40, 10, '2026-06-03 10:05:09.156472'),
(41, 15, '2026-06-03 10:05:09.156472'),
(42, 9, '2026-06-03 10:05:09.156472'),
(43, 23, '2026-06-03 10:05:09.156472'),
(44, 8, '2026-06-03 10:05:09.156472'),
(45, 29, '2026-06-03 10:05:09.156472'),
(46, 12, '2026-06-03 10:05:09.156472'),
(47, 17, '2026-06-03 10:05:09.156472'),
(48, 5, '2026-06-03 10:05:09.156472'),
(49, 14, '2026-06-03 10:05:09.156472'),
(50, 25, '2026-06-03 10:05:09.156472'),
(51, 16, '2026-06-03 10:05:09.156472'),
(52, 7, '2026-06-03 10:05:09.156472'),
(53, 20, '2026-06-03 10:05:09.156472'),
(54, 9, '2026-06-03 10:05:09.156472'),
(55, 18, '2026-06-03 10:05:09.156472'),
(56, 11, '2026-06-03 10:05:09.156472'),
(57, 24, '2026-06-03 10:05:09.156472'),
(58, 10, '2026-06-03 10:05:09.156472'),
(59, 22, '2026-06-03 10:05:09.156472'),
(60, 6, '2026-06-03 10:05:09.156472');


SELECT * from fraud_alerts;


INSERT INTO fraud_alerts (account_id, alert_type, severity, created_at) VALUES
(3, 'suspicios_amount', 3, '2026-06-05 08:00:00.000000'),
(7, 'multiple_failed_logins', 2, '2026-06-07 14:20:00.000000'),
(13, 'rapid_transactions', 4, '2026-06-10 09:15:00.000000'),
(22, 'usual_location', 3, '2026-06-12 11:30:00.000000'),
(28, 'rapid_transactions', 5, '2026-06-15 16:45:00.000000'),
(35, 'account_takeover', 2, '2026-06-18 10:00:00.000000'),
(41, 'suspicios_amount', 4, '2026-06-20 14:20:00.000000'),
(50, 'new_device_login', 1, '2026-06-22 09:30:00.000000'),
(56, 'vilocity_check', 5, '2026-06-25 13:10:00.000000'),
(60, 'blacklist_ip', 3, '2026-06-28 11:45:00.000000'),
(5, 'usual_location', 3, '2026-07-01 08:30:00.000000'),
(11, 'hogh_risk_country', 4, '2026-07-03 14:15:00.000000'),
(18, 'card_not_present', 2, '2026-07-05 10:45:00.000000'),
(25, 'suspicios_amount', 4, '2026-07-08 09:20:00.000000'),
(32, 'account_takeover', 5, '2026-07-10 16:30:00.000000'),
(38, 'multiple_failed_logins', 1, '2026-07-12 11:00:00.000000'),
(45, 'blacklist_ip', 5, '2026-07-15 13:25:00.000000'),
(52, 'hogh_risk_country', 3, '2026-07-18 10:15:00.000000'),
(8, 'vilocity_check', 5, '2026-07-20 14:50:00.000000'),
(16, 'card_not_present', 2, '2026-07-22 09:40:00.000000'),
(1, 'suspicios_amount', 2, '2026-07-25 11:30:00.000000'),
(4, 'multiple_failed_logins', 3, '2026-07-27 15:20:00.000000'),
(9, 'rapid_transactions', 5, '2026-07-30 10:00:00.000000'),
(12, 'usual_location', 2, '2026-08-01 13:45:00.000000'),
(15, 'rapid_transactions', 4, '2026-08-03 09:15:00.000000'),
(19, 'account_takeover', 1, '2026-08-05 16:30:00.000000'),
(21, 'suspicios_amount', 3, '2026-08-07 11:20:00.000000'),
(24, 'new_device_login', 2, '2026-08-10 14:10:00.000000'),
(27, 'vilocity_check', 5, '2026-08-12 08:45:00.000000'),
(30, 'blacklist_ip', 3, '2026-08-14 12:30:00.000000'),
(33, 'usual_location', 4, '2026-08-16 10:00:00.000000'),
(36, 'hogh_risk_country', 2, '2026-08-18 15:55:00.000000'),
(39, 'card_not_present', 3, '2026-08-20 09:25:00.000000'),
(42, 'suspicios_amount', 5, '2026-08-22 13:40:00.000000'),
(46, 'account_takeover', 4, '2026-08-25 11:15:00.000000'),
(48, 'multiple_failed_logins', 1, '2026-08-27 16:05:00.000000'),
(51, 'blacklist_ip', 5, '2026-08-29 10:30:00.000000'),
(53, 'hogh_risk_country', 3, '2026-09-01 14:50:00.000000'),
(55, 'vilocity_check', 5, '2026-09-03 09:10:00.000000'),
(57, 'card_not_present', 2, '2026-09-05 12:25:00.000000'),
(2, 'suspicios_amount', 3, '2026-09-08 11:40:00.000000'),
(6, 'multiple_failed_logins', 2, '2026-09-10 15:30:00.000000'),
(10, 'rapid_transactions', 4, '2026-09-12 10:15:00.000000'),
(14, 'usual_location', 3, '2026-09-15 08:50:00.000000'),
(17, 'rapid_transactions', 5, '2026-09-17 14:20:00.000000'),
(20, 'account_takeover', 2, '2026-09-19 09:45:00.000000'),
(23, 'suspicios_amount', 4, '2026-09-22 16:10:00.000000'),
(26, 'new_device_login', 1, '2026-09-24 11:00:00.000000'),
(29, 'vilocity_check', 5, '2026-09-26 13:35:00.000000'),
(31, 'blacklist_ip', 3, '2026-09-29 10:25:00.000000'),
(34, 'usual_location', 3, '2026-10-01 15:15:00.000000'),
(37, 'hogh_risk_country', 4, '2026-10-03 09:55:00.000000'),
(40, 'card_not_present', 2, '2026-10-05 12:40:00.000000'),
(43, 'suspicios_amount', 4, '2026-10-08 14:30:00.000000'),
(44, 'account_takeover', 5, '2026-10-10 11:10:00.000000'),
(47, 'multiple_failed_logins', 1, '2026-10-12 08:35:00.000000'),
(49, 'blacklist_ip', 5, '2026-10-15 16:20:00.000000'),
(54, 'hogh_risk_country', 3, '2026-10-17 10:05:00.000000'),
(58, 'vilocity_check', 5, '2026-10-19 13:50:00.000000'),
(59, 'card_not_present', 2, '2026-10-22 09:30:00.000000');








INSERT INTO login_history (customer_id, ip_address, device, created_at) VALUES
(1, '192.168.1.1', 'Chrome Windows', '2026-06-03 08:00:00.000000'),
(2, '192.168.1.2', 'Firefox Mac', '2026-06-03 08:15:00.000000'),
(3, '192.168.1.3', 'Safari iPhone', '2026-06-03 08:30:00.000000'),
(4, '192.168.1.4', 'Android App', '2026-06-03 08:45:00.000000'),
(5, '192.168.1.5', 'Chrome Windows', '2026-06-03 09:00:00.000000'),
(6, '192.168.1.6', 'Edge Windows', '2026-06-03 09:15:00.000000'),
(7, '192.168.1.7', 'Safari Mac', '2026-06-03 09:30:00.000000'),
(8, '192.168.1.8', 'iPhone App', '2026-06-03 09:45:00.000000'),
(9, '192.168.1.9', 'Chrome Linux', '2026-06-03 10:00:00.000000'),
(10, '192.168.1.10', 'Android App', '2026-06-03 10:15:00.000000'),
(11, '192.168.1.11', 'Firefox Windows', '2026-06-04 08:00:00.000000'),
(12, '192.168.1.12', 'Safari iPad', '2026-06-04 08:30:00.000000'),
(13, '192.168.1.13', 'Chrome Windows', '2026-06-04 09:00:00.000000'),
(14, '192.168.1.14', 'Android App', '2026-06-04 09:30:00.000000'),
(15, '192.168.1.15', 'iPhone App', '2026-06-04 10:00:00.000000'),
(16, '192.168.1.16', 'Edge Windows', '2026-06-04 10:30:00.000000'),
(17, '192.168.1.17', 'Chrome Mac', '2026-06-05 08:00:00.000000'),
(18, '192.168.1.18', 'Safari iPhone', '2026-06-05 08:45:00.000000'),
(19, '192.168.1.19', 'Android App', '2026-06-05 09:30:00.000000'),
(20, '192.168.1.20', 'Firefox Windows', '2026-06-05 10:15:00.000000'),
(21, '192.168.1.21', 'Chrome Windows', '2026-06-06 08:15:00.000000'),
(22, '192.168.1.22', 'Safari Mac', '2026-06-06 09:00:00.000000'),
(23, '192.168.1.23', 'iPhone App', '2026-06-06 09:45:00.000000'),
(24, '192.168.1.24', 'Android App', '2026-06-06 10:30:00.000000'),
(25, '192.168.1.25', 'Chrome Linux', '2026-06-07 08:00:00.000000'),
(26, '192.168.1.26', 'Edge Windows', '2026-06-07 08:45:00.000000'),
(27, '192.168.1.27', 'Firefox Mac', '2026-06-07 09:30:00.000000'),
(28, '192.168.1.28', 'Safari iPad', '2026-06-07 10:15:00.000000'),
(29, '192.168.1.29', 'Chrome Windows', '2026-06-08 08:30:00.000000'),
(30, '192.168.1.30', 'Android App', '2026-06-08 09:15:00.000000'),
(31, '192.168.1.31', 'iPhone App', '2026-06-08 10:00:00.000000'),
(32, '192.168.1.32', 'Safari Mac', '2026-06-08 10:45:00.000000'),
(33, '192.168.1.33', 'Chrome Windows', '2026-06-09 08:00:00.000000'),
(34, '192.168.1.34', 'Firefox Windows', '2026-06-09 09:00:00.000000'),
(35, '192.168.1.35', 'Android App', '2026-06-09 10:00:00.000000'),
(36, '192.168.1.36', 'Edge Windows', '2026-06-09 11:00:00.000000'),
(37, '192.168.1.37', 'Chrome Mac', '2026-06-10 08:15:00.000000'),
(38, '192.168.1.38', 'Safari iPhone', '2026-06-10 09:15:00.000000'),
(39, '192.168.1.39', 'iPhone App', '2026-06-10 10:15:00.000000'),
(40, '192.168.1.40', 'Android App', '2026-06-10 11:15:00.000000'),
(41, '192.168.1.41', 'Chrome Windows', '2026-06-11 08:30:00.000000'),
(42, '192.168.1.42', 'Firefox Mac', '2026-06-11 09:30:00.000000'),
(43, '192.168.1.43', 'Safari iPad', '2026-06-11 10:30:00.000000'),
(44, '192.168.1.44', 'Edge Windows', '2026-06-11 11:30:00.000000'),
(45, '192.168.1.45', 'Chrome Linux', '2026-06-12 08:45:00.000000'),
(46, '192.168.1.46', 'Android App', '2026-06-12 09:45:00.000000'),
(47, '192.168.1.47', 'iPhone App', '2026-06-12 10:45:00.000000'),
(48, '192.168.1.48', 'Safari Mac', '2026-06-12 11:45:00.000000'),
(49, '192.168.1.49', 'Chrome Windows', '2026-06-13 09:00:00.000000'),
(50, '192.168.1.50', 'Firefox Windows', '2026-06-13 10:00:00.000000'),
(51, '192.168.1.51', 'Android App', '2026-06-13 11:00:00.000000'),
(52, '192.168.1.52', 'Edge Windows', '2026-06-13 12:00:00.000000'),
(53, '192.168.1.53', 'Chrome Mac', '2026-06-14 09:15:00.000000'),
(54, '192.168.1.54', 'Safari iPhone', '2026-06-14 10:15:00.000000'),
(55, '192.168.1.55', 'iPhone App', '2026-06-14 11:15:00.000000'),
(56, '192.168.1.56', 'Android App', '2026-06-14 12:15:00.000000'),
(57, '192.168.1.57', 'Chrome Windows', '2026-06-15 09:30:00.000000'),
(58, '192.168.1.58', 'Firefox Mac', '2026-06-15 10:30:00.000000'),
(59, '192.168.1.59', 'Safari iPad', '2026-06-15 11:30:00.000000'),
(60, '192.168.1.60', 'Edge Windows', '2026-06-15 12:30:00.000000');

INSERT INTO notifications (customer_id, message, is_read, created_at) VALUES
(1, 'Welcome to our banking system!', 1, '2026-06-03 10:05:09.156472'),
(2, 'Your deposit of $16502.00 was successful', 1, '2026-06-03 10:05:09.156472'),
(3, 'New login detected from new device', 0, '2026-06-03 10:05:09.156472'),
(4, 'Your loan application is pending review', 1, '2026-06-03 10:05:09.156472'),
(5, 'Monthly statement is ready', 0, '2026-06-04 08:00:00.000000'),
(6, 'Security alert: Password changed', 1, '2026-06-04 09:15:00.000000'),
(7, 'Your card has been blocked', 1, '2026-06-05 10:30:00.000000'),
(8, 'Bill payment reminder', 0, '2026-06-05 11:45:00.000000'),
(9, 'Special offer: Low interest loans', 0, '2026-06-06 08:00:00.000000'),
(10, 'Your account has been credited', 1, '2026-06-06 09:20:00.000000'),
(11, 'Suspicious transaction detected', 1, '2026-06-07 10:00:00.000000'),
(12, 'Please update your contact information', 0, '2026-06-07 11:30:00.000000'),
(13, 'Your loan payment is due soon', 0, '2026-06-08 09:00:00.000000'),
(14, 'New beneficiary added', 1, '2026-06-08 10:15:00.000000'),
(15, 'Account statement available', 0, '2026-06-09 08:30:00.000000'),
(16, 'Credit limit increased', 1, '2026-06-09 09:45:00.000000'),
(17, 'Failed login attempt detected', 0, '2026-06-10 10:00:00.000000'),
(18, 'Your transfer was successful', 1, '2026-06-10 11:15:00.000000'),
(19, 'New feature: Mobile check deposit', 0, '2026-06-11 08:00:00.000000'),
(20, 'Account freeze notification', 1, '2026-06-11 09:30:00.000000'),
(21, 'Payment received', 1, '2026-06-12 10:45:00.000000'),
(22, 'Your card expires soon', 0, '2026-06-12 12:00:00.000000'),
(23, 'Interest rate update', 0, '2026-06-13 08:15:00.000000'),
(24, 'Maintenance scheduled', 1, '2026-06-13 09:30:00.000000'),
(25, 'Fraud alert notification', 1, '2026-06-14 10:00:00.000000'),
(26, 'New statement available', 0, '2026-06-14 11:15:00.000000'),
(27, 'Your loan has been approved', 1, '2026-06-15 08:30:00.000000'),
(28, 'Weekly account summary', 0, '2026-06-15 09:45:00.000000'),
(29, 'Security update required', 1, '2026-06-16 10:00:00.000000'),
(30, 'Transfer limit changed', 0, '2026-06-16 11:30:00.000000'),
(31, 'Welcome bonus credited', 1, '2026-06-17 08:00:00.000000'),
(32, 'Your profile has been updated', 0, '2026-06-17 09:15:00.000000'),
(33, 'New login from unknown location', 1, '2026-06-18 10:30:00.000000'),
(34, 'Account verification needed', 0, '2026-06-18 11:45:00.000000'),
(35, 'Thank you for banking with us', 1, '2026-06-19 08:00:00.000000'),
(36, 'Your debit card has been issued', 0, '2026-06-19 09:30:00.000000'),
(37, 'Important: Terms updated', 1, '2026-06-20 10:00:00.000000'),
(38, 'Transaction failed', 1, '2026-06-20 11:15:00.000000'),
(39, 'Monthly fee deducted', 0, '2026-06-21 08:45:00.000000'),
(40, 'Your account is now active', 1, '2026-06-21 10:00:00.000000'),
(41, 'Pending transaction approved', 0, '2026-06-22 09:30:00.000000'),
(42, 'New beneficiary added', 1, '2026-06-22 10:45:00.000000'),
(43, 'Your loan payment was received', 0, '2026-06-23 08:15:00.000000'),
(44, 'Daily limit increased', 1, '2026-06-23 09:30:00.000000'),
(45, 'Account alert: Low balance', 0, '2026-06-24 10:00:00.000000'),
(46, 'Direct deposit set up', 1, '2026-06-24 11:15:00.000000'),
(47, 'Your card is ready for activation', 0, '2026-06-25 08:30:00.000000'),
(48, 'New security feature added', 1, '2026-06-25 09:45:00.000000'),
(49, 'Payment reminder: Loan due', 0, '2026-06-26 10:00:00.000000'),
(50, 'Transaction limit reached', 1, '2026-06-26 11:30:00.000000'),
(51, 'Account summary - June', 0, '2026-06-27 08:00:00.000000'),
(52, 'Your beneficiary was removed', 1, '2026-06-27 09:15:00.000000'),
(53, 'New login from mobile app', 0, '2026-06-28 10:30:00.000000'),
(54, 'Bank holiday schedule', 1, '2026-06-28 11:45:00.000000'),
(55, 'Your account has been locked', 1, '2026-06-29 08:00:00.000000'),
(56, 'Please contact support', 0, '2026-06-29 09:30:00.000000'),
(57, 'Your transfer was completed', 1, '2026-06-30 10:00:00.000000'),
(58, 'Monthly rewards available', 0, '2026-06-30 11:15:00.000000'),
(59, 'Account anniversary bonus', 1, '2026-07-01 08:30:00.000000'),
(60, 'Thank you for being valued customer', 0, '2026-07-01 09:45:00.000000');


