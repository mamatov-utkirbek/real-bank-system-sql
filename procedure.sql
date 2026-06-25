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


exec update_account_status 33;



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


