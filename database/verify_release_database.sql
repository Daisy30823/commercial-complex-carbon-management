select 'table_count' as check_item,
       count(*) as actual_value,
       if(count(*) >= 15, 'pass', 'fail') as result
from information_schema.tables
where table_schema = database() and table_type = 'BASE TABLE';

select 'tables_with_15_columns' as check_item,
       count(*) as actual_value,
       if(count(*) >= 10, 'pass', 'fail') as result
from (
    select table_name
    from information_schema.columns
    where table_schema = database()
    group by table_name
    having count(*) >= 15
) t;

select 'tables_without_primary_key' as check_item,
       count(*) as actual_value,
       if(count(*) = 0, 'pass', 'fail') as result
from information_schema.tables t
where t.table_schema = database()
  and t.table_type = 'BASE TABLE'
  and not exists (
      select 1 from information_schema.table_constraints c
      where c.table_schema = t.table_schema
        and c.table_name = t.table_name
        and c.constraint_type = 'PRIMARY KEY'
  );

select 'foreign_keys' as check_item, count(*) as actual_value,
       if(count(*) > 0, 'pass', 'fail') as result
from information_schema.table_constraints
where table_schema = database() and constraint_type = 'FOREIGN KEY';

select 'views' as check_item, count(*) as actual_value,
       if(count(*) >= 1, 'pass', 'fail') as result
from information_schema.views where table_schema = database();

select 'json_columns' as check_item, count(*) as actual_value,
       if(count(*) >= 1, 'pass', 'fail') as result
from information_schema.columns
where table_schema = database() and data_type = 'json';

select 'self_referencing_foreign_keys' as check_item, count(*) as actual_value,
       if(count(*) >= 1, 'pass', 'fail') as result
from information_schema.key_column_usage
where table_schema = database() and referenced_table_name = table_name;

select routine_type as check_item, count(*) as actual_value, 'pass' as result
from information_schema.routines where routine_schema = database()
group by routine_type;

select 'triggers' as check_item, count(*) as actual_value,
       if(count(*) >= 1, 'pass', 'fail') as result
from information_schema.triggers where trigger_schema = database();

set session group_concat_max_len = 1000000;
select group_concat(
    concat('select ''', replace(table_name, '''', ''''''), ''' as table_name, count(*) as record_count from `', replace(table_name, '`', '``'), '`')
    separator ' union all '
) into @release_count_sql
from information_schema.tables
where table_schema = database() and table_type = 'BASE TABLE';
set @release_count_sql = concat(
    'select ''tables_with_200_rows'' as check_item, count(*) as actual_value, ',
    'if(count(*) >= 5, ''pass'', ''fail'') as result from (',
    @release_count_sql,
    ') release_counts where record_count >= 200'
);
prepare release_count_stmt from @release_count_sql;
execute release_count_stmt;
deallocate prepare release_count_stmt;

select 'energy_records' as check_item, count(*) as actual_value,
       if(count(*) >= 5000, 'pass', 'fail') as result
from energy_consumption_record;

select 'missing_carbon_records' as check_item, count(*) as actual_value,
       if(count(*) = 0, 'pass', 'fail') as result
from energy_consumption_record e
left join carbon_accounting_record c on c.energy_record_id = e.energy_record_id
where c.carbon_accounting_id is null;

select 'enabled_complexes' as check_item, count(*) as actual_value,
       if(count(*) >= 2, 'pass', 'fail') as result
from commercial_complex where record_status = 1;

select 'cross_complex_occupancies' as check_item, count(*) as actual_value,
       if(count(*) = 0, 'pass', 'fail') as result
from merchant_occupancy mo
join merchant m on m.merchant_id = mo.merchant_id
join functional_area a on a.area_id = mo.area_id
join building b on b.building_id = a.building_id
where m.complex_id <> b.complex_id;

select 'cross_complex_meter_parents' as check_item, count(*) as actual_value,
       if(count(*) = 0, 'pass', 'fail') as result
from meter_node child
join meter_node parent on parent.meter_node_id = child.parent_node_id
where child.complex_id <> parent.complex_id;

select 'required_crud_procedures' as check_item, count(*) as actual_value,
       if(count(*) = 12, 'pass', 'fail') as result
from information_schema.routines
where routine_schema = database() and routine_name in (
    'sp_save_commercial_complex','sp_delete_commercial_complex',
    'sp_save_building','sp_delete_building',
    'sp_save_functional_area','sp_delete_functional_area',
    'sp_save_merchant','sp_delete_merchant',
    'sp_save_meter_node','sp_delete_meter_node',
    'sp_save_meter_device','sp_delete_meter_device'
);

select 'required_query_procedures' as check_item, count(*) as actual_value,
       if(count(*) = 7, 'pass', 'fail') as result
from information_schema.routines
where routine_schema = database() and routine_name in (
    'sp_query_monthly_area_energy_carbon','sp_query_top_merchants_carbon',
    'sp_query_over_budget_areas','sp_query_open_alerts',
    'sp_query_project_effect','sp_query_energy_mix','sp_query_meter_node_tree'
);
