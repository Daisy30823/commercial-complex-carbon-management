-- Adds coherent demonstration buildings only when the official complex is short of eight.
insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select 1, 2, 'hzcc-bld-04', '办公塔楼 A', '办公楼', '示范路88号东侧', 18000.00, 12, 1,
       48.00, '2019-06-01', '2019-08-01', 1800, 13500.00, '二星', 1, 40, '杭州示范综合体办公配套建筑'
where not exists (select 1 from building where building_code = 'hzcc-bld-04');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select 1, 2, 'hzcc-bld-05', '办公塔楼 B', '办公楼', '示范路88号西侧', 16500.00, 11, 1,
       44.00, '2019-06-01', '2019-08-01', 1600, 12200.00, '二星', 1, 50, '杭州示范综合体办公配套建筑'
where not exists (select 1 from building where building_code = 'hzcc-bld-05');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select 1, 1, 'hzcc-bld-06', '酒店及服务楼', '酒店', '示范路88号南侧', 22000.00, 10, 2,
       42.00, '2018-06-01', '2018-09-01', 2200, 16800.00, '三星', 1, 60, '杭州示范综合体配套服务建筑'
where not exists (select 1 from building where building_code = 'hzcc-bld-06');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select 1, 1, 'hzcc-bld-07', '能源设备中心', '设备设施', '示范路88号北侧', 9000.00, 5, 1,
       24.00, '2018-06-01', '2018-09-01', 600, 5200.00, '二星', 1, 70, '杭州示范综合体能源设备建筑'
where not exists (select 1 from building where building_code = 'hzcc-bld-07');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select 1, 2, 'hzcc-bld-08', '文化展陈楼', '公共服务', '示范路88号西南侧', 12500.00, 6, 1,
       28.00, '2020-03-01', '2020-05-01', 1200, 8500.00, '二星', 1, 80, '杭州示范综合体公共服务建筑'
where not exists (select 1 from building where building_code = 'hzcc-bld-08');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select 1, 2, 'hzcc-bld-09', '南区配套商业楼', '商业楼', '示范路88号南区', 14500.00, 8, 1,
       34.00, '2020-03-01', '2020-05-01', 1500, 10200.00, '二星', 1, 90, '杭州示范综合体配套商业建筑'
where not exists (select 1 from building where building_code = 'hzcc-bld-09');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select c.complex_id, 2, 'nbcc-bld-01', '购物中心主楼', '购物中心', '滨海大道168号', 68000.00, 8, 2,
       38.00, '2020-05-01', '2020-09-01', 5200, 51000.00, '三星', 1, 10, '宁波示范综合体商业主楼'
from commercial_complex c where c.complex_code = 'nbcc001'
  and not exists (select 1 from building where building_code = 'nbcc-bld-01');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select c.complex_id, 2, 'nbcc-bld-02', '滨海写字楼', '办公楼', '滨海大道168号东侧', 24000.00, 14, 1,
       58.00, '2020-05-01', '2020-09-01', 1800, 18200.00, '二星', 1, 20, '宁波示范综合体办公建筑'
from commercial_complex c where c.complex_code = 'nbcc001'
  and not exists (select 1 from building where building_code = 'nbcc-bld-02');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select c.complex_id, 1, 'nbcc-bld-03', '滨海服务公寓', '公寓', '滨海大道168号南侧', 21000.00, 11, 1,
       46.00, '2020-05-01', '2020-09-01', 1200, 14800.00, '二星', 1, 30, '宁波示范综合体服务公寓'
from commercial_complex c where c.complex_code = 'nbcc001'
  and not exists (select 1 from building where building_code = 'nbcc-bld-03');

insert into building
    (complex_id, managing_department_id, building_code, building_name, building_type,
     address_detail, gross_floor_area, above_ground_floors, underground_floors,
     building_height, completion_date, use_start_date, design_daily_flow,
     air_conditioning_area, energy_management_grade, record_status, sort_no, remark)
select c.complex_id, 1, 'nbcc-bld-04', '能源设备中心', '设备设施', '滨海大道168号北侧', 15000.00, 5, 1,
       25.00, '2020-05-01', '2020-09-01', 500, 8200.00, '二星', 1, 40, '宁波示范综合体能源设备建筑'
from commercial_complex c where c.complex_code = 'nbcc001'
  and not exists (select 1 from building where building_code = 'nbcc-bld-04');
