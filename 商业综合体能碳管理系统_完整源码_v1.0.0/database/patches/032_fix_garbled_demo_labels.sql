-- Repairs only the three identifiable disabled acceptance-test meter labels.
update meter_node
set node_name = '功能验收测试根节点'
where node_code = 'AN-0811220309' and node_status = 0;

update meter_node
set node_name = '功能验收测试变压器节点'
where node_code = 'TR-0811220406' and node_status = 0;

update meter_node
set node_name = '功能验收测试计量节点'
where node_code = 'TC-0811220406' and node_status = 0;

update functional_area
set area_name = '功能验收测试区域', area_type = '测试区域', remark = '功能验收测试数据，已停用'
where area_code = 'AA-0811220309' and record_status = 0;
