use commercial_complex_carbon_db;

delimiter $$
drop procedure if exists sp_scan_data_quality_issues$$
create procedure sp_scan_data_quality_issues(in p_complex_id bigint unsigned,in p_start date,in p_end date)
begin
    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'missing_record','采集完整性','中','meter_device',md.meter_device_id,md.meter_device_id,'统计期无能耗记录','启用设备在所选统计期内没有任何能耗记录','0','至少 1 条',sha2(concat('missing_record:',md.meter_device_id,':',p_start,':',p_end),256),json_object('deviceCode',md.device_code,'startDate',p_start,'endDate',p_end)
    from meter_device md join meter_node mn on mn.meter_node_id=md.meter_node_id left join energy_consumption_record e on e.meter_device_id=md.meter_device_id and e.record_date between p_start and p_end where mn.complex_id=p_complex_id and md.device_status=1 group by mn.complex_id,md.meter_device_id,md.device_code having count(e.energy_record_id)=0;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'duplicate_period','周期重复','高','energy_consumption_record',min(e.energy_record_id),e.meter_device_id,min(e.energy_record_id),'设备统计周期重复','同一设备存在重复的统计开始和结束时间',cast(count(*) as char),'1',sha2(concat('duplicate_period:',e.meter_device_id,':',e.period_start,':',e.period_end),256),json_object('duplicateCount',count(*))
    from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end group by mn.complex_id,e.meter_device_id,e.period_start,e.period_end having count(*)>1;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'negative_consumption','用量异常','高','energy_consumption_record',e.energy_record_id,e.meter_device_id,e.energy_record_id,'能耗用量为负数','能耗用量违反非负业务约束',cast(e.consumption_amount as char),'>=0',sha2(concat('negative_consumption:',e.energy_record_id),256),json_object('recordCode',e.record_code,'amount',e.consumption_amount)
    from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end and e.consumption_amount<0;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'end_less_than_start','读数异常','高','energy_consumption_record',e.energy_record_id,e.meter_device_id,e.energy_record_id,'期末读数小于期初读数','设备读数倒退，违反读数单调约束',concat(e.start_reading,' -> ',e.end_reading),'期末读数 >= 期初读数',sha2(concat('end_less_than_start:',e.energy_record_id),256),json_object('recordCode',e.record_code,'startReading',e.start_reading,'endReading',e.end_reading)
    from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end and e.end_reading<e.start_reading;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'abnormal_flag','能耗数据','高','energy_consumption_record',e.energy_record_id,e.meter_device_id,e.energy_record_id,'能耗记录已标记异常','原始能耗记录 abnormal_flag=1',cast(e.abnormal_flag as char),'0',sha2(concat('abnormal_flag:',e.energy_record_id),256),json_object('recordCode',e.record_code,'recordDate',e.record_date,'amount',e.consumption_amount)
    from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end and e.abnormal_flag=1;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'pending_audit','审核状态','中','energy_consumption_record',e.energy_record_id,e.meter_device_id,e.energy_record_id,'能耗记录待审核','统计期内记录仍处于待审核状态',cast(e.audit_status as char),'1',sha2(concat('pending_audit:',e.energy_record_id),256),json_object('recordCode',e.record_code,'recordDate',e.record_date)
    from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end and e.audit_status=0;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'invalid_json','报文格式','高','energy_consumption_record',e.energy_record_id,e.meter_device_id,e.energy_record_id,'原始报文缺失或无效','raw_payload 为空或不是有效 JSON 对象',coalesce(cast(e.raw_payload as char),'null'),'有效 JSON',sha2(concat('invalid_json:',e.energy_record_id),256),json_object('recordCode',e.record_code)
    from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end and (e.raw_payload is null or json_valid(e.raw_payload)=0);

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'continuous_zero','用量异常','中','energy_consumption_record',min(e.energy_record_id),e.meter_device_id,min(e.energy_record_id),'连续零用量','同一设备连续至少 3 个统计日用量为 0',cast(count(*) as char),'<3',sha2(concat('continuous_zero:',e.meter_device_id,':',p_start,':',p_end),256),json_object('deviceId',e.meter_device_id,'zeroDays',count(*))
    from energy_consumption_record e join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end and e.consumption_amount=0 group by mn.complex_id,e.meter_device_id having count(distinct e.record_date)>=3;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'device_offline','设备状态','高','meter_device',md.meter_device_id,md.meter_device_id,'计量设备离线','设备当前在线状态为离线',cast(md.online_status as char),'1',sha2(concat('device_offline:',md.meter_device_id),256),json_object('deviceCode',md.device_code,'lastCollectionTime',md.last_collection_time)
    from meter_device md join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and md.device_status=1 and md.online_status=0;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'sudden_increase','用量异常','高','energy_consumption_record',x.energy_record_id,x.meter_device_id,x.energy_record_id,'能耗突增','当日用量超过该设备统计期平均值的 3 倍',cast(x.consumption_amount as char),cast(round(x.avg_amount*3,6) as char),sha2(concat('sudden_increase:',x.energy_record_id),256),json_object('amount',x.consumption_amount,'average',x.avg_amount)
    from (select e.*,avg(e.consumption_amount) over(partition by e.meter_device_id) avg_amount from energy_consumption_record e where e.record_date between p_start and p_end) x join meter_device md on md.meter_device_id=x.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and x.avg_amount>0 and x.consumption_amount>x.avg_amount*2;

    insert ignore into data_quality_issue (complex_id,issue_rule,issue_category,severity_level,source_table,source_record_id,meter_device_id,energy_record_id,issue_title,issue_description,detected_value,expected_value,issue_fingerprint,source_snapshot)
    select mn.complex_id,'expired_emission_factor','排放因子','高','carbon_accounting_record',car.carbon_accounting_id,e.meter_device_id,e.energy_record_id,'使用过期排放因子','核算日期不在排放因子有效期内',cast(car.emission_factor_id as char),'有效期内因子',sha2(concat('expired_emission_factor:',car.carbon_accounting_id),256),json_object('accountingDate',car.accounting_date,'factorId',car.emission_factor_id)
    from carbon_accounting_record car join emission_factor f on f.emission_factor_id=car.emission_factor_id join energy_consumption_record e on e.energy_record_id=car.energy_record_id join meter_device md on md.meter_device_id=e.meter_device_id join meter_node mn on mn.meter_node_id=md.meter_node_id where mn.complex_id=p_complex_id and e.record_date between p_start and p_end and (car.accounting_date<f.effective_date or (f.expiry_date is not null and car.accounting_date>f.expiry_date));

    select issue_rule,count(*) issue_count from data_quality_issue where complex_id=p_complex_id and issue_status in(0,1) group by issue_rule order by issue_count desc;
