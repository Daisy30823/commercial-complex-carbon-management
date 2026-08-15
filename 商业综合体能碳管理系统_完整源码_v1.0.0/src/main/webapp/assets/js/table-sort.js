(function(global){
  const prefix='commercial-carbon:table-sort:';
  function get(resource){try{return JSON.parse(sessionStorage.getItem(prefix+resource)||'null')}catch(error){return null}}
  function set(resource,value){sessionStorage.setItem(prefix+resource,JSON.stringify(value));return value}
  function clear(resource){sessionStorage.removeItem(prefix+resource)}
  function toggle(resource,key){const current=get(resource);return set(resource,{sortBy:key,sortOrder:current?.sortBy===key&&current.sortOrder==='desc'?'asc':'desc'})}
  function query(resource){const value=get(resource);return value?`sortBy=${encodeURIComponent(value.sortBy)}&sortOrder=${encodeURIComponent(value.sortOrder)}`:''}
  function header(resource,key,label){const value=get(resource),active=value?.sortBy===key,order=active?value.sortOrder:null;return `<th class="sortable-header${active?' is-sorted':''}" data-sort-key="${escapeHtml(key)}" tabindex="0" role="columnheader" aria-sort="${order==='asc'?'ascending':order==='desc'?'descending':'none'}"><span>${escapeHtml(label)}</span><span class="sort-indicator" aria-hidden="true">${order==='asc'?'↑':order==='desc'?'↓':'↕'}</span></th>`}
  function bind(root,resource,onChange){const element=typeof root==='string'?document.querySelector(root):root;if(!element)return;const activate=event=>{const target=event.target.closest('.sortable-header');if(!target||!element.contains(target))return;if(event.type==='keydown'&&!['Enter',' '].includes(event.key))return;event.preventDefault();toggle(resource,target.dataset.sortKey);onChange(get(resource))};element.onclick=activate;element.onkeydown=activate}
  function sortRows(resource,rows){const value=get(resource);if(!value)return [...rows];const direction=value.sortOrder==='asc'?1:-1,key=value.sortBy;return rows.map((row,index)=>({row,index})).sort((a,b)=>{const av=a.row[key],bv=b.row[key];if(av==null&&bv==null)return a.index-b.index;if(av==null)return 1;if(bv==null)return -1;const an=Number(av),bn=Number(bv),result=Number.isFinite(an)&&Number.isFinite(bn)?an-bn:String(av).localeCompare(String(bv),'zh-CN',{numeric:true,sensitivity:'base'});return result===0?a.index-b.index:result*direction}).map(item=>item.row)}
  function escapeHtml(value){return String(value??'').replace(/[&<>"']/g,char=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]))}
  global.TableSort={get,set,clear,toggle,query,header,bind,sortRows};
})(window);
