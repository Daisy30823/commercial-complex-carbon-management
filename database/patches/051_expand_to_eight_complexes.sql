-- 扩展为八个正式商业综合体；仅新增/修正目标档案，不影响既有模拟数据。
insert into commercial_complex (
    complex_code, complex_name, short_name, unified_social_credit_code,
    address, province_name, city_name, district_name, longitude, latitude,
    gross_floor_area, leasable_area, parking_spaces, opening_date,
    business_start_time, business_end_time, operator_name, property_company,
    contact_name, contact_phone, record_status, remark
)
values
('wzcc001','温州瓯江商业中心','瓯江商业中心','91330300MA8CC00101','浙江省温州市鹿城区瓯江路88号','浙江省','温州市','鹿城区',120.672111,28.016273,116000,76000,1280,'2019-09-28','10:00:00','22:00:00','温州瓯江商业运营有限公司','温州安和物业服务有限公司','陈经理','0577-88001001',1,'八综合体演示正式档案'),
('jhcc001','金华婺城商业中心','婺城商业中心','91330700MA8CC00102','浙江省金华市婺城区双龙南街168号','浙江省','金华市','婺城区',119.647265,29.079195,98000,63500,980,'2020-06-18','10:00:00','22:00:00','金华婺城商业运营有限公司','金华诚悦物业服务有限公司','林经理','0579-88001002',1,'八综合体演示正式档案'),
('huzh001','湖州太湖商业中心','太湖商业中心','91330500MA8CC00103','浙江省湖州市吴兴区太湖路299号','浙江省','湖州市','吴兴区',120.086823,30.894348,132000,84500,1460,'2018-11-16','09:30:00','22:00:00','湖州太湖商业运营有限公司','湖州绿城物业服务有限公司','周经理','0572-88001003',1,'八综合体演示正式档案'),
('tzcc001','台州椒江商业中心','椒江商业中心','91331000MA8CC00104','浙江省台州市椒江区市府大道518号','浙江省','台州市','椒江区',121.420757,28.656386,108000,70200,1120,'2021-05-20','10:00:00','22:30:00','台州椒江商业运营有限公司','台州和美物业服务有限公司','沈经理','0576-88001004',1,'八综合体演示正式档案')
on duplicate key update
    complex_name=values(complex_name), short_name=values(short_name),
    address=values(address), city_name=values(city_name), district_name=values(district_name),
    gross_floor_area=values(gross_floor_area), leasable_area=values(leasable_area),
    parking_spaces=values(parking_spaces), operator_name=values(operator_name),
    property_company=values(property_company), contact_name=values(contact_name),
    contact_phone=values(contact_phone), record_status=1, remark=values(remark);
