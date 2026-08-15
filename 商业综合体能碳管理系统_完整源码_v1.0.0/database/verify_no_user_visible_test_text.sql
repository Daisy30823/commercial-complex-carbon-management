use commercial_complex_carbon_db;

select 'commercial_complex' as data_scope,count(*) as remaining_count from commercial_complex where concat_ws(' ',complex_code,complex_name,address,operator_name,property_company,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'building',count(*) from building where concat_ws(' ',building_code,building_name,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'functional_area',count(*) from functional_area where concat_ws(' ',area_code,area_name,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'merchant',count(*) from merchant where concat_ws(' ',merchant_code,merchant_name,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'merchant_occupancy',count(*) from merchant_occupancy where concat_ws(' ',contract_code,lease_purpose,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'meter_node',count(*) from meter_node where concat_ws(' ',node_code,node_name,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'meter_device',count(*) from meter_device where concat_ws(' ',device_code,device_name,manufacturer,model_number,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'energy_consumption_record',count(*) from energy_consumption_record where concat_ws(' ',record_code,data_source,correction_reason,cast(raw_payload as char)) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'carbon_accounting_record',count(*) from carbon_accounting_record where concat_ws(' ',accounting_code,formula_text,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'alert_event',count(*) from alert_event where concat_ws(' ',event_code,event_title,event_content,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'corrective_task',count(*) from corrective_task where concat_ws(' ',task_code,task_title,task_content,corrective_measure,handling_result,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'energy_saving_project',count(*) from energy_saving_project where concat_ws(' ',project_code,project_name,project_description,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'project_evaluation',count(*) from project_evaluation where concat_ws(' ',evaluation_type,evaluation_conclusion,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'merchant_energy_bill',count(*) from merchant_energy_bill where concat_ws(' ',bill_code,remark) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'data_quality_issue',count(*) from data_quality_issue where concat_ws(' ',issue_code,issue_title,issue_description,resolution_note,cast(source_snapshot as char)) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'data_quality_review',count(*) from data_quality_review where concat_ws(' ',review_comment,cast(before_snapshot as char),cast(after_snapshot as char)) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo'
union all select 'operation_log',count(*) from operation_log where concat_ws(' ',module_name,object_type,object_id,operation_description,request_url,cast(request_params as char),cast(response_body as char)) regexp '课程设计|模拟|功能验收|临时测试|test-|acc-|demo';

