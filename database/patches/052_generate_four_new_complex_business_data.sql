delimiter $$

drop procedure if exists sp_generate_four_new_complex_business_data$$
create procedure sp_generate_four_new_complex_business_data()
begin
    declare v_complex_no int default 1;
    declare v_i int;
    declare v_day int;
    declare v_complex_id bigint unsigned;
    declare v_complex_code varchar(40);
    declare v_complex_name varchar(120);
    declare v_prefix varchar(10);
    declare v_department_id bigint unsigned;
    declare v_building_id bigint unsigned;
    declare v_area_id bigint unsigned;
    declare v_merchant_id bigint unsigned;
    declare v_root_id bigint unsigned;
    declare v_parent_id bigint unsigned;
    declare v_node_id bigint unsigned;
    declare v_device_id bigint unsigned;
    declare v_energy_type_id bigint unsigned;
    declare v_unit varchar(30);
    declare v_date date;
    declare v_consumption decimal(20,6);
    declare v_start_reading decimal(20,6);
    declare v_budget_id bigint unsigned;
    declare v_rule_id bigint unsigned;
    declare v_alert_id bigint unsigned;
    declare v_project_id bigint unsigned;
    declare v_admin_id bigint unsigned;
    declare v_password_hash varchar(255);
    declare v_bill_index int;
    declare v_bill_date date;
    declare v_scaled_count int default 0;

    select user_id,password_hash into v_admin_id,v_password_hash from app_user where username='admin' limit 1;

    while v_complex_no <= 4 do
        set v_complex_code = case v_complex_no when 1 then 'wzcc001' when 2 then 'jhcc001' when 3 then 'huzh001' else 'tzcc001' end;
        set v_prefix = case v_complex_no when 1 then 'wz' when 2 then 'jh' when 3 then 'hu' else 'tz' end;
        select complex_id,complex_name into v_complex_id,v_complex_name from commercial_complex where complex_code=v_complex_code and record_status=1;

        set v_i=1;
        while v_i<=5 do
            insert into property_department(complex_id,department_code,department_name,department_type,department_level,department_path,manager_name,contact_phone,office_location,responsibility,sort_no,department_status,remark)
            select v_complex_id,concat(v_prefix,'-dept-',lpad(v_i,2,'0')),
                   case v_i when 1 then '运营管理部' when 2 then '工程能源部' when 3 then '安全品质部' when 4 then '客户服务部' else '财务管理部' end,
                   case v_i when 2 then '工程' when 3 then '安全' else '管理' end,1,concat('/',v_prefix,'/dept/',v_i),
                   concat(case v_i when 1 then '陈' when 2 then '林' when 3 then '周' when 4 then '沈' else '许' end,'经理'),
                   concat('0571-88',lpad(v_complex_no*100+v_i,6,'0')),'综合体管理中心',
                   case v_i when 1 then '运营协调与经营管理' when 2 then '能源计量与设备运维' when 3 then '安全检查与品质管理' when 4 then '商户服务与客户沟通' else '预算与成本管理' end,
                   v_i,1,'综合体常设业务部门'
            where not exists(select 1 from property_department where department_code=concat(v_prefix,'-dept-',lpad(v_i,2,'0')));

            select department_id into v_department_id from property_department where department_code=concat(v_prefix,'-dept-',lpad(v_i,2,'0'));
            insert into app_user(department_id,username,password_hash,real_name,gender,employee_no,job_title,phone,email,user_status,remark)
            select v_department_id,concat(v_prefix,'_operator_',v_i),v_password_hash,
                   concat(case v_i when 1 then '陈' when 2 then '林' when 3 then '周' when 4 then '沈' else '许' end,case v_complex_no when 1 then '杭' when 2 then '甬' when 3 then '越' else '禾' end),
                   case when mod(v_i,2)=0 then 2 else 1 end,concat(upper(v_prefix),'E',lpad(v_i,3,'0')),
                   case v_i when 1 then '运营主管' when 2 then '能源工程师' when 3 then '品质主管' when 4 then '客户主管' else '财务主管' end,
                   concat('138000',v_complex_no,lpad(v_i,3,'0')),concat(v_prefix,'_operator_',v_i,'@energy.local'),1,'综合体业务用户'
            where not exists(select 1 from app_user where username=concat(v_prefix,'_operator_',v_i));
            set v_i=v_i+1;
        end while;

        insert into energy_allocation_rule(complex_id,rule_code,rule_name,allocation_method,parameters_json,effective_date,active_flag,rule_config,remark,created_by_user_id)
        select v_complex_id,concat(v_prefix,'-lease-area-rule'),'公共能耗按租赁面积分摊','lease_area',json_object('basis','lease_area'),date('2020-01-01'),1,json_object('precision',10),'在用公共能耗分摊规则',v_admin_id
        where not exists(
            select 1 from energy_allocation_rule
            where complex_id=v_complex_id and allocation_method='lease_area' and active_flag=1
        );

        set v_i=1;
        while v_i<=5 do
            select department_id into v_department_id from property_department where department_code=concat(v_prefix,'-dept-',lpad(mod(v_i,5)+1,2,'0'));
            insert into building(complex_id,managing_department_id,building_code,building_name,building_type,address_detail,gross_floor_area,above_ground_floors,underground_floors,air_conditioning_area,energy_management_grade,record_status,sort_no,remark)
            select v_complex_id,v_department_id,concat(v_prefix,'-b-',lpad(v_i,2,'0')),
                   concat(v_complex_name,case v_i when 1 then '商业主楼' when 2 then '办公塔楼' when 3 then '服务配套楼' when 4 then '地下停车建筑' else '能源设备中心' end),
                   case v_i when 1 then '商业' when 2 then '办公' when 3 then '服务' when 4 then '停车' else '设备' end,
                   concat('综合体',v_i,'号分区'),16000+v_i*4200,case v_i when 2 then 18 when 4 then 1 else 6+v_i end,case when v_i=4 then 3 else 1 end,12000+v_i*2500,'一级',1,v_i,'综合体正式运营建筑'
            where not exists(select 1 from building where building_code=concat(v_prefix,'-b-',lpad(v_i,2,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=15 do
            select building_id into v_building_id from building where building_code=concat(v_prefix,'-b-',lpad(mod(v_i-1,5)+1,2,'0'));
            select department_id into v_department_id from property_department where department_code=concat(v_prefix,'-dept-',lpad(mod(v_i-1,5)+1,2,'0'));
            insert into functional_area(building_id,responsible_department_id,area_code,area_name,area_type,floor_no,zone_name,gross_area,rentable_area,public_area_flag,opening_time,closing_time,design_capacity,operation_status,energy_management_level,carbon_budget_enabled,record_status,sort_no,remark)
            select v_building_id,v_department_id,concat(v_prefix,'-a-',lpad(v_i,2,'0')),
                   concat(case v_i when 1 then '一层零售区' when 2 then '二层零售区' when 3 then '特色餐饮区' when 4 then '影院娱乐区' when 5 then '亲子活动区' when 6 then '运动健身区' when 7 then '公共走廊与中庭' when 8 then '地下停车场' when 9 then '中央空调机房' when 10 then '高低压配电房' when 11 then '运营办公区' when 12 then '仓储后勤区' when 13 then '屋顶设备区' when 14 then '生活服务区' else '综合服务区' end),
                   case when v_i in (1,2) then '零售' when v_i=3 then '餐饮' when v_i in (4,5,6) then '娱乐' when v_i=8 then '停车' when v_i in (9,10,13) then '设备' when v_i=11 then '办公' when v_i=12 then '后勤' else '公共' end,
                   concat(mod(v_i-1,5)+1,'f'),concat(char(64+mod(v_i-1,5)+1),'区'),1200+v_i*170,case when v_i in (7,8,9,10,13) then 0 else 900+v_i*120 end,
                   case when v_i in (7,8,9,10,13) then 1 else 0 end,'10:00:00','22:00:00',500+v_i*80,'正常','重点',1,1,v_i,'综合体功能分区'
            where not exists(select 1 from functional_area where area_code=concat(v_prefix,'-a-',lpad(v_i,2,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=18 do
            insert into merchant(complex_id,merchant_code,merchant_name,brand_name,merchant_category,contact_name,contact_phone,contact_email,planned_business_hours,operating_area,employee_count,high_energy_flag,risk_level,settlement_mode,merchant_status,entry_date,remark)
            select v_complex_id,concat(v_prefix,'-m-',lpad(v_i,2,'0')),
                   concat(case mod(v_i-1,10) when 0 then '青禾生活馆' when 1 then '云杉餐厅' when 2 then '悦读书店' when 3 then '星幕影城' when 4 then '活力健身中心' when 5 then '童趣成长空间' when 6 then '清露咖啡' when 7 then '智选数码馆' when 8 then '邻里生活服务' else '丰味食品集合店' end,lpad(v_i,2,'0')),
                   concat('城市优选',lpad(v_i,2,'0')),case mod(v_i-1,10) when 0 then '零售' when 1 then '餐饮' when 2 then '书店' when 3 then '影院' when 4 then '健身' when 5 then '亲子娱乐' when 6 then '咖啡' when 7 then '数码' when 8 then '生活服务' else '超市' end,
                   concat('联系人',v_i),concat('139',v_complex_no,lpad(v_i,7,'0')),concat(v_prefix,'m',v_i,'@merchant.local'),'10:00-22:00',180+v_i*35,8+mod(v_i,20),case when mod(v_i,6)=0 then 1 else 0 end,'低','按月结算',1,date_sub(curdate(),interval 500+v_i day),'在营商户'
            where not exists(select 1 from merchant where merchant_code=concat(v_prefix,'-m-',lpad(v_i,2,'0')));
            select merchant_id into v_merchant_id from merchant where merchant_code=concat(v_prefix,'-m-',lpad(v_i,2,'0'));
            select area_id into v_area_id from functional_area where area_code=concat(v_prefix,'-a-',lpad(mod(v_i-1,10)+1,2,'0'));
            insert into merchant_occupancy(merchant_id,area_id,contract_code,occupancy_start_date,lease_area,lease_purpose,rent_calculation_mode,energy_settlement_mode,shared_energy_ratio,contract_status,current_valid_flag,signed_by_user_id,signed_at,remark)
            select v_merchant_id,v_area_id,concat(v_prefix,'-contract-',lpad(v_i,2,'0')),date_sub(curdate(),interval 500+v_i day),180+v_i*35,'商业经营','固定租金','按表计量',0.02+mod(v_i,8)*0.005,1,1,v_admin_id,date_sub(now(),interval 500+v_i day),'有效入驻关系'
            where not exists(select 1 from merchant_occupancy where contract_code=concat(v_prefix,'-contract-',lpad(v_i,2,'0')));
            set v_i=v_i+1;
        end while;

        insert into meter_node(complex_id,energy_type_id,node_code,node_name,node_type,node_level,node_path,allocation_method,allocation_ratio,virtual_node_flag,leaf_node_flag,data_aggregation_flag,carbon_accounting_flag,node_status,sort_no,remark)
        select v_complex_id,1,concat(v_prefix,'-root'),concat(v_complex_name,'总计量节点'),'root',1,concat('/',v_prefix),'direct',1,1,0,1,1,1,1,'综合体总计量节点'
        where not exists(select 1 from meter_node where node_code=concat(v_prefix,'-root'));
        select meter_node_id into v_root_id from meter_node where node_code=concat(v_prefix,'-root');

        set v_i=1;
        while v_i<=5 do
            select building_id into v_building_id from building where building_code=concat(v_prefix,'-b-',lpad(v_i,2,'0'));
            insert into meter_node(complex_id,building_id,energy_type_id,parent_node_id,node_code,node_name,node_type,node_level,node_path,allocation_method,allocation_ratio,virtual_node_flag,leaf_node_flag,data_aggregation_flag,carbon_accounting_flag,node_status,sort_no,remark)
            select v_complex_id,v_building_id,1,v_root_id,concat(v_prefix,'-bn-',lpad(v_i,2,'0')),concat('建筑计量节点-',lpad(v_i,2,'0')),'building',2,concat('/',v_prefix,'/b',v_i),'direct',1,1,0,1,1,1,v_i,'建筑级计量节点'
            where not exists(select 1 from meter_node where node_code=concat(v_prefix,'-bn-',lpad(v_i,2,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=15 do
            select area_id,building_id into v_area_id,v_building_id from functional_area where area_code=concat(v_prefix,'-a-',lpad(v_i,2,'0'));
            select meter_node_id into v_parent_id from meter_node where node_code=concat(v_prefix,'-bn-',lpad(mod(v_i-1,5)+1,2,'0'));
            insert into meter_node(complex_id,building_id,area_id,energy_type_id,parent_node_id,node_code,node_name,node_type,node_level,node_path,allocation_method,allocation_ratio,virtual_node_flag,leaf_node_flag,data_aggregation_flag,carbon_accounting_flag,node_status,sort_no,remark)
            select v_complex_id,v_building_id,v_area_id,mod(v_i-1,5)+1,v_parent_id,concat(v_prefix,'-an-',lpad(v_i,2,'0')),concat('功能区域计量节点-',lpad(v_i,2,'0')),'area',3,concat('/',v_prefix,'/a',v_i),'direct',1,0,0,1,1,1,v_i,'区域级计量节点'
            where not exists(select 1 from meter_node where node_code=concat(v_prefix,'-an-',lpad(v_i,2,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=18 do
            select merchant_id into v_merchant_id from merchant where merchant_code=concat(v_prefix,'-m-',lpad(v_i,2,'0'));
            select area_id,building_id into v_area_id,v_building_id from functional_area where area_code=concat(v_prefix,'-a-',lpad(mod(v_i-1,10)+1,2,'0'));
            select meter_node_id into v_parent_id from meter_node where node_code=concat(v_prefix,'-an-',lpad(mod(v_i-1,10)+1,2,'0'));
            insert into meter_node(complex_id,building_id,area_id,merchant_id,energy_type_id,parent_node_id,node_code,node_name,node_type,node_level,node_path,allocation_method,allocation_ratio,virtual_node_flag,leaf_node_flag,data_aggregation_flag,carbon_accounting_flag,node_status,sort_no,remark)
            select v_complex_id,v_building_id,v_area_id,v_merchant_id,mod(v_i-1,5)+1,v_parent_id,concat(v_prefix,'-mn-',lpad(v_i,2,'0')),concat('商户计量节点-',lpad(v_i,2,'0')),'merchant',4,concat('/',v_prefix,'/m',v_i),'direct',1,0,1,1,1,1,v_i,'商户级计量节点'
            where not exists(select 1 from meter_node where node_code=concat(v_prefix,'-mn-',lpad(v_i,2,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=30 do
            set v_energy_type_id=mod(v_i-1,5)+1;
            select meter_node_id into v_node_id from meter_node where node_code=concat(v_prefix,'-an-',lpad(mod(v_i-1,15)+1,2,'0'));
            select standard_unit into v_unit from energy_type where energy_type_id=v_energy_type_id;
            insert into meter_device(meter_node_id,energy_type_id,device_code,device_name,device_type,serial_number,manufacturer,model_number,communication_protocol,communication_address,measuring_unit,multiplier,accuracy_class,collection_frequency_minutes,installation_location,installation_date,commissioning_date,last_collection_time,online_status,device_status,remark)
            select v_node_id,v_energy_type_id,concat(v_prefix,'-d-',lpad(v_i,3,'0')),concat(case v_energy_type_id when 1 then '智能电表' when 2 then '燃气表' when 3 then '智能水表' when 4 then '柴油计量表' else '热量表' end,'-',lpad(v_i,3,'0')),
                   case v_energy_type_id when 1 then '智能电表' when 2 then '燃气表' when 3 then '水表' when 4 then '柴油计量表' else '热量表' end,concat(upper(v_prefix),'SN',lpad(v_i,6,'0')),'城市能源仪表有限公司',concat('em-',v_energy_type_id,'-',v_i),'modbus-tcp',concat(v_prefix,'-addr-',v_i),v_unit,1,'1.0级',60,concat('区域',mod(v_i-1,15)+1),date_sub(curdate(),interval 600 day),date_sub(curdate(),interval 590 day),now(),case when mod(v_i,29)=0 then 0 else 1 end,1,'在用计量设备'
            where not exists(select 1 from meter_device where device_code=concat(v_prefix,'-d-',lpad(v_i,3,'0')));
            set v_i=v_i+1;
        end while;

        set v_day=0;
        while v_day<180 do
            set v_date=date_sub(curdate(),interval v_day day);
            set v_i=1;
            while v_i<=30 do
                select meter_device_id,energy_type_id,measuring_unit into v_device_id,v_energy_type_id,v_unit from meter_device where device_code=concat(v_prefix,'-d-',lpad(v_i,3,'0'));
                set v_consumption=case v_energy_type_id
                    when 1 then 260+v_i*4+if(dayofweek(v_date) in (1,7),75,0)+if(month(v_date) between 6 and 9,120,20)+mod(day(v_date),7)*4
                    when 2 then 35+v_i*1.2+if(dayofweek(v_date) in (1,7),12,0)+mod(day(v_date),5)*2
                    when 3 then 65+v_i*1.8+if(dayofweek(v_date) in (1,7),20,0)+mod(day(v_date),6)*3
                    when 4 then 5+if(mod(dayofyear(v_date)+v_i,30)=0,28,0)
                    else 18+if(month(v_date) in (11,12,1,2),95,12)+mod(day(v_date),5)*3 end;
                if mod(v_day*31+v_i,101)=0 then set v_consumption=v_consumption*1.65; end if;
                set v_start_reading=(180-v_day)*10000+v_i*500;
                insert into energy_consumption_record(meter_device_id,energy_type_id,record_code,record_date,period_start,period_end,start_reading,end_reading,multiplier,consumption_amount,consumption_unit,unit_price,energy_cost,data_source,data_quality_status,abnormal_flag,audit_status,raw_payload,created_by_user_id)
                select v_device_id,v_energy_type_id,concat('mc-',v_prefix,'-',lpad(v_i,3,'0'),'-',date_format(v_date,'%Y%m%d')),v_date,timestamp(v_date,'00:00:00'),timestamp(v_date,'23:59:59'),v_start_reading,v_start_reading+v_consumption,1,v_consumption,v_unit,
                       case v_energy_type_id when 1 then 0.82 when 2 then 3.15 when 3 then 4.20 when 4 then 7.60 else 68.00 end,
                       v_consumption*case v_energy_type_id when 1 then 0.82 when 2 then 3.15 when 3 then 4.20 when 4 then 7.60 else 68.00 end,
                       '自动采集',case when mod(v_day*31+v_i,101)=0 then 4 else 1 end,case when mod(v_day*31+v_i,101)=0 then 1 else 0 end,case when mod(v_day*17+v_i,53)=0 then 0 else 1 end,
                       json_object('source','building-energy-gateway','device',concat(v_prefix,'-d-',lpad(v_i,3,'0')),'date',v_date,'quality',case when mod(v_day*31+v_i,101)=0 then '需要复核' else '正常' end),v_admin_id
                where not exists(select 1 from energy_consumption_record where record_code=concat('mc-',v_prefix,'-',lpad(v_i,3,'0'),'-',date_format(v_date,'%Y%m%d')));
                set v_i=v_i+1;
            end while;
            set v_day=v_day+1;
        end while;

        update energy_consumption_record e
        set e.end_reading=e.start_reading+e.consumption_amount*(0.90+v_complex_no*0.07),
            e.raw_payload=json_set(coalesce(e.raw_payload,json_object()),'$.complex_scale_applied',true,'$.complex_scale',0.90+v_complex_no*0.07)
        where e.record_code like concat('mc-',v_prefix,'-%')
          and json_unquote(json_extract(e.raw_payload,'$.source'))='building-energy-gateway'
          and json_extract(e.raw_payload,'$.complex_scale_applied') is null;
        set v_scaled_count=row_count();

        insert into carbon_budget(complex_id,prepared_department_id,prepared_by_user_id,budget_code,budget_name,budget_year,total_budget_emission_kg,baseline_year,baseline_emission_kg,target_reduction_rate,actual_emission_kg,execution_rate,remaining_budget_kg,preparation_date,effective_date,budget_status,remark)
        select v_complex_id,(select min(department_id) from property_department where complex_id=v_complex_id),v_admin_id,concat(v_prefix,'-budget-',year(curdate())),concat(v_complex_name,year(curdate()),'年度碳预算'),year(curdate()),12000000+v_complex_no*1200000,year(curdate())-1,13500000+v_complex_no*1200000,8.5,0,0,12000000+v_complex_no*1200000,makedate(year(curdate()),1),makedate(year(curdate()),1),1,'年度碳预算'
        where not exists(select 1 from carbon_budget where complex_id=v_complex_id and budget_year=year(curdate()));
        select carbon_budget_id into v_budget_id from carbon_budget where complex_id=v_complex_id and budget_year=year(curdate()) limit 1;
        set v_i=1;
        while v_i<=15 do
            select area_id into v_area_id from functional_area where area_code=concat(v_prefix,'-a-',lpad(v_i,2,'0'));
            insert into carbon_budget_detail(carbon_budget_id,area_id,budget_month,budget_emission_kg,actual_emission_kg,execution_rate,remaining_budget_kg,over_budget_flag,warning_level,audit_status,valid_flag,remark)
            select v_budget_id,v_area_id,months.m,(12000000+v_complex_no*1200000)/180,0,0,(12000000+v_complex_no*1200000)/180,0,'正常',1,1,'月度区域预算'
            from (select 1 m union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9 union all select 10 union all select 11 union all select 12) months
            where not exists(select 1 from carbon_budget_detail d where d.carbon_budget_id=v_budget_id and d.area_id=v_area_id and d.budget_month=months.m);
            set v_i=v_i+1;
        end while;

        insert into carbon_budget_detail(carbon_budget_id,area_id,budget_month,budget_emission_kg,actual_emission_kg,execution_rate,remaining_budget_kg,over_budget_flag,warning_level,audit_status,valid_flag,remark)
        select v_budget_id,a.area_id,months.m,
               (select total_budget_emission_kg from carbon_budget where carbon_budget_id=v_budget_id)/
               ((select count(*) from functional_area fa join building fb on fb.building_id=fa.building_id where fb.complex_id=v_complex_id and fa.record_status=1)*12),
               0,0,0,0,'正常',1,1,'月度区域预算'
        from functional_area a
        join building b on b.building_id=a.building_id
        cross join (select 1 m union all select 2 union all select 3 union all select 4 union all select 5 union all select 6 union all select 7 union all select 8 union all select 9 union all select 10 union all select 11 union all select 12) months
        where b.complex_id=v_complex_id and a.record_status=1
          and not exists(
              select 1 from carbon_budget_detail d
              where d.carbon_budget_id=v_budget_id and d.area_id=a.area_id and d.budget_month=months.m
          );

        update carbon_budget_detail d
        join carbon_budget cb on cb.carbon_budget_id=d.carbon_budget_id
        set d.budget_emission_kg=cb.total_budget_emission_kg/
            ((select count(*) from functional_area fa join building fb on fb.building_id=fa.building_id where fb.complex_id=v_complex_id and fa.record_status=1)*12)
        where d.carbon_budget_id=v_budget_id and d.valid_flag=1;

        call sp_refresh_budget_actuals(v_budget_id);

        insert into alert_rule(complex_id,rule_code,rule_name,rule_category,target_type,metric_code,comparison_operator,threshold_value,threshold_unit,duration_minutes,severity_level,auto_create_task_flag,priority_no,active_flag,rule_status,rule_description,created_by_user_id)
        select v_complex_id,concat(v_prefix,'-rule-energy'),'区域能耗异常规则','能耗异常','area','daily_energy','>',500,'tce',60,'中',1,100,1,1,'识别区域日度能耗异常',v_admin_id
        where not exists(select 1 from alert_rule where rule_code=concat(v_prefix,'-rule-energy'));
        select alert_rule_id into v_rule_id from alert_rule where rule_code=concat(v_prefix,'-rule-energy');

        set v_i=1;
        while v_i<=50 do
            select area_id into v_area_id from functional_area where area_code=concat(v_prefix,'-a-',lpad(mod(v_i-1,15)+1,2,'0'));
            select meter_device_id into v_device_id from meter_device where device_code=concat(v_prefix,'-d-',lpad(mod(v_i-1,30)+1,3,'0'));
            insert into alert_event(alert_rule_id,complex_id,area_id,meter_device_id,event_code,event_type,severity_level,event_title,event_content,detected_value,threshold_value,value_unit,occurred_at,first_seen_at,last_seen_at,event_status,source_snapshot,remark)
            select v_rule_id,v_complex_id,v_area_id,v_device_id,concat(v_prefix,'-alert-',lpad(v_i,3,'0')),
                   case mod(v_i,6) when 0 then '碳预算超标' when 1 then '能耗异常突增' when 2 then '设备离线' when 3 then '数据异常' when 4 then '数据缺失' else '整改逾期' end,
                   case mod(v_i,4) when 0 then '高' when 1 then '中' else '低' end,
                   concat(case mod(v_i,6) when 0 then '区域碳预算执行率偏高' when 1 then '区域日能耗出现异常波动' when 2 then '计量设备通信中断' when 3 then '采集数据需要复核' when 4 then '日度采集记录缺失' else '整改任务接近计划期限' end,'-',lpad(v_i,3,'0')),
                   '系统依据计量数据、预算执行和设备状态识别的运营预警。',550+v_i,500,'指标值',date_sub(now(),interval v_i day),date_sub(now(),interval v_i day),date_sub(now(),interval v_i day),mod(v_i,4),json_object('area_id',v_area_id,'device_id',v_device_id),'运营预警事件'
            where not exists(select 1 from alert_event where event_code=concat(v_prefix,'-alert-',lpad(v_i,3,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=35 do
            select alert_event_id into v_alert_id from alert_event where event_code=concat(v_prefix,'-alert-',lpad(v_i,3,'0'));
            select department_id into v_department_id from property_department where department_code=concat(v_prefix,'-dept-',lpad(mod(v_i-1,5)+1,2,'0'));
            insert into corrective_task(alert_event_id,responsible_department_id,responsible_user_id,task_code,task_title,task_content,priority_level,planned_start_at,planned_end_at,actual_start_at,actual_end_at,corrective_measure,handling_result,task_status,overdue_flag,verification_result,remark)
            select v_alert_id,v_department_id,(select min(user_id) from app_user where department_id=v_department_id),concat(v_prefix,'-task-',lpad(v_i,3,'0')),concat('能碳运营整改任务-',lpad(v_i,3,'0')),'核查关联设备和区域数据，落实节能运行措施。',case mod(v_i,3) when 0 then '高' when 1 then '中' else '低' end,date_sub(now(),interval v_i day),date_add(date_sub(now(),interval v_i day),interval 7 day),case when mod(v_i,4)>0 then date_sub(now(),interval v_i-1 day) end,case when mod(v_i,4)=3 then date_sub(now(),interval v_i-5 day) end,'复核设备状态、优化运行时段并跟踪能耗变化。','整改措施已按计划执行。',mod(v_i,4),case when mod(v_i,11)=0 then 1 else 0 end,'复核结果符合运营要求','整改闭环任务'
            where not exists(select 1 from corrective_task where task_code=concat(v_prefix,'-task-',lpad(v_i,3,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=6 do
            select department_id into v_department_id from property_department where department_code=concat(v_prefix,'-dept-02');
            select area_id into v_area_id from functional_area where area_code=concat(v_prefix,'-a-',lpad(mod(v_i-1,15)+1,2,'0'));
            insert into energy_saving_project(complex_id,responsible_department_id,area_id,project_manager_user_id,project_code,project_name,project_type,project_source,planned_start_date,planned_end_date,actual_start_date,actual_end_date,investment_amount,expected_annual_energy_saving,expected_energy_unit,expected_carbon_reduction_kg,expected_cost_saving,baseline_start_date,baseline_end_date,project_status,acceptance_status,project_description,remark)
            select v_complex_id,v_department_id,v_area_id,(select min(user_id) from app_user where department_id=v_department_id),concat(v_prefix,'-project-',lpad(v_i,2,'0')),
                   case v_i when 1 then '公共区域led照明改造' when 2 then '中央空调群控优化' when 3 then '停车场通风联动控制' when 4 then '屋顶分布式光伏建设' when 5 then '高效机电设备更新' else '公共区域节水改造' end,
                   case v_i when 1 then '照明改造' when 2 then '空调优化' when 3 then '通风控制' when 4 then '可再生能源' when 5 then '设备更新' else '节水改造' end,
                   '年度节能计划',date_sub(curdate(),interval 260-v_i*10 day),date_sub(curdate(),interval 120-v_i*8 day),date_sub(curdate(),interval 250-v_i*10 day),date_sub(curdate(),interval 110-v_i*8 day),280000+v_i*95000,180+v_i*45,'tce',95000+v_i*22000,120000+v_i*36000,date_sub(curdate(),interval 500 day),date_sub(curdate(),interval 321 day),case when v_i<=2 then 2 when v_i<=4 then 3 else 1 end,case when v_i<=4 then 1 else 0 end,'围绕重点用能系统实施持续优化。','节能项目档案'
            where not exists(select 1 from energy_saving_project where project_code=concat(v_prefix,'-project-',lpad(v_i,2,'0')));
            set v_i=v_i+1;
        end while;

        set v_i=1;
        while v_i<=8 do
            select energy_saving_project_id into v_project_id from energy_saving_project where project_code=concat(v_prefix,'-project-',lpad(mod(v_i-1,6)+1,2,'0'));
            insert into project_evaluation(energy_saving_project_id,evaluator_user_id,evaluation_no,evaluation_type,evaluation_date,baseline_start_date,baseline_end_date,evaluation_start_date,evaluation_end_date,baseline_energy_amount,normalized_baseline_energy,actual_energy_amount,energy_unit,energy_saving_amount,energy_saving_rate,baseline_carbon_kg,actual_carbon_kg,carbon_reduction_kg,cost_saving_amount,annualized_cost_saving,return_on_investment_rate,payback_period_months,evaluation_conclusion,evaluation_status,remark)
            select v_project_id,v_admin_id,floor((v_i-1)/6)+1,'运行效果评价',date_sub(curdate(),interval v_i*5 day),date_sub(curdate(),interval 500 day),date_sub(curdate(),interval 321 day),date_sub(curdate(),interval 180 day),date_sub(curdate(),interval 1 day),1500+v_i*80,1480+v_i*75,1180+v_i*55,'tce',300+v_i*20,18+v_i*0.7,980000+v_i*55000,760000+v_i*42000,220000+v_i*13000,180000+v_i*22000,360000+v_i*25000,12+v_i,24+v_i*2,'项目运行稳定，节能与减排效果达到预期。',1,'项目效果评价'
            where not exists(select 1 from project_evaluation where energy_saving_project_id=v_project_id and evaluation_no=floor((v_i-1)/6)+1);
            set v_i=v_i+1;
        end while;

        set v_bill_index=1;
        while v_bill_index<=3 do
            set v_bill_date=date_sub(date_format(curdate(),'%Y-%m-01'),interval v_bill_index month);
            if not exists(
                select 1 from merchant_energy_bill
                where complex_id=v_complex_id
                  and bill_year=year(v_bill_date)
                  and bill_month=month(v_bill_date)
                  and current_version_flag=1
            ) or (
                select count(*) from merchant_energy_bill
                where complex_id=v_complex_id
                  and bill_year=year(v_bill_date)
                  and bill_month=month(v_bill_date)
                  and current_version_flag=1
            ) < (
                select count(*) from merchant_occupancy o
                join merchant m on m.merchant_id=o.merchant_id
                where m.complex_id=v_complex_id and m.merchant_status=1 and o.current_valid_flag=1
            ) or v_scaled_count>0 then
                call sp_generate_merchant_energy_bills(v_complex_id,year(v_bill_date),month(v_bill_date),'lease_area',v_admin_id);
            end if;
            set v_bill_index=v_bill_index+1;
        end while;

        if (select count(*) from data_quality_issue where complex_id=v_complex_id)<20 then
            call sp_scan_data_quality_issues(v_complex_id,date_sub(curdate(),interval 180 day),date_sub(curdate(),interval 1 day));
        end if;

        set v_complex_no=v_complex_no+1;
    end while;

    set v_i=1;
    while v_i<=1600 do
        insert into operation_log(user_id,username_snapshot,module_name,business_type,object_type,object_id,operation_description,request_method,request_url,request_params,response_code,response_body,operation_result,ip_address,execution_time_ms,operation_time)
        select v_admin_id,'admin',case mod(v_i,8) when 0 then '综合体管理' when 1 then '建筑管理' when 2 then '能源消费' when 3 then '碳核算' when 4 then '碳预算' when 5 then '预警整改' when 6 then '节能项目' else '月度报告' end,
               case mod(v_i,8) when 0 then 'insert' when 1 then 'update' when 2 then 'select' when 3 then 'audit' when 4 then 'generate' when 5 then 'update' when 6 then 'select' else 'export' end,
               'business_record',concat('formal-log-',lpad(v_i,4,'0')),
               case mod(v_i,12) when 0 then '新增商业综合体档案' when 1 then '更新建筑基础信息' when 2 then '查询月度能源消费' when 3 then '复核碳核算记录' when 4 then '刷新碳预算执行数据' when 5 then '确认高等级预警' when 6 then '分配整改责任人' when 7 then '完成整改任务' when 8 then '查看节能项目效果' when 9 then '导出月度能碳报告' when 10 then '生成商户能碳账单' else '执行数据质量扫描' end,
               case when mod(v_i,3)=0 then 'GET' else 'POST' end,'/api/business',json_object('sequence',v_i),200,json_object('success',true),1,'127.0.0.1',20+mod(v_i,180),date_sub(now(),interval v_i*3 minute)
        where not exists(select 1 from operation_log where object_id=concat('formal-log-',lpad(v_i,4,'0')));
        set v_i=v_i+1;
    end while;
end$$

delimiter ;

call sp_generate_four_new_complex_business_data();
