use commercial_complex_carbon_db;

delimiter $$

drop procedure if exists sp_preview_merchant_bill_allocation$$
create procedure sp_preview_merchant_bill_allocation(
    in p_complex_id bigint unsigned,
    in p_year int,
    in p_month int,
    in p_allocation_method varchar(30)
)
begin
    declare v_start date;
    declare v_end date;
    set v_start = str_to_date(concat(p_year, '-', lpad(p_month,2,'0'), '-01'), '%Y-%m-%d');
    set v_end = last_day(v_start);

    with eligible as (
        select m.merchant_id, m.merchant_code, m.merchant_name,
               sum(case coalesce(p_allocation_method,'lease_area')
                   when 'contract_ratio' then greatest(mo.shared_energy_ratio,0)
                   when 'manual' then greatest(mo.shared_energy_ratio,0)
                   when 'operating_days' then greatest(datediff(least(coalesce(mo.occupancy_end_date,v_end),v_end), greatest(mo.occupancy_start_date,v_start))+1,0)
                   else greatest(mo.lease_area,0) end) allocation_base
        from merchant m
        join merchant_occupancy mo on mo.merchant_id=m.merchant_id
        where m.complex_id=p_complex_id and m.merchant_status=1 and mo.current_valid_flag=1
          and mo.occupancy_start_date<=v_end and coalesce(mo.occupancy_end_date,v_end)>=v_start
        group by m.merchant_id,m.merchant_code,m.merchant_name
    ), base_weights as (
        select e.*, case when sum(allocation_base) over()>0 then allocation_base/sum(allocation_base) over() else 0 end raw_weight from eligible e
    ), weights as (
        select b.*,case when row_number() over(order by merchant_id)=count(*) over() then 1-coalesce(sum(raw_weight) over(order by merchant_id rows between unbounded preceding and 1 preceding),0) else raw_weight end allocation_weight from base_weights b
    ), direct_data as (
        select mn.merchant_id, ecr.energy_type_id, et.energy_name, et.standard_unit,
               sum(ecr.consumption_amount) consumption_amount,
               sum(ecr.consumption_amount*coalesce(et.standard_coal_coefficient,0)) energy_tce,
               sum(ecr.energy_cost) energy_cost, sum(coalesce(car.carbon_emission_kg,0)) carbon_kg
        from energy_consumption_record ecr
        join meter_device md on md.meter_device_id=ecr.meter_device_id
        join meter_node mn on mn.meter_node_id=md.meter_node_id
        join energy_type et on et.energy_type_id=ecr.energy_type_id
        left join carbon_accounting_record car on car.energy_record_id=ecr.energy_record_id
        where mn.complex_id=p_complex_id and mn.merchant_id is not null and ecr.record_date between v_start and v_end
        group by mn.merchant_id,ecr.energy_type_id,et.energy_name,et.standard_unit
    ), public_data as (
        select ecr.energy_type_id, et.energy_name, et.standard_unit,
               sum(ecr.consumption_amount) consumption_amount,
               sum(ecr.consumption_amount*coalesce(et.standard_coal_coefficient,0)) energy_tce,
               sum(ecr.energy_cost) energy_cost, sum(coalesce(car.carbon_emission_kg,0)) carbon_kg
        from energy_consumption_record ecr
        join meter_device md on md.meter_device_id=ecr.meter_device_id
        join meter_node mn on mn.meter_node_id=md.meter_node_id
        join energy_type et on et.energy_type_id=ecr.energy_type_id
        left join functional_area fa on fa.area_id=mn.area_id
        left join carbon_accounting_record car on car.energy_record_id=ecr.energy_record_id
        where mn.complex_id=p_complex_id and mn.merchant_id is null and ecr.record_date between v_start and v_end
          and (coalesce(fa.public_area_flag,0)=1 or mn.node_type in ('root','building','area','public','virtual'))
        group by ecr.energy_type_id,et.energy_name,et.standard_unit
    ), merchant_energy as (
        select w.merchant_id,w.merchant_code,w.merchant_name,w.allocation_base,w.allocation_weight,
               et.energy_type_id,et.energy_name,et.standard_unit,
               coalesce(d.consumption_amount,0) direct_consumption,
               coalesce(p.consumption_amount,0)*w.allocation_weight allocated_consumption,
               coalesce(d.energy_cost,0) direct_cost,coalesce(p.energy_cost,0)*w.allocation_weight allocated_cost,
               coalesce(d.energy_tce,0) direct_tce,coalesce(p.energy_tce,0)*w.allocation_weight allocated_tce,
               coalesce(d.carbon_kg,0) direct_carbon_kg,coalesce(p.carbon_kg,0)*w.allocation_weight allocated_carbon_kg
        from weights w cross join energy_type et
        left join direct_data d on d.merchant_id=w.merchant_id and d.energy_type_id=et.energy_type_id
        left join public_data p on p.energy_type_id=et.energy_type_id
        where et.energy_status=1 and (coalesce(d.consumption_amount,0)<>0 or coalesce(p.consumption_amount,0)<>0)
    )
    select *, direct_consumption+allocated_consumption total_consumption,
           direct_cost+allocated_cost total_cost,direct_tce+allocated_tce total_tce,
           direct_carbon_kg+allocated_carbon_kg total_carbon_kg
    from merchant_energy order by merchant_name,energy_type_id;
