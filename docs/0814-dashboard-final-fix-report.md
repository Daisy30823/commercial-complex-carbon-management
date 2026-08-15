# 2026-08-14 Dashboard 定向修复报告

## 修复范围

本轮仅处理登录后左侧 Logo、Dashboard 图表居中、主内容背景可见度和停用测试综合体显示问题。未执行主 SQL，未修改数据库结构、技术栈、业务流程或六类图表数量。

## Logo

- 原问题：`.sidebar .logo` 同时设置了半透明深色背景、14px 圆角和 Logo 背景图，形成多余的矩形承载板。
- 修改：容器背景改为透明、去除圆角和阴影，Logo 以 `82px × 82px` 居中、等比例、完整显示；窄屏使用 `58px × 58px`。
- 交互：保留点击或键盘 Enter/Space 返回 Dashboard；图片加载失败时才显示“低碳管理”。
- 文件：`src/main/webapp/assets/css/app.css`、`src/main/webapp/assets/js/app.js`。

## 图表布局

- 横向排名图原来使用 `left:145`、`right:58`，再叠加右侧 12px dataZoom，绘图区和数值标签整体偏右且显得拥挤。
- 修正为 `left:24`、`right:78`、`containLabel:true`，由 ECharts 按 112px 的分类轴标签实际宽度纳入布局；右侧滑条缩为 7px，隐藏详情并降低填充色存在感。
- 热力图原来使用 `left:145`、`right:28`，导致绘图区视觉中心偏移；修正为左右各 30px，并通过 `containLabel:true` 为 110px 区域标签自动留白。
- 热力图底部预留 108px，日期标签保持 35 度旋转，横向 `visualMap` 居中放置。
- 雷达图主体保持水平 50% 居中、半径 52%；半圆仪表盘保持水平 50% 居中、半径 78%，中心值与下方三项指标对齐。
- ECharts 每次重新加载前销毁旧实例，使用 `clear()` 和 `setOption(option, true)`；`ResizeObserver` 加双 `requestAnimationFrame` 在模块可见、布局稳定后统一 `resize()`。

## 背景

- 登录后全部模块继续共享 `app-background.png`，未对单张卡片重复设置背景。
- 主内容遮罩由顶部/底部约 88%/92% 不透明调整为 74%/84%，背景定位改为 `center top`，保留 `cover fixed no-repeat`。
- 卡片、表格、表单继续使用白色表面，保证业务内容可读；窄屏降级为随页面滚动。

## 测试综合体

- `ACC-0811220309` 是功能验收残留记录，保留用于审计并继续停用，不进入启用综合体选择器。
- 已将综合体名称、运营单位、物业单位、联系人和备注修正为明确中文；未删除记录。
- 数据补丁同步更新：`database/patches/030_clean_acceptance_test_data.sql`。

## 验收记录

| 项目 | 结果 |
| --- | --- |
| `mvnw.cmd test` | BUILD SUCCESS，26 项测试，0 失败、0 错误、0 跳过 |
| `mvnw.cmd clean package` | BUILD SUCCESS，生成 `target/commercial-complex-carbon.war` |
| Tomcat 清理并重新部署 | 通过；端口先停止后恢复，应用 HTTP 200，源/部署 WAR 均为 11,283,164 字节 |
| Logo/背景/四张重点图表浏览器检查 | 通过；最终 Logo 高度 86px，六个图表 Canvas 均生成 |
| Console JavaScript error | 通过；最终登录、Dashboard、综合体页刷新均无 error/warn |
| CSS/JS/PNG 网络请求 | app.css、app.js、本地 ECharts、Logo、背景图均 HTTP 200 |

浏览器实测中，1280×720 窗口曾暴露出侧栏 flex 会把 86px Logo 容器压缩为 61px；补充 `flex:0 0 86px` 并重新部署后，计算高度稳定为 86px。排名图、热力图、雷达图和仪表盘已在真实数据库数据下完成视觉检查，图形主体与图例/色带均未被裁切。

浏览器已生成并展示 Logo/背景、排名/热力和雷达/仪表盘验收截图；当前浏览器接口忽略截图 `path` 参数，未能写入 `docs/screenshots`，报告不虚构本地截图文件。
