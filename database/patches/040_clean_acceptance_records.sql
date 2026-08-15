-- 保留有审计价值的历史记录，但移除用户可见的验收命名并保持停用。
update commercial_complex
set complex_code = 'archived002',
    complex_name = '历史停用综合体档案',
    short_name = '历史档案',
    operator_name = '历史资料归档',
    property_company = '历史资料归档',
    contact_name = null,
    contact_phone = null,
    remark = '已停用，不参与当前业务统计',
    record_status = 0
where complex_code = 'ACC-0811220309';

update building
set building_code = 'archived-building-01', building_name = '历史停用建筑档案',
    building_type = '历史档案', remark = '已停用', record_status = 0
where building_code = 'AB-0811220309';

update functional_area
set area_code = 'archived-area-01', area_name = '历史停用区域档案',
    area_type = '历史档案', remark = '已停用', record_status = 0
where area_code = 'AA-0811220309';

update merchant
set merchant_code = 'archived-merchant-01', merchant_name = '历史停用商户档案',
    brand_name = '历史档案', remark = '已停用', merchant_status = 2
where merchant_code = 'AM-0811220309';

update meter_node
set node_code = concat('archived-node-', meter_node_id), node_name = '历史停用计量节点',
    remark = '已停用', node_status = 0
where node_code in ('AN-0811220309','TR-0811220406','TC-0811220406');

