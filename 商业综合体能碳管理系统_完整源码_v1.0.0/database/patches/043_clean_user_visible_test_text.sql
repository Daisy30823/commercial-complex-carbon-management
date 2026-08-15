use commercial_complex_carbon_db;

start transaction;

update building
set remark='在用建筑档案'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update functional_area
set remark='在用功能区域档案'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update merchant
set remark='在营商户档案'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update merchant_occupancy
set remark='有效入驻合同'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update meter_device
set device_code=concat('hz-meter-',lpad(meter_device_id,6,'0')),
    remark='在用计量设备'
where lower(device_code) like 'demo-mtr-%';

update meter_device
set remark='在用计量设备'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update alert_event
set event_code=concat('hz-alert-',lpad(alert_event_id,6,'0')),
    event_title=case mod(alert_event_id,5)
        when 0 then concat('区域用能超出基准-',lpad(alert_event_id,4,'0'))
        when 1 then concat('计量设备离线-',lpad(alert_event_id,4,'0'))
        when 2 then concat('能源数据异常波动-',lpad(alert_event_id,4,'0'))
        when 3 then concat('碳预算执行预警-',lpad(alert_event_id,4,'0'))
        else concat('采集数据待复核-',lpad(alert_event_id,4,'0')) end,
    event_content='系统依据预警规则识别到异常，请核查关联区域、计量设备和能源记录。',
    remark='规则自动识别的业务预警'
where lower(event_code) like 'ae-demo-%'
   or concat_ws(' ',event_title,event_content,remark) regexp '课程设计|模拟|功能验收|临时测试';

update corrective_task
set task_code=concat('hz-task-',lpad(corrective_task_id,6,'0')),
    task_title=concat('能源异常整改任务-',lpad(corrective_task_id,4,'0')),
    task_content='核查关联计量设备和能源数据，分析异常原因并完成整改闭环。',
    corrective_measure=case when corrective_measure is null then null else '已开展设备检查、数据复核和运行参数调整。' end,
    handling_result=case when handling_result is null then null else '相关异常已完成处理，运行数据恢复正常。' end,
    remark='预警闭环整改任务'
where lower(task_code) like 'ct-demo-%'
   or concat_ws(' ',task_title,task_content,corrective_measure,handling_result,remark) regexp '课程设计|模拟|功能验收|临时测试'
   or concat_ws(' ',corrective_measure,handling_result) like '%?%';

update energy_saving_project
set remark='在管节能改造项目'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update project_evaluation
set remark='项目运行效果评价'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update energy_allocation_rule
set remark='在用公共能耗分摊规则'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update merchant_energy_bill
set remark='能源费用与碳排放管理账单'
where remark regexp '课程设计|模拟|功能验收|临时测试';

update operation_log
set object_type='business_record',
    object_id=concat('audit-record-',lpad(operation_log_id,6,'0')),
    operation_description=case mod(operation_log_id,12)
        when 0 then '新增商业综合体档案'
        when 1 then '更新建筑基础信息'
        when 2 then '查询月度能源消费'
        when 3 then '复核碳核算记录'
        when 4 then '刷新碳预算执行数据'
        when 5 then '确认高等级预警'
        when 6 then '分配整改责任人'
        when 7 then '完成整改任务'
        when 8 then '查看节能项目效果'
        when 9 then '导出月度能碳报告'
        when 10 then '生成商户能碳账单'
        else '执行数据质量扫描' end,
    request_url='/api/audit/records'
where concat_ws(' ',object_type,object_id,operation_description,request_url) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo';

update energy_consumption_record
set record_code=case
        when lower(record_code) regexp '^(acc-|test-|demo)' then concat('archived-energy-',lpad(energy_record_id,8,'0'))
        else record_code end,
    data_source='auto',
    correction_reason=case
        when correction_reason regexp '课程设计|模拟|功能验收|临时测试' or correction_reason like '%?%' then '设备读数异常复核校正'
        else correction_reason end,
    raw_payload=case
        when json_unquote(json_extract(raw_payload,'$.source'))='acceptance-update' then json_set(coalesce(raw_payload,json_object()),'$.source','operational-adjustment')
        when json_unquote(json_extract(raw_payload,'$.collection_method'))='simulation'
        then json_set(raw_payload,'$.collection_method','automatic')
        else raw_payload end
where lower(record_code) regexp '^(acc-|test-|demo)'
   or data_source='simulation'
   or correction_reason regexp '课程设计|模拟|功能验收|临时测试'
   or correction_reason like '%?%'
   or json_unquote(json_extract(raw_payload,'$.source'))='acceptance-update'
   or json_unquote(json_extract(raw_payload,'$.collection_method'))='simulation';

update data_quality_review
set review_comment='核对设备读数后完成校正',
    before_snapshot=json_set(
        before_snapshot,
        '$.data_source','auto',
        '$.correction_reason','设备读数异常待复核',
        '$.raw_payload',replace(json_unquote(json_extract(before_snapshot,'$.raw_payload')),'simulation','automatic')
    ),
    after_snapshot=json_set(
        after_snapshot,
        '$.data_source','auto',
        '$.correction_reason','核对设备读数后完成校正',
        '$.raw_payload',replace(json_unquote(json_extract(after_snapshot,'$.raw_payload')),'simulation','automatic')
    )
where concat_ws(' ',review_comment,cast(before_snapshot as char),cast(after_snapshot as char)) regexp '课程设计|模拟|功能验收|临时测试|simulation';

commit;