end$$

drop procedure if exists sp_query_data_quality_issues$$
create procedure sp_query_data_quality_issues(in p_complex_id bigint unsigned,in p_start date,in p_end date,in p_rule varchar(50),in p_severity varchar(20),in p_status tinyint,in p_device_id bigint unsigned,in p_keyword varchar(100),in p_page int,in p_page_size int)
begin declare v_offset int default 0;set v_offset=(p_page-1)*p_page_size;select q.*,md.device_code,md.device_name,e.record_code,e.record_date from data_quality_issue q left join meter_device md on md.meter_device_id=q.meter_device_id left join energy_consumption_record e on e.energy_record_id=q.energy_record_id where q.complex_id=p_complex_id and (p_start is null or coalesce(e.record_date,date(q.detected_at))>=p_start) and (p_end is null or coalesce(e.record_date,date(q.detected_at))<=p_end) and (p_rule is null or q.issue_rule=p_rule) and (p_severity is null or q.severity_level=p_severity) and (p_status is null or q.issue_status=p_status) and (p_device_id is null or q.meter_device_id=p_device_id) and (p_keyword is null or q.issue_title like concat('%',p_keyword,'%') or md.device_name like concat('%',p_keyword,'%') or e.record_code like concat('%',p_keyword,'%')) order by q.detected_at desc,q.data_quality_issue_id desc limit p_page_size offset v_offset; end$$

drop procedure if exists sp_review_data_quality_issue$$
create procedure sp_review_data_quality_issue(in p_issue_id bigint unsigned,in p_user_id bigint unsigned,in p_comment varchar(1000))
begin insert into data_quality_review(data_quality_issue_id,reviewer_user_id,review_action,before_snapshot,review_comment) select data_quality_issue_id,p_user_id,'review',source_snapshot,p_comment from data_quality_issue where data_quality_issue_id=p_issue_id; update data_quality_issue set issue_status=1,resolution_note=p_comment where data_quality_issue_id=p_issue_id and issue_status=0; select row_count() affected_rows; end$$

