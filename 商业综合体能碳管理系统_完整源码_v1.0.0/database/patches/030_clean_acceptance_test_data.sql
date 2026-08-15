-- idempotent cleanup of clearly identifiable acceptance-test records
-- keeps the records for audit, but makes them inactive and labels their purpose.
update commercial_complex
set complex_name = '功能验收测试综合体', short_name = '验收测试', address = '浙江省杭州市测试地址',
    operator_name = '功能验收测试运营单位', property_company = '功能验收测试物业单位',
    contact_name = '测试联系人',
    remark = '功能验收测试数据，已停用，不参与当前业务统计', record_status = 0
where complex_code = 'ACC-0811220309';

update commercial_complex
set complex_code = 'nbcc001', short_name = '宁波示范综合体', address = '宁波市杭州湾新区滨海大道168号',
    province_name = '浙江省', city_name = '宁波市', district_name = '杭州湾新区',
    gross_floor_area = 128000.00, leasable_area = 76000.00, parking_spaces = 860,
    operator_name = '宁波示范商业管理有限公司', property_company = '宁波示范物业服务有限公司',
    contact_name = '李经理', remark = '数据库课程设计模拟商业综合体', record_status = 1
where complex_name = '宁波示范商业综合体';

update building
set building_name = '功能验收测试楼', building_type = '测试建筑',
    remark = '功能验收测试数据，已停用', record_status = 0
where building_code = 'AB-0811220309';

update meter_node
set node_name = '功能验收测试根节点', remark = '功能验收测试数据，已停用', node_status = 0
where node_code = 'AN-0811220309';

update meter_node
set node_name = '功能验收测试节点', remark = '功能验收测试数据，已停用', node_status = 0
where node_code in ('TR-0811220406', 'TC-0811220406');
