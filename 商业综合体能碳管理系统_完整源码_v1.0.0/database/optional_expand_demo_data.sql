use commercial_complex_carbon_db;
-- 可选：将日度演示数据扩展到更长时间跨度。原始脚本的 25 天 × 220 设备已满足 5000+ 课程硬性要求。
call sp_generate_demo_energy_records(120);
call sp_refresh_budget_actuals(1);
