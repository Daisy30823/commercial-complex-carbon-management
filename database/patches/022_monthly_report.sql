use commercial_complex_carbon_db;

delimiter $$
drop procedure if exists sp_generate_monthly_carbon_report_dataset$$
create procedure sp_generate_monthly_carbon_report_dataset(in p_complex_id bigint unsigned,in p_year int,in p_month int)
begin
    declare v_start date;
    declare v_end date;
    set v_start=str_to_date(concat(p_year,'-',lpad(p_month,2,'0'),'-01'),'%Y-%m-%d');
    set v_end=last_day(v_start);
    select cc.complex_id,cc.complex_name,p_year report_year,p_month report_month,v_start period_start,v_end period_end,
      min(ecr.record_date) actual_start_date,max(ecr.record_date) actual_end_date,count(distinct ecr.record_date) covered_days,day(v_end) expected_days,
      (select count(*)*day(v_end) from meter_device dx join meter_node nx on nx.meter_node_id=dx.meter_node_id where nx.complex_id=p_complex_id and dx.device_status=1) expected_record_count,
      count(ecr.energy_record_id) actual_record_count,count(ecr.energy_record_id) energy_record_count,count(car.carbon_accounting_id) carbon_record_count,
      round(sum(ecr.consumption_amount*coalesce(et.standard_coal_coefficient,0)),6) total_energy_tce,
      round(sum(ecr.energy_cost),2) total_energy_cost,round(sum(coalesce(car.carbon_emission_kg,0)),6) total_carbon_kg,
      round(count(distinct ecr.record_date)/day(v_end)*100,2) date_completeness_rate,if(count(distinct ecr.record_date)=day(v_end),1,0) complete_month_flag,
      (select count(*) from merchant_energy_bill b where b.complex_id=p_complex_id and b.bill_year=p_year and b.bill_month=p_month and b.bill_status<>2) merchant_bill_count,
      (select count(*) from alert_event a where a.complex_id=p_complex_id and a.occurred_at between v_start and date_add(v_end,interval 1 day)) alert_count,
      (select count(*) from corrective_task t join alert_event a on a.alert_event_id=t.alert_event_id where a.complex_id=p_complex_id and t.created_at between v_start and date_add(v_end,interval 1 day)) corrective_task_count
    from commercial_complex cc
    left join meter_node mn on mn.complex_id=cc.complex_id
    left join meter_device md on md.meter_node_id=mn.meter_node_id
    left join energy_consumption_record ecr on ecr.meter_device_id=md.meter_device_id and ecr.record_date between v_start and v_end
    left join energy_type et on et.energy_type_id=ecr.energy_type_id
    left join carbon_accounting_record car on car.energy_record_id=ecr.energy_record_id
    where cc.complex_id=p_complex_id group by cc.complex_id,cc.complex_name;
end$$
delimiter ;
