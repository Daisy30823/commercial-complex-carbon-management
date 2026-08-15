use commercial_complex_carbon_db;

delimiter $$

drop procedure if exists sp_add_multi_complex_indexes$$
create procedure sp_add_multi_complex_indexes()
begin
    if not exists(
        select 1 from information_schema.statistics
        where table_schema=database()
          and table_name='energy_consumption_record'
          and index_name='idx_energy_device_date'
    ) then
        create index idx_energy_device_date
            on energy_consumption_record(meter_device_id,record_date,energy_type_id);
    end if;

    if not exists(
        select 1 from information_schema.statistics
        where table_schema=database()
          and table_name='operation_log'
          and index_name='idx_log_time_type'
    ) then
        create index idx_log_time_type
            on operation_log(operation_time,module_name,business_type,user_id);
    end if;
end$$

delimiter ;

call sp_add_multi_complex_indexes();

