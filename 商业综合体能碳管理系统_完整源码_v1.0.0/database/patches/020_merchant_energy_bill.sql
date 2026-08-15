use commercial_complex_carbon_db;

create table if not exists energy_allocation_rule (
    allocation_rule_id bigint unsigned not null auto_increment,
    complex_id bigint unsigned not null,
    rule_code varchar(60) not null,
    rule_name varchar(120) not null,
    allocation_method varchar(30) not null comment 'lease_area, contract_ratio, operating_days, manual',
    effective_date date not null,
    expiry_date date null,
    active_flag tinyint not null default 1,
    rule_config json null,
    remark varchar(500) null,
    created_at datetime not null default current_timestamp,
    updated_at datetime not null default current_timestamp on update current_timestamp,
    primary key (allocation_rule_id),
    unique key uk_allocation_rule_code (complex_id, rule_code),
    key idx_allocation_rule_effective (complex_id, active_flag, effective_date, expiry_date),
    constraint fk_allocation_rule_complex foreign key (complex_id)
        references commercial_complex (complex_id) on delete restrict on update cascade,
    constraint chk_allocation_method check (allocation_method in ('lease_area','contract_ratio','operating_days','manual'))
) engine=innodb default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='公共能耗分摊规则';

create table if not exists merchant_energy_bill (
    merchant_energy_bill_id bigint unsigned not null auto_increment,
    complex_id bigint unsigned not null,
    merchant_id bigint unsigned not null,
    allocation_rule_id bigint unsigned null,
    bill_code varchar(100) not null,
    bill_year int not null,
    bill_month tinyint not null,
    period_start date not null,
    period_end date not null,
    direct_energy_cost decimal(20,2) not null default 0,
    allocated_energy_cost decimal(20,2) not null default 0,
    total_energy_cost decimal(20,2) not null default 0,
    direct_energy_tce decimal(20,8) not null default 0,
    allocated_energy_tce decimal(20,8) not null default 0,
    total_energy_tce decimal(20,8) not null default 0,
    direct_carbon_kg decimal(20,6) not null default 0,
    allocated_carbon_kg decimal(20,6) not null default 0,
    total_carbon_kg decimal(20,6) not null default 0,
    allocation_weight decimal(18,10) not null default 0,
    bill_status tinyint not null default 0 comment '0草稿，1已确认，2已作废',
    confirmed_by_user_id bigint unsigned null,
    confirmed_at datetime null,
    voided_by_user_id bigint unsigned null,
    voided_at datetime null,
    void_reason varchar(500) null,
    generated_at datetime not null default current_timestamp,
    remark varchar(500) null,
    created_at datetime not null default current_timestamp,
    updated_at datetime not null default current_timestamp on update current_timestamp,
    primary key (merchant_energy_bill_id),
    unique key uk_merchant_bill_period (complex_id, merchant_id, bill_year, bill_month),
    unique key uk_merchant_bill_code (bill_code),
    key idx_merchant_bill_query (complex_id, bill_year, bill_month, bill_status),
    constraint fk_merchant_bill_complex foreign key (complex_id)
        references commercial_complex (complex_id) on delete restrict on update cascade,
    constraint fk_merchant_bill_merchant foreign key (merchant_id)
        references merchant (merchant_id) on delete restrict on update cascade,
    constraint fk_merchant_bill_rule foreign key (allocation_rule_id)
        references energy_allocation_rule (allocation_rule_id) on delete set null on update cascade,
    constraint fk_merchant_bill_confirm_user foreign key (confirmed_by_user_id)
        references app_user (user_id) on delete set null on update cascade,
    constraint fk_merchant_bill_void_user foreign key (voided_by_user_id)
        references app_user (user_id) on delete set null on update cascade,
    constraint chk_merchant_bill_month check (bill_month between 1 and 12),
    constraint chk_merchant_bill_status check (bill_status in (0,1,2))
) engine=innodb default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='商户月度能碳账单';

