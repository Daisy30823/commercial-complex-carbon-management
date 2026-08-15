insert into commercial_complex(
    complex_code, complex_name, short_name, address, province_name, city_name, district_name,
    gross_floor_area, leasable_area, parking_spaces, opening_date, business_start_time,
    business_end_time, operator_name, property_company, contact_name, contact_phone,
    record_status, remark
)
select 'sxjh001','绍兴镜湖商业中心','镜湖商业中心','浙江省绍兴市越城区镜湖新区城市广场1号',
       '浙江省','绍兴市','越城区',146000,92000,980,'2021-09-18','10:00:00','22:00:00',
       '绍兴镜湖商业运营有限公司','绍兴镜湖物业服务有限公司','周经理','0575-88001234',1,'综合能碳运营示例场景'
where not exists(select 1 from commercial_complex where complex_code='sxjh001');

insert into commercial_complex(
    complex_code, complex_name, short_name, address, province_name, city_name, district_name,
    gross_floor_area, leasable_area, parking_spaces, opening_date, business_start_time,
    business_end_time, operator_name, property_company, contact_name, contact_phone,
    record_status, remark
)
select 'jxyh001','嘉兴运河商业中心','运河商业中心','浙江省嘉兴市南湖区运河商务大道88号',
       '浙江省','嘉兴市','南湖区',118000,73500,760,'2022-05-20','10:00:00','22:00:00',
       '嘉兴运河商业运营有限公司','嘉兴运河物业服务有限公司','沈经理','0573-82005678',1,'综合能碳运营示例场景'
where not exists(select 1 from commercial_complex where complex_code='jxyh001');

update commercial_complex
set remark='综合能碳运营管理场景'
where complex_code in ('hzcc001','nbcc001');