drop procedure if exists sp_resolve_data_quality_issue$$
create procedure sp_resolve_data_quality_issue(in p_issue_id bigint unsigned,in p_user_id bigint unsigned,in p_comment varchar(1000))
begin if trim(coalesce(p_comment,''))='' then signal sqlstate '45000' set message_text='解决说明不能为空'; end if; insert into data_quality_review(data_quality_issue_id,reviewer_user_id,review_action,before_snapshot,review_comment) select data_quality_issue_id,p_user_id,'resolve',source_snapshot,p_comment from data_quality_issue where data_quality_issue_id=p_issue_id; update data_quality_issue set issue_status=2,resolved_by_user_id=p_user_id,resolved_at=now(),resolution_note=p_comment where data_quality_issue_id=p_issue_id and issue_status in(0,1); select row_count() affected_rows; end$$

drop procedure if exists sp_mark_data_quality_false_positive$$
create procedure sp_mark_data_quality_false_positive(in p_issue_id bigint unsigned,in p_user_id bigint unsigned,in p_comment varchar(1000))
begin if trim(coalesce(p_comment,''))='' then signal sqlstate '45000' set message_text='误报说明不能为空'; end if; insert into data_quality_review(data_quality_issue_id,reviewer_user_id,review_action,before_snapshot,review_comment) select data_quality_issue_id,p_user_id,'false_positive',source_snapshot,p_comment from data_quality_issue where data_quality_issue_id=p_issue_id; update data_quality_issue set issue_status=3,resolved_by_user_id=p_user_id,resolved_at=now(),resolution_note=p_comment where data_quality_issue_id=p_issue_id and issue_status in(0,1); select row_count() affected_rows; end$$

drop procedure if exists sp_scan_data_quality$$
create procedure sp_scan_data_quality(in p_complex_id bigint unsigned,in p_start date,in p_end date,in p_user_id bigint unsigned)
begin call sp_scan_data_quality_issues(p_complex_id,p_start,p_end); end$$

drop procedure if exists sp_mark_quality_issue_false_positive$$
create procedure sp_mark_quality_issue_false_positive(in p_issue_id bigint unsigned,in p_user_id bigint unsigned,in p_comment varchar(1000))
begin call sp_mark_data_quality_false_positive(p_issue_id,p_user_id,p_comment); end$$
delimiter ;

update data_quality_issue
set issue_category=case issue_rule
      when 'missing_record' then '采集完整性' when 'duplicate_period' then '周期重复'
      when 'negative_consumption' then '用量异常' when 'end_less_than_start' then '读数异常'
      when 'sudden_increase' then '用量异常' when 'continuous_zero' then '用量异常'
      when 'device_offline' then '设备状态' when 'invalid_json' then '报文格式'
      when 'pending_audit' then '审核状态' when 'expired_emission_factor' then '排放因子'
      else '能耗数据' end,
    severity_level=case when issue_rule in ('missing_record','continuous_zero','pending_audit') then '中' else '高' end,
    issue_title=case issue_rule
      when 'missing_record' then '统计期无能耗记录' when 'duplicate_period' then '设备统计周期重复'
      when 'negative_consumption' then '能耗用量为负数' when 'end_less_than_start' then '期末读数小于期初读数'
      when 'sudden_increase' then '能耗突增' when 'continuous_zero' then '连续零用量'
      when 'device_offline' then '计量设备离线' when 'invalid_json' then '原始报文缺失或无效'
      when 'pending_audit' then '能耗记录待审核' when 'expired_emission_factor' then '使用过期排放因子'
      else '能耗记录已标记异常' end,
    issue_description=case issue_rule
      when 'missing_record' then '启用设备在所选统计期内没有任何能耗记录'
      when 'duplicate_period' then '同一设备存在重复的统计开始和结束时间'
      when 'negative_consumption' then '能耗用量违反非负业务约束'
      when 'end_less_than_start' then '设备读数倒退，违反读数单调约束'
      when 'sudden_increase' then '当日用量超过该设备统计期平均值的 3 倍'
      when 'continuous_zero' then '同一设备连续至少 3 个统计日用量为 0'
      when 'device_offline' then '设备当前在线状态为离线'
      when 'invalid_json' then 'raw_payload 为空或不是有效 JSON 对象'
      when 'pending_audit' then '统计期内记录仍处于待审核状态'
      when 'expired_emission_factor' then '核算日期不在排放因子有效期内'
      else '原始能耗记录 abnormal_flag=1' end
where issue_rule in ('missing_record','duplicate_period','negative_consumption','end_less_than_start','sudden_increase','continuous_zero','device_offline','invalid_json','pending_audit','expired_emission_factor','abnormal_flag');

update data_quality_issue set issue_code=coalesce(issue_code,concat('dqi-',lpad(data_quality_issue_id,8,'0'))),first_seen_at=coalesce(first_seen_at,detected_at),last_seen_at=now() where issue_status in(0,1);
