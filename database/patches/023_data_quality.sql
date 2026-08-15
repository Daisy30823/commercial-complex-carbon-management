use commercial_complex_carbon_db;

create table if not exists data_quality_issue (
    data_quality_issue_id bigint unsigned not null auto_increment,
    complex_id bigint unsigned not null,
    issue_rule varchar(50) not null,
    issue_category varchar(50) not null,
    severity_level varchar(20) not null,
    source_table varchar(80) not null,
    source_record_id bigint unsigned null,
    meter_device_id bigint unsigned null,
    energy_record_id bigint unsigned null,
    issue_title varchar(200) not null,
    issue_description varchar(1500) not null,
    detected_value varchar(255) null,
    expected_value varchar(255) null,
    issue_fingerprint varchar(64) not null,
    issue_status tinyint not null default 0 comment '0待处理，1复核中，2已解决，3误报',
    detected_at datetime not null default current_timestamp,
    resolved_at datetime null,
    resolved_by_user_id bigint unsigned null,
    resolution_note varchar(1000) null,
    source_snapshot json null,
    created_at datetime not null default current_timestamp,
    updated_at datetime not null default current_timestamp on update current_timestamp,
    primary key (data_quality_issue_id),
    unique key uk_quality_issue_fingerprint (issue_fingerprint),
    key idx_quality_issue_query (complex_id, issue_status, severity_level, issue_rule),
    key idx_quality_issue_record (energy_record_id),
    constraint fk_quality_issue_complex foreign key (complex_id) references commercial_complex (complex_id) on delete restrict on update cascade,
    constraint fk_quality_issue_device foreign key (meter_device_id) references meter_device (meter_device_id) on delete set null on update cascade,
    constraint fk_quality_issue_energy foreign key (energy_record_id) references energy_consumption_record (energy_record_id) on delete set null on update cascade,
    constraint fk_quality_issue_resolver foreign key (resolved_by_user_id) references app_user (user_id) on delete set null on update cascade,
    constraint chk_quality_issue_status check (issue_status in (0,1,2,3))
) engine=innodb default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='数据质量问题';

create table if not exists data_quality_review (
    data_quality_review_id bigint unsigned not null auto_increment,
    data_quality_issue_id bigint unsigned not null,
    reviewer_user_id bigint unsigned not null,
    review_action varchar(30) not null,
    before_snapshot json null,
    after_snapshot json null,
    review_comment varchar(1000) null,
    reviewed_at datetime not null default current_timestamp,
    primary key (data_quality_review_id),
    key idx_quality_review_issue (data_quality_issue_id, reviewed_at),
    constraint fk_quality_review_issue foreign key (data_quality_issue_id) references data_quality_issue (data_quality_issue_id) on delete cascade on update cascade,
    constraint fk_quality_review_user foreign key (reviewer_user_id) references app_user (user_id) on delete restrict on update cascade
) engine=innodb default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='数据质量复核记录';

create table if not exists data_quality_rule_config (
    rule_code varchar(50) not null,
    rule_name varchar(120) not null,
    rule_description varchar(500) not null,
    severity_level varchar(20) not null,
    threshold_json json null,
    active_flag tinyint not null default 1,
    updated_at datetime not null default current_timestamp on update current_timestamp,
    primary key(rule_code)
) engine=innodb default charset=utf8mb4 collate=utf8mb4_0900_ai_ci comment='数据质量规则集中配置';

insert into data_quality_rule_config(rule_code,rule_name,rule_description,severity_level,threshold_json) values
('missing_record','缺失记录','启用设备在统计期内没有采集记录','中',json_object('minimumRecords',1)),
('duplicate_period','重复统计周期','同一设备统计时间区间重复','高',json_object()),
('negative_consumption','负数用量','消费量小于零','高',json_object('minimum',0)),
('end_less_than_start','读数倒退','期末读数小于期初读数','高',json_object()),
('sudden_increase','能耗突增','用量高于统计期均值两倍','高',json_object('averageMultiplier',2)),
('continuous_zero','连续零用量','连续至少三天用量为零','中',json_object('days',3)),
('device_offline','设备离线','启用设备在线状态为离线','高',json_object()),
('invalid_json','原始报文异常','原始报文为空或无效','高',json_object()),
('pending_audit','审核超时','记录长时间处于待审核','中',json_object('hours',24)),
('expired_emission_factor','排放因子失效','核算日期不在因子有效期内','高',json_object()),
('abnormal_flag','异常标记','能耗记录已标记异常','高',json_object())
on duplicate key update rule_name=values(rule_name),rule_description=values(rule_description),severity_level=values(severity_level),threshold_json=values(threshold_json),active_flag=1;

delimiter $$
drop procedure if exists patch_023_add_column$$
create procedure patch_023_add_column(in p_column varchar(64),in p_definition varchar(1000))
begin
 if not exists(select 1 from information_schema.columns where table_schema=database() and table_name='data_quality_issue' and column_name=p_column) then
  set @patch_sql=concat('alter table data_quality_issue add column ',p_column,' ',p_definition);
  prepare patch_stmt from @patch_sql;execute patch_stmt;deallocate prepare patch_stmt;
 end if;
end$$
call patch_023_add_column('issue_code','varchar(100) null after data_quality_issue_id')$$
call patch_023_add_column('assigned_user_id','bigint unsigned null after issue_status')$$
call patch_023_add_column('first_seen_at','datetime null after detected_at')$$
call patch_023_add_column('last_seen_at','datetime null after first_seen_at')$$
call patch_023_add_column('resolution_type','varchar(40) null after resolved_by_user_id')$$
drop procedure patch_023_add_column$$
delimiter ;

update data_quality_issue set issue_code=coalesce(issue_code,concat('dqi-',lpad(data_quality_issue_id,8,'0'))),first_seen_at=coalesce(first_seen_at,detected_at),last_seen_at=coalesce(last_seen_at,detected_at);
