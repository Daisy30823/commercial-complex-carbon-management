(function () {
  const dashboardChartIds = [
    'trendChart',
    'rankingChart',
    'mixChart',
    'heatChart',
    'radarChart',
    'gaugeChart'
  ];
  let dashboardLoadSequence = 0;

  function nextDashboardPaint() {
    return new Promise(resolve => {
      requestAnimationFrame(() => requestAnimationFrame(resolve));
    });
  }

  async function waitForDashboardLayout() {
    await nextDashboardPaint();
    const elements = dashboardChartIds.map(id => document.getElementById(id));
    if (elements.some(element => !element)) {
      throw new Error('Dashboard 图表容器未完成渲染');
    }
    if (elements.every(element => element.clientWidth > 0 && element.clientHeight > 0)) {
      return;
    }
    await new Promise(resolve => {
      const observer = new ResizeObserver(() => {
        if (elements.every(element => element.clientWidth > 0 && element.clientHeight > 0)) {
          observer.disconnect();
          resolve();
        }
      });
      elements.forEach(element => observer.observe(element));
    });
  }

  function disposeDashboardCharts() {
    dashboardLoadSequence += 1;
    dashboardChartIds.forEach(id => {
      const element = document.getElementById(id);
      const instance = element && window.echarts ? echarts.getInstanceByDom(element) : null;
      if (instance) instance.dispose();
      delete state.charts[id];
    });
  }

  function showChartState(id, message, retry) {
    const element = document.getElementById(id);
    if (!element) return;
    const instance = window.echarts ? echarts.getInstanceByDom(element) : null;
    if (instance) instance.dispose();
    delete state.charts[id];
    element.innerHTML = `<div class="chart-state">${esc(message)}${retry ? '<button type="button" class="btn ghost chart-retry">重新加载</button>' : ''}</div>`;
    element.querySelector('.chart-retry')?.addEventListener('click', () => loadDashboard());
  }

  function showAllChartLoading() {
    dashboardChartIds.forEach(id => showChartState(id, '数据加载中…', false));
    const gaugeMeta = document.getElementById('gaugeMeta');
    if (gaugeMeta) gaugeMeta.innerHTML = '';
  }

  chart = function (id, inputOption) {
    const element = document.getElementById(id);
    if (!element || !window.echarts) throw new Error('图表组件尚未就绪');
    if (element.clientWidth <= 0 || element.clientHeight <= 0) {
      throw new Error('图表容器尺寸尚未就绪');
    }
    const oldChart = echarts.getInstanceByDom(element);
    if (oldChart) oldChart.dispose();
    element.replaceChildren();
    const instance = echarts.init(element);
    state.charts[id] = instance;
    const option = {...inputOption, color: palette};
    if (option.grid !== undefined) option.grid = {containLabel: true, ...option.grid};
    instance.clear();
    instance.setOption(option, {notMerge: true, lazyUpdate: false, replaceMerge: ['series']});
    requestAnimationFrame(() => instance.resize());
    return instance;
  };

  function renderKpis(summary) {
    const cards = [
      ['建筑数量', summary.buildingCount, '栋', 'buildings'],
      ['计量设备数量', summary.deviceCount, '台', 'devices'],
      ['近30日综合能耗', fmt(summary.recentEnergyTce), 'tce', 'energy'],
      ['近30日碳排放', summary.recentCarbonKg >= 1000 ? fmt(summary.recentCarbonKg / 1000) : fmt(summary.recentCarbonKg), summary.recentCarbonKg >= 1000 ? 'tCO₂e' : 'kgCO₂e', 'carbon'],
      ['年度预算执行率', `${Number(summary.budgetExecutionRate || 0).toFixed(2)}%`, '', 'budget'],
      ['未关闭预警', summary.openAlerts, '条', 'alerts'],
      ['实施中节能项目', summary.activeProjects, '项', 'projects'],
      ['累计减排量', summary.simulatedReductionKg >= 1000 ? fmt(summary.simulatedReductionKg / 1000) : fmt(summary.simulatedReductionKg), summary.simulatedReductionKg >= 1000 ? 'tCO₂e' : 'kgCO₂e', 'projects']
    ];
    const kpis = document.getElementById('kpis');
    kpis.innerHTML = cards.map(card => `<div class="kpi" data-drill="${card[3]}"><small>${card[0]}</small><strong>${card[1]}</strong><span>${card[2]}</span></div>`).join('');
    kpis.querySelectorAll('[data-drill]').forEach(element => {
      element.addEventListener('click', () => route(element.dataset.drill));
    });
  }

  function renderTrend(rows) {
    if (!rows.length) return showChartState('trendChart', '暂无趋势数据', false);
    chart('trendChart', {
      tooltip: {trigger: 'axis', valueFormatter: value => fmt(value)},
      legend: {top: 4, data: ['综合能耗（tce）', '碳排放（tCO₂e）']},
      grid: {left: 55, right: 60, top: 52, bottom: 58},
      xAxis: {type: 'category', boundaryGap: false, data: rows.map(row => row.stat_date), axisLabel: {interval: 'auto', rotate: 25}},
      yAxis: [{type: 'value', name: 'tce', nameGap: 14}, {type: 'value', name: 'tCO₂e', nameGap: 14}],
      dataZoom: rows.length > 20 ? [{type: 'inside'}, {type: 'slider', height: 14, bottom: 5}] : [],
      series: [
        {name: '综合能耗（tce）', type: 'line', smooth: true, symbol: 'circle', symbolSize: 5, areaStyle: {opacity: .08}, data: rows.map(row => row.energy_tce)},
        {name: '碳排放（tCO₂e）', type: 'line', smooth: true, yAxisIndex: 1, lineStyle: {type: 'dashed'}, data: rows.map(row => row.carbon_t)}
      ]
    });
  }

  function renderRanking(rows) {
    if (!rows.length) return showChartState('rankingChart', '暂无区域排名数据', false);
    const ordered = [...rows].sort((left, right) => Number(right.carbon_t) - Number(left.carbon_t));
    chart('rankingChart', {
      tooltip: {trigger: 'axis', axisPointer: {type: 'shadow'}, formatter: params => `${esc(ordered[params[0].dataIndex]?.area_name || '')}<br>碳排放：${fmt(params[0].value)} tCO₂e`},
      grid: {left: 24, right: 78, top: 30, bottom: 52},
      xAxis: {type: 'value', name: 'tCO₂e', nameLocation: 'middle', nameGap: 32},
      yAxis: {type: 'category', inverse: true, data: ordered.map(row => row.area_name), axisLabel: {width: 112, overflow: 'truncate'}},
      dataZoom: ordered.length > 10 ? [{type: 'inside', yAxisIndex: 0}, {type: 'slider', yAxisIndex: 0, width: 7, right: 12, showDetail: false, brushSelect: false, borderColor: 'transparent', fillerColor: 'rgba(88,167,154,.18)', handleSize: '75%'}] : [],
      series: [{type: 'bar', barMaxWidth: 22, data: ordered.map(row => Number(row.carbon_t) || 0), label: {show: true, position: 'right', formatter: params => fmt(params.value)}}]
    });
  }

  function renderMix(rows) {
    if (!rows.length) return showChartState('mixChart', '暂无能源结构数据', false);
    chart('mixChart', {
      tooltip: {trigger: 'item', formatter: params => `${params.name}<br>排放量：${fmt(params.value)} tCO₂e<br>占比：${params.percent}%`},
      legend: {type: 'scroll', bottom: 2, left: 'center'},
      series: [{type: 'pie', radius: ['43%', '67%'], center: ['50%', '44%'], avoidLabelOverlap: true, minShowLabelAngle: 8, label: {formatter: '{b}\n{d}%'}, labelLine: {length: 10, length2: 8}, data: rows.map(row => ({name: row.energy_name, value: Number(row.total_carbon_emission_kg || 0) / 1000}))}]
    });
  }

  function renderHeat(rows) {
    if (!rows.length) return showChartState('heatChart', '暂无区域热力数据', false);
    const dates = [...new Set(rows.map(row => String(row.stat_date)))];
    const areas = [...new Set(rows.map(row => row.area_name))];
    const values = new Map(rows.map(row => [`${row.stat_date}|${row.area_name}`, Number(row.value_tce || 0)]));
    chart('heatChart', {
      tooltip: {position: 'top', formatter: params => `${dates[params.value[0]]}<br>${areas[params.value[1]]}<br>综合能耗：${fmt(params.value[2])} tce`},
      grid: {left: 30, right: 30, top: 30, bottom: 108},
      xAxis: {type: 'category', data: dates, axisLabel: {interval: 'auto', rotate: 35, margin: 12}},
      yAxis: {type: 'category', data: areas, axisLabel: {width: 110, overflow: 'truncate'}},
      visualMap: {min: 0, max: Math.max(...rows.map(row => Number(row.value_tce) || 0), 1), orient: 'horizontal', left: 'center', bottom: 8, itemWidth: 12, itemHeight: 132, text: ['高', '低'], textGap: 8, calculable: true},
      dataZoom: dates.length > 20 ? [{type: 'inside', xAxisIndex: 0}] : [],
      series: [{type: 'heatmap', data: dates.flatMap((date, dateIndex) => areas.map((area, areaIndex) => [dateIndex, areaIndex, values.get(`${date}|${area}`) || 0])), emphasis: {itemStyle: {shadowBlur: 8, shadowColor: 'rgba(0,0,0,.18)'}}}]
    });
  }

  function renderRadar(rows) {
    if (!rows.length) return showChartState('radarChart', '暂无区域绩效数据', false);
    renderRadarPicker(rows);
  }

  function renderGauge(rows) {
    const gaugeData = Array.isArray(rows) ? rows[0] : null;
    if (!gaugeData) {
      showChartState('gaugeChart', '暂无年度预算数据', false);
      return;
    }
    const rate = Number(gaugeData.execution_rate) || 0;
    const gaugeMax = Math.max(120, Math.ceil(rate / 20) * 20);
    chart('gaugeChart', {
      series: [{
        type: 'gauge',
        startAngle: 180,
        endAngle: 0,
        min: 0,
        max: gaugeMax,
        center: ['50%', '60%'],
        radius: '80%',
        splitNumber: 0,
        axisLine: {lineStyle: {width: 14, color: [[Math.min(80 / gaugeMax, 1), '#4f8f62'], [Math.min(90 / gaugeMax, 1), '#d9c56e'], [Math.min(100 / gaugeMax, 1), '#d49a3a'], [1, '#b85c4d']]}},
        axisTick: {show: false},
        splitLine: {show: false},
        axisLabel: {show: false},
        pointer: {show: true, length: '42%', width: 5},
        anchor: {show: true, size: 8, itemStyle: {color: '#1d5547'}},
        title: {show: false},
        detail: {show: true, valueAnimation: true, formatter: value => `${Number(value).toFixed(2)}%`, fontSize: 30, fontWeight: 700, offsetCenter: [0, '30%'], color: '#1d5547'},
        data: [{value: rate}]
      }]
    });
    document.getElementById('gaugeMeta').innerHTML = `<span>实际排放<strong>${fmt((Number(gaugeData.actual_emission_kg) || 0) / 1000)} tCO₂e</strong></span><span>年度预算<strong>${fmt((Number(gaugeData.total_budget_emission_kg) || 0) / 1000)} tCO₂e</strong></span><span>剩余预算<strong>${fmt((Number(gaugeData.remaining_budget_kg) || 0) / 1000)} tCO₂e</strong></span>`;
  }

  const chartRequests = [
    ['trendChart', 'charts/energy-carbon-trend', renderTrend],
    ['rankingChart', 'charts/area-carbon-ranking', renderRanking],
    ['mixChart', 'charts/energy-mix', renderMix],
    ['heatChart', 'charts/area-date-heatmap', renderHeat],
    ['radarChart', 'charts/area-performance-radar', renderRadar],
    ['gaugeChart', 'charts/budget-gauge', renderGauge]
  ];

  loadDashboard = async function () {
    const sequence = ++dashboardLoadSequence;
    const startedAt = Date.now();
    const kpis = document.getElementById('kpis');
    kpis.innerHTML = '<div class="table-state">总览指标加载中…</div>';
    showAllChartLoading();
    try {
      await waitForDashboardLayout();
    } catch (error) {
      dashboardChartIds.forEach(id => showChartState(id, error.message, true));
      return;
    }
    if (sequence !== dashboardLoadSequence || state.view !== 'dashboard') return;

    const summaryTask = api(`dashboard/summary?${qs()}`).then(summary => {
      if (sequence !== dashboardLoadSequence || state.view !== 'dashboard') return;
      renderKpis(summary);
      kpis.dataset.loadMs = String(Date.now() - startedAt);
    }).catch(error => {
      if (sequence !== dashboardLoadSequence) return;
      kpis.innerHTML = `<div class="table-state">总览指标加载失败：${esc(error.message)} <button type="button" class="btn ghost" id="retryDashboardSummary">重新加载</button></div>`;
      document.getElementById('retryDashboardSummary')?.addEventListener('click', () => loadDashboard());
    });

    const tasks = chartRequests.map(([id, endpoint, renderer]) => api(`${endpoint}?${qs()}`).then(rows => {
      if (sequence !== dashboardLoadSequence || state.view !== 'dashboard') return;
      renderer(rows);
      document.getElementById(id).dataset.loadMs = String(Date.now() - startedAt);
    }).catch(error => {
      if (sequence !== dashboardLoadSequence) return;
      showChartState(id, `加载失败：${error.message}`, true);
    }));

    await Promise.allSettled([summaryTask, ...tasks]);
    if (sequence !== dashboardLoadSequence || state.view !== 'dashboard') return;
    await nextDashboardPaint();
    dashboardChartIds.forEach(id => state.charts[id]?.resize());
  };

  const showWithDashboardLifecycle = show;
  show = function (view) {
    if (view !== 'dashboard') disposeDashboardCharts();
    return showWithDashboardLifecycle(view);
  };
})();