end$$

drop procedure if exists sp_generate_merchant_energy_bills$$
create procedure sp_generate_merchant_energy_bills(
    in p_complex_id bigint unsigned,
    in p_year int,
    in p_month int,
    in p_allocation_method varchar(30),
    in p_user_id bigint unsigned
)
begin
    declare v_rule_id bigint unsigned;
    declare v_start date;
    declare v_end date;
    declare v_version int default 1;
    declare v_merchant_count int default 0;
    declare v_completeness decimal(8,4) default 0;
    set v_start=str_to_date(concat(p_year,'-',lpad(p_month,2,'0'),'-01'),'%Y-%m-%d');
    set v_end=last_day(v_start);
    select allocation_rule_id into v_rule_id from energy_allocation_rule
      where complex_id=p_complex_id and active_flag=1 and allocation_method=coalesce(p_allocation_method,'lease_area')
      and effective_date<=v_end and (expiry_date is null or expiry_date>=v_start)
      order by effective_date desc limit 1;
    if v_rule_id is null then signal sqlstate '45000' set message_text='未找到有效的公共能耗分摊规则'; end if;
    select coalesce(max(version_no),0)+1 into v_version from merchant_energy_bill where complex_id=p_complex_id and bill_year=p_year and bill_month=p_month;
    select round(count(distinct e.record_date)/day(v_end)*100,4) into v_completeness from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between v_start and v_end;

    drop temporary table if exists tmp_bill_preview;
    create temporary table tmp_bill_preview (
      merchant_id bigint unsigned, merchant_code varchar(50), merchant_name varchar(120), allocation_base decimal(20,6), allocation_weight decimal(18,10),
      energy_type_id bigint unsigned, energy_name varchar(60), standard_unit varchar(30), direct_consumption decimal(20,6), allocated_consumption decimal(20,6),
      direct_cost decimal(20,2), allocated_cost decimal(20,2), direct_tce decimal(20,8), allocated_tce decimal(20,8), direct_carbon_kg decimal(20,6), allocated_carbon_kg decimal(20,6)
    );
    insert into tmp_bill_preview
    with eligible as (
      select m.merchant_id,m.merchant_code,m.merchant_name,sum(case coalesce(p_allocation_method,'lease_area') when 'contract_ratio' then greatest(mo.shared_energy_ratio,0) when 'manual' then greatest(mo.shared_energy_ratio,0) when 'operating_days' then greatest(datediff(least(coalesce(mo.occupancy_end_date,v_end),v_end),greatest(mo.occupancy_start_date,v_start))+1,0) else greatest(mo.lease_area,0) end) allocation_base
      from merchant m join merchant_occupancy mo on mo.merchant_id=m.merchant_id where m.complex_id=p_complex_id and m.merchant_status=1 and mo.current_valid_flag=1 and mo.occupancy_start_date<=v_end and coalesce(mo.occupancy_end_date,v_end)>=v_start group by m.merchant_id,m.merchant_code,m.merchant_name
    ), base_weights as (select e.*,case when sum(allocation_base) over()>0 then allocation_base/sum(allocation_base) over() else 0 end raw_weight from eligible e),
    weights as (select b.*,case when row_number() over(order by merchant_id)=count(*) over() then 1-coalesce(sum(raw_weight) over(order by merchant_id rows between unbounded preceding and 1 preceding),0) else raw_weight end allocation_weight from base_weights b),
    direct_data as (select mn.merchant_id,ecr.energy_type_id,sum(ecr.consumption_amount) amount,sum(ecr.energy_cost) cost,sum(ecr.consumption_amount*coalesce(et.standard_coal_coefficient,0)) tce,sum(coalesce(car.carbon_emission_kg,0)) carbon from energy_consumption_record ecr join meter_device md on md.meter_device_id=ecr.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id join energy_type et on et.energy_type_id=ecr.energy_type_id left join carbon_accounting_record car on car.energy_record_id=ecr.energy_record_id where mn.complex_id=p_complex_id and mn.merchant_id is not null and ecr.record_date between v_start and v_end group by mn.merchant_id,ecr.energy_type_id),
    public_data as (select ecr.energy_type_id,sum(ecr.consumption_amount) amount,sum(ecr.energy_cost) cost,sum(ecr.consumption_amount*coalesce(et.standard_coal_coefficient,0)) tce,sum(coalesce(car.carbon_emission_kg,0)) carbon from energy_consumption_record ecr join meter_device md on md.meter_device_id=ecr.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id join energy_type et on et.energy_type_id=ecr.energy_type_id left join functional_area fa on fa.area_id=mn.area_id left join carbon_accounting_record car on car.energy_record_id=ecr.energy_record_id where mn.complex_id=p_complex_id and mn.merchant_id is null and ecr.record_date between v_start and v_end and (coalesce(fa.public_area_flag,0)=1 or mn.node_type in ('root','building','area','public','virtual')) group by ecr.energy_type_id)
    select w.merchant_id,w.merchant_code,w.merchant_name,w.allocation_base,w.allocation_weight,et.energy_type_id,et.energy_name,et.standard_unit,coalesce(d.amount,0),coalesce(p.amount,0)*w.allocation_weight,coalesce(d.cost,0),coalesce(p.cost,0)*w.allocation_weight,coalesce(d.tce,0),coalesce(p.tce,0)*w.allocation_weight,coalesce(d.carbon,0),coalesce(p.carbon,0)*w.allocation_weight
    from weights w cross join energy_type et left join direct_data d on d.merchant_id=w.merchant_id and d.energy_type_id=et.energy_type_id left join public_data p on p.energy_type_id=et.energy_type_id where et.energy_status=1 and (coalesce(d.amount,0)<>0 or coalesce(p.amount,0)<>0);

    select count(distinct merchant_id) into v_merchant_count from tmp_bill_preview;
    if v_merchant_count=0 then signal sqlstate '45000' set message_text='所选月份没有有效入驻商户或可分摊数据'; end if;
    update merchant_energy_bill set current_version_flag=0 where complex_id=p_complex_id and bill_year=p_year and bill_month=p_month and current_version_flag=1;
    insert into merchant_energy_bill (complex_id,merchant_id,allocation_rule_id,bill_code,bill_year,bill_month,version_no,current_version_flag,period_start,period_end,direct_energy_cost,allocated_energy_cost,total_energy_cost,direct_energy_tce,allocated_energy_tce,total_energy_tce,total_standard_coal_tce,direct_carbon_kg,allocated_carbon_kg,total_carbon_kg,data_completeness_rate,allocation_weight,bill_status,generated_by_user_id,generated_at,remark)
    select p_complex_id,merchant_id,v_rule_id,concat('meb-',p_complex_id,'-',p_year,lpad(p_month,2,'0'),'-',merchant_id,'-v',v_version),p_year,p_month,v_version,1,v_start,v_end,sum(direct_cost),sum(allocated_cost),sum(direct_cost+allocated_cost),sum(direct_tce),sum(allocated_tce),sum(direct_tce+allocated_tce),sum(direct_tce+allocated_tce),sum(direct_carbon_kg),sum(allocated_carbon_kg),sum(direct_carbon_kg+allocated_carbon_kg),v_completeness,max(allocation_weight),0,p_user_id,now(),'课程设计模拟管理账单，不作为正式结算或碳核证依据'
    from tmp_bill_preview group by merchant_id;
    insert into merchant_energy_bill_detail (merchant_energy_bill_id,energy_type_id,source_type,consumption_amount,consumption_unit,standard_coal_tce,energy_cost,carbon_emission_kg,allocation_base_amount,allocation_weight,calculation_snapshot)
    select b.merchant_energy_bill_id,t.energy_type_id,'direct',t.direct_consumption,t.standard_unit,t.direct_tce,t.direct_cost,t.direct_carbon_kg,t.allocation_base,t.allocation_weight,json_object('method',p_allocation_method,'periodStart',v_start,'periodEnd',v_end)
    from tmp_bill_preview t join merchant_energy_bill b on b.complex_id=p_complex_id and b.merchant_id=t.merchant_id and b.bill_year=p_year and b.bill_month=p_month and b.version_no=v_version where t.direct_consumption<>0
    on duplicate key update consumption_amount=values(consumption_amount),standard_coal_tce=values(standard_coal_tce),energy_cost=values(energy_cost),carbon_emission_kg=values(carbon_emission_kg),calculation_snapshot=values(calculation_snapshot);
    insert into merchant_energy_bill_detail (merchant_energy_bill_id,energy_type_id,source_type,consumption_amount,consumption_unit,standard_coal_tce,energy_cost,carbon_emission_kg,allocation_base_amount,allocation_weight,calculation_snapshot)
    select b.merchant_energy_bill_id,t.energy_type_id,'allocated',t.allocated_consumption,t.standard_unit,t.allocated_tce,t.allocated_cost,t.allocated_carbon_kg,t.allocation_base,t.allocation_weight,json_object('method',p_allocation_method,'periodStart',v_start,'periodEnd',v_end)
    from tmp_bill_preview t join merchant_energy_bill b on b.complex_id=p_complex_id and b.merchant_id=t.merchant_id and b.bill_year=p_year and b.bill_month=p_month and b.version_no=v_version where t.allocated_consumption<>0
    on duplicate key update consumption_amount=values(consumption_amount),standard_coal_tce=values(standard_coal_tce),energy_cost=values(energy_cost),carbon_emission_kg=values(carbon_emission_kg),allocation_base_amount=values(allocation_base_amount),allocation_weight=values(allocation_weight),calculation_snapshot=values(calculation_snapshot);
    select count(*) generated_count,v_version version_no,v_completeness data_completeness_rate,sum(total_energy_cost) total_cost,sum(total_energy_tce) total_tce,sum(total_carbon_kg) total_carbon_kg from merchant_energy_bill where complex_id=p_complex_id and bill_year=p_year and bill_month=p_month and version_no=v_version;