create table if not exists merchant_energy_bill_detail (
    merchant_energy_bill_detail_id bigint unsigned not null auto_increment,
    merchant_energy_bill_id bigint unsigned not null,
    energy_type_id bigint unsigned not null,
    source_type varchar(20) not null comment 'direct或allocated',
    consumption_amount decimal(20,6) not null default 0,
    consumption_unit varchar(30) not null,
    standard_coal_tce decimal(20,8) not null default 0,
    energy_cost decimal(20,2) not null default 0,
    carbon_emission_kg decimal(20,6) not null default 0,
    allocation_base_amount decimal(20,6) null,
    allocation_weight decimal(18,10) null,
    calculation_snapshot json null,
    created_at datetime not null default current_timestamp,
    updated_at datetime not null default current_timestamp on update current_timestamp,
    primary key (merchant_energy_bill_detail_id),
    unique key uk_bill_detail_energy_source (merchant_energy_bill_id, energy_type_id, source_type),
    key idx_bill_detail_energy (energy_type_id),
    constraint fk_bill_detail_bill foreign key (merchant_energy_bill_id)
        references merchant_energy_bill (merchant_energy_bill_id) on delete cascade on update cascade,
    constraint fk_bill_detail_energy foreign key (energy_type_id)
        references energy_type (energy_type_id) on delete restrict on update cascade,
    constraint chk_bill_detail_source check (source_type in ('direct','allocated'))
) engine=innodb default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='商户月度能碳账单能源明细';

delimiter $$
drop procedure if exists patch_020_add_column$$
create procedure patch_020_add_column(in p_table varchar(64),in p_column varchar(64),in p_definition varchar(1000))
begin
  if not exists(select 1 from information_schema.columns where table_schema=database() and table_name=p_table and column_name=p_column) then
    set @patch_sql=concat('alter table ',p_table,' add column ',p_column,' ',p_definition);
    prepare patch_stmt from @patch_sql; execute patch_stmt; deallocate prepare patch_stmt;
  end if;
end$$
call patch_020_add_column('energy_allocation_rule','energy_type_id','bigint unsigned null after complex_id')$$
call patch_020_add_column('energy_allocation_rule','building_id','bigint unsigned null after energy_type_id')$$
call patch_020_add_column('energy_allocation_rule','area_id','bigint unsigned null after building_id')$$
call patch_020_add_column('energy_allocation_rule','parameters_json','json null after allocation_method')$$
call patch_020_add_column('energy_allocation_rule','created_by_user_id','bigint unsigned null after remark')$$
call patch_020_add_column('merchant_energy_bill','version_no','int not null default 1 after bill_month')$$
call patch_020_add_column('merchant_energy_bill','current_version_flag','tinyint not null default 1 after version_no')$$
call patch_020_add_column('merchant_energy_bill','total_standard_coal_tce','decimal(20,8) not null default 0 after total_energy_tce')$$
call patch_020_add_column('merchant_energy_bill','data_completeness_rate','decimal(8,4) not null default 0 after total_carbon_kg')$$
call patch_020_add_column('merchant_energy_bill','generated_by_user_id','bigint unsigned null after bill_status')$$
call patch_020_add_column('merchant_energy_bill_detail','source_area_id','bigint unsigned null after source_type')$$
call patch_020_add_column('merchant_energy_bill_detail','allocation_ratio','decimal(18,10) null after allocation_weight')$$
call patch_020_add_column('merchant_energy_bill_detail','allocation_method','varchar(30) null after allocation_ratio')$$
call patch_020_add_column('merchant_energy_bill_detail','source_record_count','int not null default 0 after allocation_method')$$
call patch_020_add_column('merchant_energy_bill_detail','calculation_snapshot_json','json null after calculation_snapshot')$$
drop procedure patch_020_add_column$$

drop procedure if exists patch_020_indexes$$
create procedure patch_020_indexes()
begin
  if exists(select 1 from information_schema.statistics where table_schema=database() and table_name='merchant_energy_bill' and index_name='uk_merchant_bill_period') then
    alter table merchant_energy_bill drop index uk_merchant_bill_period;
  end if;
  if not exists(select 1 from information_schema.statistics where table_schema=database() and table_name='merchant_energy_bill' and index_name='uk_merchant_bill_version') then
    alter table merchant_energy_bill add unique key uk_merchant_bill_version(complex_id,merchant_id,bill_year,bill_month,version_no);
  end if;
end$$
call patch_020_indexes()$$
drop procedure patch_020_indexes$$
delimiter ;

insert into energy_allocation_rule (complex_id,rule_code,rule_name,allocation_method,parameters_json,effective_date,active_flag,rule_config,remark)
select cc.complex_id,concat(method_code,'-',cc.complex_id),method_name,method_code,json_object('normalization','within_complex_month'),'2020-01-01',1,json_object('normalization','within_complex_month'),'课程设计管理分摊规则'
from commercial_complex cc cross join (
 select 'lease_area' method_code,'按有效租赁面积分摊' method_name union all
 select 'contract_ratio','按合同约定比例分摊' union all
 select 'operating_days','按有效经营天数分摊' union all
 select 'manual','按人工配置比例分摊'
) methods where cc.record_status=1
on duplicate key update rule_name=values(rule_name),parameters_json=values(parameters_json),active_flag=values(active_flag),remark=values(remark);
