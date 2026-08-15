-- 自助注册用户默认只读角色；幂等执行，不修改既有角色与用户。
insert into sys_role (
    role_code, role_name, data_scope, role_description, sort_no,
    role_status, built_in_flag, created_by_user_id, updated_by_user_id
)
select 'registered_user', '注册用户', 'self', '通过系统注册页面创建的只读用户', 90,
       1, 1,
       (select user_id from app_user where username = 'admin' limit 1),
       (select user_id from app_user where username = 'admin' limit 1)
where not exists (
    select 1 from sys_role where role_code = 'registered_user'
);

update sys_role
set role_name = '注册用户',
    data_scope = 'self',
    role_description = '通过系统注册页面创建的只读用户',
    role_status = 1,
    built_in_flag = 1
where role_code = 'registered_user';