end$$

drop procedure if exists sp_query_merchant_energy_bills$$
create procedure sp_query_merchant_energy_bills(in p_complex_id bigint unsigned,in p_year int,in p_month int,in p_merchant_id bigint unsigned,in p_status tinyint)
begin
 select b.*,m.merchant_code,m.merchant_name,r.rule_name,r.allocation_method,(select count(*) from data_quality_issue q left join energy_consumption_record er on er.energy_record_id=q.energy_record_id where q.complex_id=b.complex_id and q.issue_status in(0,1) and (er.record_date between b.period_start and b.period_end or er.energy_record_id is null)) open_quality_issues from merchant_energy_bill b join merchant m on m.merchant_id=b.merchant_id left join energy_allocation_rule r on r.allocation_rule_id=b.allocation_rule_id where b.complex_id=p_complex_id and b.current_version_flag=1 and (p_year is null or b.bill_year=p_year) and (p_month is null or b.bill_month=p_month) and (p_merchant_id is null or b.merchant_id=p_merchant_id) and (p_status is null or b.bill_status=p_status) order by b.bill_year desc,b.bill_month desc,m.merchant_name;
end$$

drop procedure if exists sp_confirm_merchant_energy_bill$$
create procedure sp_confirm_merchant_energy_bill(in p_bill_id bigint unsigned,in p_user_id bigint unsigned)
begin
 if exists(select 1 from merchant_energy_bill where merchant_energy_bill_id=p_bill_id and data_completeness_rate<95) then signal sqlstate '45000' set message_text='数据完整率低于95%，账单只能保留为草稿'; end if;
 if exists(select 1 from merchant_energy_bill b join data_quality_issue q on q.complex_id=b.complex_id left join energy_consumption_record er on er.energy_record_id=q.energy_record_id where b.merchant_energy_bill_id=p_bill_id and q.issue_status in(0,1) and q.severity_level='高' and (er.record_date between b.period_start and b.period_end or er.energy_record_id is null)) then signal sqlstate '45000' set message_text='账期存在未解决的高风险数据质量问题，不能确认'; end if;
 update merchant_energy_bill set bill_status=1,confirmed_by_user_id=p_user_id,confirmed_at=now() where merchant_energy_bill_id=p_bill_id and bill_status=0 and current_version_flag=1; select row_count() affected_rows;
end$$

drop procedure if exists sp_void_merchant_energy_bill$$
create procedure sp_void_merchant_energy_bill(in p_bill_id bigint unsigned,in p_user_id bigint unsigned,in p_reason varchar(500))
begin if trim(coalesce(p_reason,''))='' then signal sqlstate '45000' set message_text='作废原因不能为空'; end if; update merchant_energy_bill set bill_status=2,voided_by_user_id=p_user_id,voided_at=now(),void_reason=p_reason where merchant_energy_bill_id=p_bill_id and bill_status in (0,1); select row_count() affected_rows; end$$

delimiter ;
