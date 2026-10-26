import { useState } from 'react';
import { AlertTriangle, ArrowDownToLine, ArrowRight, Boxes, Camera, ChartNoAxesCombined, CircleDollarSign, Edit3, MessageCircle, Package, Phone, Plus, RefreshCw, RotateCcw, Search, ShoppingBag, Sparkles, Store, Trash2, Truck, Users, Zap } from 'lucide-react';
import { date, money, number, playBeep, query, request, useAction, useResource } from './api';
import { ActionNotice, Badge, Button, Card, Confirm, Empty, Field, Modal, Notice, RecordForm, Resource, SectionTitle, Stat } from './ui';

export function BarcodeScannerModal({ onDetected, onClose, items = [] }) {
  const [manualCode, setManualCode] = useState('');
  const [continuous, setContinuous] = useState(false);
  const [lastScanned, setLastScanned] = useState('');

  function triggerScan(code) {
    if (!code) return;
    playBeep();
    if (navigator.vibrate) navigator.vibrate(50);
    setLastScanned(code);
    onDetected(code);
    if (!continuous) onClose();
  }

  return (
    <Modal title="Kamera Scan Barcode / QR" onClose={onClose}>
      <div className="scanner-box">
        <div className="scanner-viewfinder">
          <Camera size={38} />
          <strong>Arahkan kamera ke Barcode (EAN-13 / Code 128 / QR)</strong>
          <small>Audio beep & haptic 50ms aktif saat kode terdeteksi</small>
        </div>
        <label className="field check-field" style={{ marginBottom: 12 }}>
          <span>Mode Pemindaian Beruntun (Continuous Scan Opname)</span>
          <input type="checkbox" checked={continuous} onChange={e => setContinuous(e.target.checked)} />
        </label>
        {lastScanned && <Notice success>Kode terdeteksi: {lastScanned}</Notice>}
        <form onSubmit={e => { e.preventDefault(); triggerScan(manualCode.trim()); }}>
          <Field label="Input / Simulasi Scan SKU Barcode" placeholder="Contoh: SKU-001 atau 8991234567890" value={manualCode} onChange={e => setManualCode(e.target.value)} />
          <div className="form-actions">
            <Button type="button" variant="secondary" onClick={onClose}>Tutup</Button>
            <Button type="submit" disabled={!manualCode.trim()}><Zap size={16} /> Proses Barcode</Button>
          </div>
        </form>
        {items.length > 0 && (
          <div style={{ marginTop: 14 }}>
            <small className="eyebrow">SIMULASI SCAN CEPAT DARI KATALOG</small>
            <div className="filter-pills" style={{ marginTop: 8, marginBottom: 0 }}>
              {items.slice(0, 6).map(it => (
                <button type="button" key={it.id} onClick={() => triggerScan(it.sku)}>
                  {it.sku} · {it.name}
                </button>
              ))}
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
}

export function Dashboard({ navigate, user }) {
  const data = useResource('/dashboard');
  const restockAction = useAction();
  const storeAction = useAction();

  return (
    <div>
      <SectionTitle eyebrow="DASHBOARD EKSEKUTIF" title={`Selamat datang, ${user.name?.split(' ')[0] || 'Juragan'}.`} description="Pandangan 360 derajat atas kondisi bisnis multi-cabang hari ini.">
        <Button variant="secondary" onClick={data.reload}><RefreshCw size={16} /> Perbarui</Button>
        <Button onClick={() => navigate('cashier')}><Plus size={17} /> Buka Kasir POS</Button>
      </SectionTitle>
      <ActionNotice action={restockAction} />
      <ActionNotice action={storeAction} />
      <Resource resource={data}>{d => {
        const avail = d.stock_availability || {
          in_stock: Math.max(0, (d.total_products || 8) - (d.kpi?.low_stock_alerts || 0)),
          low_stock: d.kpi?.low_stock_alerts || 0,
          out_of_stock: 0,
          total: d.total_products || 8,
        };
        const totalSku = Math.max(1, avail.total || 1);
        const inStockPct = Math.round((avail.in_stock / totalSku) * 100);
        const lowStockPct = Math.round((avail.low_stock / totalSku) * 100);
        const primaryOutlet = d.outlets_leaderboard?.[0];

        return (
          <div>
            {primaryOutlet && (
              <Card style={{ marginBottom: 18, padding: '14px 18px', display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <span className="product-icon"><Store size={20} /></span>
                  <div>
                    <strong>Cabang Aktif: {primaryOutlet.name}</strong>
                    <small style={{ display: 'block', color: '#6B7280' }}>{primaryOutlet.address} · Status: {primaryOutlet.is_open ? 'BUKA' : 'TUTUP'}</small>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <Button variant="secondary" busy={storeAction.busy} onClick={() => storeAction.run(async () => { await request(`/stores/${primaryOutlet.id}/toggle-status`, { method: 'PATCH' }); data.reload(); }, 'Status toko diperbarui.')}>
                    {primaryOutlet.is_open ? 'Tutup Toko Sementara' : 'Buka Toko Sekarang'}
                  </Button>
                  <Button variant="secondary" onClick={() => navigate('inventory')}><Plus size={15} /> Tambah Produk</Button>
                  <Button variant="dark" onClick={() => navigate('supri')}><Sparkles size={15} /> Tanya Supri AI</Button>
                </div>
              </Card>
            )}

            <div className="stats-grid">
              <Stat label="Total Penjualan Hari Ini" value={money(d.kpi.today_sales)} detail="+20% vs rata-rata harian" icon={CircleDollarSign} tone="lime" />
              <Stat label="Omzet Bulan Berjalan" value={money(d.kpi.monthly_turnover)} detail="Total pendapatan kotor" icon={ChartNoAxesCombined} tone="dark" />
              <Stat label="Total Produk Terdaftar" value={number(d.kpi.total_products ?? avail.total)} detail={`${number(d.kpi.total_customers)} pelanggan (${number(d.kpi.vip_customers)} VIP)`} icon={Package} />
              <Stat label="Stok Kritis (Low/Out)" value={number(d.kpi.low_stock_alerts)} detail="Perlu restock segera" icon={AlertTriangle} />
            </div>

            <div className="dashboard-grid">
              <Card className="sales-chart">
                <div className="card-heading">
                  <div>
                    <span className="eyebrow">SALES OVERVIEW TREND</span>
                    <h3>Performa Omzet 7 Hari</h3>
                    <small className="muted">Peak velocity hours: 19:00 - 21:00 WIB</small>
                  </div>
                  <Badge>Rupiah</Badge>
                </div>
                <div className="w-full h-28 pt-2">
                  <svg className="w-full h-full overflow-visible" preserveAspectRatio="none" viewBox="0 0 340 100">
                    <defs>
                      <linearGradient id="salesGrad" x1="0%" x2="0%" y1="0%" y2="100%">
                        <stop offset="0%" stopColor="#B9D9FA" stopOpacity="0.75" />
                        <stop offset="100%" stopColor="#B9D9FA" stopOpacity="0.0" />
                      </linearGradient>
                    </defs>
                    <line stroke="#E5E7EB" strokeDasharray="3 3" strokeWidth="1" x1="0" x2="340" y1="20" y2="20" />
                    <line stroke="#E5E7EB" strokeDasharray="3 3" strokeWidth="1" x1="0" x2="340" y1="60" y2="60" />
                    <path d="M 0,85 C 45,78 70,60 110,65 C 150,70 180,35 220,40 C 260,45 290,15 340,12 L 340,100 L 0,100 Z" fill="url(#salesGrad)" />
                    <path d="M 0,85 C 45,78 70,60 110,65 C 150,70 180,35 220,40 C 260,45 290,15 340,12" fill="none" stroke="#4A7FB0" strokeLinecap="round" strokeWidth="2.5" />
                    <circle cx="340" cy="12" fill="#0F0F4A" r="4.5" stroke="#FFFFFF" strokeWidth="2" />
                  </svg>
                </div>
                {d.sales_velocity_chart?.length ? (
                  <div className="bar-chart" role="img" aria-label="Grafik pendapatan harian 7 hari">
                    {d.sales_velocity_chart.map((point, index) => (
                      <div className="bar-column" key={point.date}>
                        <span className="bar-value">{money(point.revenue)}</span>
                        <div className={`bar ${index === d.sales_velocity_chart.length - 1 ? 'highlight' : ''}`} style={{ height: `${Math.max(4, Number(point.revenue) / Math.max(1, ...d.sales_velocity_chart.map(p => Number(p.revenue))) * 100)}px` }} />
                        <span>{new Date(`${point.date}T12:00:00`).toLocaleDateString('id-ID', { weekday: 'short' })}</span>
                      </div>
                    ))}
                  </div>
                ) : null}
                <div className="chart-foot">
                  <span><i className="legend-dot" /> Omzet Harian Tercatat</span>
                  <button className="text-button" onClick={() => navigate('reports')}>Laporan P&L <ArrowRight size={15} /></button>
                </div>
              </Card>

              <Card>
                <div className="card-heading">
                  <div>
                    <span className="eyebrow">STOCK LEVEL BREAKDOWN</span>
                    <h3>Tingkat Ketersediaan Stok</h3>
                    <small className="muted">Rasio inventaris aktif ({avail.total} SKU)</small>
                  </div>
                  <Badge>{avail.total} SKU</Badge>
                </div>
                <div className="flex items-center justify-between gap-4 pt-1 my-3">
                  <div className="relative w-28 h-28 flex items-center justify-center flex-shrink-0">
                    <svg className="w-full h-full -rotate-90 transform" viewBox="0 0 100 100">
                      <circle cx="50" cy="50" fill="none" r="38" stroke="#F1F3FF" strokeWidth="12" />
                      <circle cx="50" cy="50" fill="none" r="38" stroke="#0F0F4A" strokeDasharray={`${(inStockPct * 238.8) / 100} 238.8`} strokeDashoffset="0" strokeLinecap="round" strokeWidth="12" />
                      <circle cx="50" cy="50" fill="none" r="38" stroke="#B9D9FA" strokeDasharray={`${(lowStockPct * 238.8) / 100} 238.8`} strokeDashoffset={`-${(inStockPct * 238.8) / 100}`} strokeLinecap="round" strokeWidth="12" />
                      <circle cx="50" cy="50" fill="none" r="38" stroke="#E8EEFB" strokeDasharray={`${(Math.max(0, 100 - inStockPct - lowStockPct) * 238.8) / 100} 238.8`} strokeDashoffset={`-${((inStockPct + lowStockPct) * 238.8) / 100}`} strokeLinecap="round" strokeWidth="12" />
                    </svg>
                    <div className="absolute inset-0 flex flex-col items-center justify-center pointer-events-none">
                      <span className="font-bold text-base leading-none text-primary">{inStockPct}%</span>
                      <small className="text-text-muted text-[10px] mt-0.5">In Stock</small>
                    </div>
                  </div>
                  <div className="grow space-y-1.5">
                    <div className="stock-line"><span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><i style={{ width: 10, height: 10, borderRadius: 99, background: '#0F0F4A', display: 'inline-block' }} /> In Stock (Aman)</span><strong>{avail.in_stock} SKU ({inStockPct}%)</strong></div>
                    <div className="stock-line"><span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><i style={{ width: 10, height: 10, borderRadius: 99, background: '#B9D9FA', display: 'inline-block' }} /> Low Stock (&lt;30)</span><strong>{avail.low_stock} SKU ({lowStockPct}%)</strong></div>
                    <div className="stock-line"><span style={{ display: 'flex', alignItems: 'center', gap: 6 }}><i style={{ width: 10, height: 10, borderRadius: 99, background: '#E8EEFB', display: 'inline-block' }} /> Out of Stock</span><strong>{avail.out_of_stock} SKU</strong></div>
                  </div>
                </div>
                {d.stock_alerts?.length > 0 && (
                  <div style={{ borderTop: '1px solid #E5E7EB', paddingTop: 12 }}>
                    <div className="card-heading" style={{ marginBottom: 8 }}>
                      <strong style={{ fontSize: 12 }}>Peringatan Stok Kritis (Top 3)</strong>
                      <Button variant="primary" busy={restockAction.busy} onClick={() => restockAction.run(async () => { await request('/inventory/batch-restock', { method: 'POST' }); data.reload(); }, 'Batch restock otomatis berhasil dijalankan.')}>
                        <Zap size={14} /> Restock Now
                      </Button>
                    </div>
                    {d.stock_alerts.map(alert => (
                      <div key={alert.id} className="stock-line" style={{ fontSize: 12 }}>
                        <span>{alert.name} ({alert.sku})</span>
                        <Badge tone={alert.is_out_of_stock ? 'danger' : 'warning'}>{alert.stock_in} / {alert.total_qty} unit</Badge>
                      </div>
                    ))}
                  </div>
                )}
              </Card>

              <Card>
                <div className="card-heading"><h3>Top Produk Terlaris</h3><button className="text-button" onClick={() => navigate('inventory')}>Inventaris <ArrowRight size={14} /></button></div>
                {d.top_products?.length ? (
                  <div className="item-list">
                    {d.top_products.map(item => (
                      <div className="list-row" key={item.id}>
                        <span className="product-icon"><Package size={22} /></span>
                        <div className="grow"><strong>{item.name}</strong><small>{item.sku} · {item.category}</small></div>
                        <div className="align-right"><strong>{money(item.price)}</strong><small>{number(item.stock_in)} unit</small></div>
                      </div>
                    ))}
                  </div>
                ) : <Empty title="Belum ada produk terjual" />}
              </Card>

              <Card>
                <div className="card-heading"><h3>Aktivitas Sistem Terkini</h3><Badge>Live</Badge></div>
                {d.recent_activities?.length ? (
                  <div className="item-list">
                    {d.recent_activities.map(item => (
                      <div className="list-row" key={item.id}>
                        <span className="activity-icon"><ShoppingBag size={18} /></span>
                        <div><strong>{item.title}</strong><small>{item.subtitle}</small><small className="muted">{item.time}</small></div>
                      </div>
                    ))}
                  </div>
                ) : <Empty title="Belum ada aktivitas">Transaksi baru akan tampil di sini.</Empty>}
              </Card>
            </div>
          </div>
        );
      }}</Resource>
    </div>
  );
}

const productFields = [
  { name: 'name', label: 'Nama produk', required: true }, { name: 'sku', label: 'SKU unik / Barcode', required: true },
  { name: 'category', label: 'Kategori', required: true }, { name: 'tag', label: 'Label', default: 'Fast Moving', options: ['Fast Moving', 'Regular', 'Discounted', 'Low Demand', 'Dead Items', 'Trending', 'New Arrival', 'Low Stock', 'Over Stock'] },
  { name: 'price', label: 'Harga jual (Rp)', type: 'number', min: 0, required: true }, { name: 'cost_price', label: 'Harga modal / HPP (Rp)', type: 'number', min: 0, required: true },
  { name: 'total_qty', label: 'Target kapasitas stok', type: 'number', min: 1, required: true }, { name: 'stock_in', label: 'Stok tersedia', type: 'number', min: 0, required: true },
  { name: 'priority', label: 'Prioritas', options: [{ value: 'low', label: 'Rendah' }, { value: 'medium', label: 'Sedang' }, { value: 'high', label: 'Tinggi' }], default: 'medium' },
  { name: 'description', label: 'Deskripsi / Gudang', multiline: true },
];

function ProductDialogs({ modal, setModal, reload, reloadTrash }) {
  if (!modal) return null;
  const close = () => setModal(null);
  if (modal.type === 'soft-delete') {
    return (
      <RecordForm
        title={`Soft Delete · ${modal.item.name}`}
        fields={[
          { name: 'reason', label: 'Alasan penghapusan sementara', options: ['Discontinued', 'Rusak / Damaged', 'Kadaluarsa / Expired', 'Salah Input SKU'], default: 'Discontinued', required: true },
          { name: 'hold_days', label: 'Masa retensi sebelum hapus permanen (hari)', type: 'number', min: 1, max: 365, default: 30, required: true },
        ]}
        submitLabel="Pindahkan ke Recently Deleted"
        onClose={close}
        onSave={async values => {
          await request(`/inventory/${modal.item.id}/soft-delete`, { method: 'POST', body: values });
          reload();
          reloadTrash?.();
        }}
      />
    );
  }
  if (modal.type === 'delete') return <Confirm title="Hapus permanen produk?" onClose={close} label="Hapus permanen" onConfirm={async () => { await request(`/inventory/${modal.item.id}`, { method: 'DELETE' }); reload(); reloadTrash?.(); }}>Produk {modal.item.name} akan dihapus permanen dari database.</Confirm>;
  if (modal.type === 'restock') return <RecordForm title={`Quick Add Stock · ${modal.item.name}`} fields={[{ name: 'qty', label: 'Jumlah barang yang diterima', type: 'number', min: 1, required: true }]} onClose={close} submitLabel="Catat barang masuk" onSave={async values => { await request(`/inventory/${modal.item.id}/restock`, { method: 'POST', body: values }); reload(); }} />;
  const editing = modal.type === 'edit';
  return <RecordForm title={editing ? 'Ubah produk' : 'Tambah produk'} fields={productFields.map(field => field.name === 'sku' && editing ? { ...field, disabled: true } : field)} initial={modal.item} onClose={close} onSave={async values => { await request(editing ? `/inventory/${modal.item.id}` : '/inventory', { method: editing ? 'PUT' : 'POST', body: { ...values, is_out_of_stock: values.stock_in <= 0 } }); reload(); }} />;
}

export function Inventory() {
  const [tab, setTab] = useState('active');
  const [search, setSearch] = useState('');
  const [tag, setTag] = useState('');
  const [category, setCategory] = useState('');
  const [modal, setModal] = useState(null);
  const [scannerOpen, setScannerOpen] = useState(false);
  const resource = useResource(`/inventory?${query({ search, tag, category })}`);
  const trashResource = useResource('/inventory/recently-deleted');
  const categories = useResource('/inventory/categories');
  const action = useAction();

  return (
    <div>
      <SectionTitle eyebrow="MANAJEMEN INVENTARIS & KONTROL STOK" title="Stok rapi, bisnis siap." description="Katalog aktif, scan barcode, dan masa retensi Recently Deleted.">
        <Button variant="secondary" onClick={() => setScannerOpen(true)}><Camera size={16} /> Scan Barcode</Button>
        <Button onClick={() => setModal({ type: 'add' })}><Plus size={17} /> Tambah produk</Button>
      </SectionTitle>

      <div className="filter-pills" role="tablist" aria-label="Tab Katalog Inventaris">
        <button role="tab" aria-selected={tab === 'active'} className={tab === 'active' ? 'selected' : ''} onClick={() => setTab('active')}>
          Aktif (Katalog Utama) {resource.data ? `(${resource.data.total_items})` : ''}
        </button>
        <button role="tab" aria-selected={tab === 'trash'} className={tab === 'trash' ? 'selected' : ''} onClick={() => setTab('trash')}>
          Recently Deleted / Tempat Sampah {trashResource.data ? `(${trashResource.data.total_items})` : ''}
        </button>
      </div>

      <ActionNotice action={action} />

      {tab === 'active' ? (
        <div>
          <div className="filter-bar">
            <div className="search-field">
              <Search size={18} />
              <input aria-label="Cari produk, SKU atau kategori" placeholder="Cari produk, SKU, atau scan barcode…" value={search} onChange={event => setSearch(event.target.value)} />
              <button type="button" className="icon-button" aria-label="Buka kamera scanner barcode" onClick={() => setScannerOpen(true)}><Camera size={17} /></button>
            </div>
            <Field label="Kategori" value={category} onChange={event => setCategory(event.target.value)}>
              <option value="">Semua kategori</option>
              {categories.data?.map(item => <option key={item.id} value={item.name}>{item.name}</option>)}
            </Field>
            <Button variant="secondary" onClick={resource.reload} aria-label="Perbarui inventaris"><RefreshCw size={17} /></Button>
          </div>
          <Notice error>{categories.error}</Notice>
          <Resource resource={resource}>{d => (
            <div>
              <div className="filter-pills" aria-label="Filter label">
                <button className={!tag ? 'selected' : ''} onClick={() => setTag('')}>Semua <span>{d.total_items}</span></button>
                {['Fast Moving', 'Regular', 'Discounted', 'Low Demand', 'Dead Items', 'Trending'].map(value => (
                  <button key={value} className={tag === value ? 'selected' : ''} onClick={() => setTag(value)}>{value}</button>
                ))}
              </div>
              <div className="inventory-summary">
                <span><Boxes size={17} /> {number(d.total_items)} SKU aktif</span>
                <span>Nilai stok (HPP): <strong>{money(d.items.reduce((sum, item) => sum + Number(item.cost_price) * Number(item.stock_in), 0))}</strong></span>
              </div>
              {d.items.length ? (
                <div className="product-grid">
                  {d.items.map(item => {
                    const out = item.is_out_of_stock || Number(item.stock_in) <= 0;
                    const low = !out && Number(item.stock_in) < 30;
                    const marginPct = Number(item.price) > 0 ? Math.round(((Number(item.price) - Number(item.cost_price)) / Number(item.price)) * 100) : 0;
                    return (
                      <Card className="product-card" key={item.id}>
                        <div className="product-top">
                          <span className="product-icon"><Package size={29} /></span>
                          <Badge tone={out ? 'danger' : low ? 'warning' : 'success'}>
                            {out ? 'Out of Stock' : low ? 'Low Stock' : item.tag}
                          </Badge>
                        </div>
                        <small className="eyebrow">{item.category} / {item.sku}</small>
                        <h3>{item.name}</h3>
                        <div className="product-price">
                          {money(item.price)}
                          <small>HPP {money(item.cost_price)} · Margin {marginPct}%</small>
                        </div>
                        <div className="stock-line">
                          <span>Sisa Stok</span>
                          <strong>{number(item.stock_in)} <small>/ {number(item.total_qty)}</small></strong>
                        </div>
                        <meter min="0" max={Math.max(1, item.total_qty)} value={item.stock_in} aria-label={`Stok ${item.name}`} />
                        <div className="product-actions">
                          <Button variant="secondary" onClick={() => setModal({ type: 'restock', item })}><Plus size={15} /> Quick Stock</Button>
                          <button className="icon-button" aria-label={`Ubah ${item.name}`} onClick={() => setModal({ type: 'edit', item })}><Edit3 size={17} /></button>
                          <button className="icon-button danger-text" title="Pindahkan ke Recently Deleted" aria-label={`Soft delete ${item.name}`} onClick={() => setModal({ type: 'soft-delete', item })}><Trash2 size={17} /></button>
                        </div>
                      </Card>
                    );
                  })}
                </div>
              ) : <Card><Empty title="Produk belum ditemukan">Coba kata kunci lain atau tambahkan produk baru.</Empty></Card>}
            </div>
          )}</Resource>
        </div>
      ) : (
        <Resource resource={trashResource}>{d => (
          <Card>
            <div className="card-heading">
              <div>
                <h3>Recently Deleted (Masa Retensi / Grace Period)</h3>
                <small className="muted">Produk yang di-soft delete ditahan sementara sebelum dihapus permanen.</small>
              </div>
              {d.items.length > 0 && (
                <Button variant="danger" busy={action.busy} onClick={() => action.run(async () => { await request('/inventory/purge-expired', { method: 'POST', body: { force: true } }); trashResource.reload(); }, 'Tempat sampah berhasil dibersihkan.')}>
                  <Trash2 size={15} /> Bersihkan Semua
                </Button>
              )}
            </div>
            {d.items.length ? (
              <div className="item-list">
                {d.items.map(item => (
                  <div className="list-row wrap-row" key={item.id}>
                    <span className="product-icon"><Package size={20} /></span>
                    <div className="grow">
                      <strong>{item.name} ({item.sku})</strong>
                      <small>Alasan: <strong>{item.deletedReason || item.deleted_reason || 'Discontinued'}</strong> · Sisa retensi: <strong>{item.daysRemaining ?? 30} hari</strong></small>
                      <small className="muted">Hapus permanen setelah: {date(item.deleteAfter || item.delete_after)}</small>
                    </div>
                    <div style={{ display: 'flex', gap: 8 }}>
                      <Button variant="secondary" busy={action.busy} onClick={() => action.run(async () => { await request(`/inventory/${item.id}/restore`, { method: 'POST' }); resource.reload(); trashResource.reload(); }, `${item.name} dipulihkan ke katalog aktif.`)}>
                        <RotateCcw size={15} /> Restore
                      </Button>
                      <button className="icon-button danger-text" aria-label={`Hapus permanen ${item.name}`} onClick={() => setModal({ type: 'delete', item })}>
                        <Trash2 size={17} />
                      </button>
                    </div>
                  </div>
                ))}
              </div>
            ) : <Empty title="Tempat sampah kosong">Tidak ada produk dalam masa penahanan soft delete.</Empty>}
          </Card>
        )}</Resource>
      )}

      {scannerOpen && (
        <BarcodeScannerModal
          items={resource.data?.items || []}
          onClose={() => setScannerOpen(false)}
          onDetected={code => { setTab('active'); setSearch(code); }}
        />
      )}
      <ProductDialogs modal={modal} setModal={setModal} reload={resource.reload} reloadTrash={trashResource.reload} />
    </div>
  );
}

const delayedSupplierShipments = [
  { id: 'PO-2026-101', productName: 'Backpack Explorer', sku: 'SKU-770', supplier: 'PT Tas Nusantara', phone: '6281234567890', delayedDays: 5, status: 'In Transit (Late)' },
  { id: 'PO-2026-104', productName: 'T-Shirts Cotton Combed', sku: 'SKU-300', supplier: 'CV Solo Textile', phone: '6281398765432', delayedDays: 4, status: 'Pending Approval' },
  { id: 'PO-2026-109', productName: 'Helmets Pro Safety', sku: 'SKU-900', supplier: 'Surya Helmet Indah', phone: '6281122334455', delayedDays: 3, status: 'In Transit (Late)' },
];

export function Shipments() {
  const resource = useResource('/inventory');
  const [modal, setModal] = useState(null);

  function contactSupplierWhatsApp(po) {
    const msg = encodeURIComponent(`Halo ${po.supplier}, menanyakan status PO #${po.id} atas produk ${po.productName} (${po.sku}) yang terlambat tiba ${po.delayedDays} hari dari estimasi ETA. Mohon update nomor resi pengiriman.`);
    window.open(`https://wa.me/${po.phone}?text=${msg}`, '_blank', 'noopener,noreferrer');
  }

  return (
    <div>
      <SectionTitle eyebrow="PURCHASES & SHIPMENTS" title="Pengadaan & Pelacakan Pengiriman." description="Monitor PO restock barang ke supplier dan tindak lanjuti keterlambatan logistik.">
        <Button variant="secondary" onClick={resource.reload}><RefreshCw size={16} /> Perbarui</Button>
      </SectionTitle>

      <Card style={{ marginBottom: 20 }}>
        <div className="card-heading">
          <div>
            <span className="eyebrow">STILL NOT ARRIVED</span>
            <h3>Keterlambatan Pengiriman Supplier</h3>
          </div>
          <Badge tone="warning">{delayedSupplierShipments.length} PO Terlambat</Badge>
        </div>
        <div className="item-list">
          {delayedSupplierShipments.map(po => (
            <div className="list-row wrap-row" key={po.id}>
              <span className="product-icon"><Truck size={20} /></span>
              <div className="grow">
                <strong>{po.productName} · <small>{po.id}</small></strong>
                <small>Supplier: {po.supplier} · SKU: {po.sku} · Terlambat {po.delayedDays} hari</small>
              </div>
              <Badge tone="warning">{po.status}</Badge>
              <Button variant="secondary" onClick={() => contactSupplierWhatsApp(po)}>
                <MessageCircle size={15} /> Hubungi WhatsApp Supplier
              </Button>
            </div>
          ))}
        </div>
      </Card>

      <Resource resource={resource}>{d => (
        <div>
          <div className="stats-grid three">
            <Stat label="Produk dalam inventaris" value={number(d.total_items)} icon={Boxes} />
            <Stat label="Produk stok rendah" value={number(d.items.filter(item => item.stock_in < item.total_qty * .3).length)} icon={Truck} tone="lime" />
            <Stat label="Total unit tersedia" value={number(d.items.reduce((sum, item) => sum + Number(item.stock_in), 0))} icon={Package} />
          </div>
          <Card>
            <div className="card-heading"><h3>Penerimaan Barang Masuk (Receive PO)</h3><Badge>Update Stok Gudang</Badge></div>
            {d.items.length ? (
              <div className="item-list">
                {d.items.map(item => (
                  <div className="list-row wrap-row" key={item.id}>
                    <span className="product-icon"><Package size={20} /></span>
                    <div className="grow"><strong>{item.name}</strong><small>{item.sku} · {number(item.stock_in)} unit tersedia</small></div>
                    <Button variant="secondary" onClick={() => setModal({ type: 'restock', item })}><ArrowDownToLine size={16} /> Terima Barang</Button>
                  </div>
                ))}
              </div>
            ) : <Empty title="Belum ada produk untuk direstock" />}
          </Card>
        </div>
      )}</Resource>
      <ProductDialogs modal={modal} setModal={setModal} reload={resource.reload} />
    </div>
  );
}

const customerFields = [
  { name: 'name', label: 'Nama pelanggan', required: true },
  { name: 'phone', label: 'Nomor telepon / WhatsApp', type: 'tel', required: true },
  { name: 'email', label: 'Email', type: 'email' },
  { name: 'city', label: 'Kota' },
  { name: 'tier', label: 'Segmen / Tier pelanggan', options: ['Regular', 'VIP', 'Wholesale', 'Baru'], default: 'Regular' },
  { name: 'status', label: 'Status', options: ['Aktif', 'Nonaktif'], default: 'Aktif' },
  { name: 'notes', label: 'Catatan preferensi', multiline: true },
];

export function Customers() {
  const [search, setSearch] = useState('');
  const [tier, setTier] = useState('');
  const [modal, setModal] = useState(null);
  const resource = useResource(`/customers?${query({ search, tier })}`);

  return (
    <div>
      <SectionTitle eyebrow="CRM & MANAJEMEN PELANGGAN" title="Pelanggan setia, aset utama." description="Klasifikasi tier, Customer Lifetime Value (LTV), dan kontak cepat WhatsApp.">
        <Button onClick={() => setModal({ type: 'add' })}><Plus size={17} /> Tambah pelanggan</Button>
      </SectionTitle>
      <div className="filter-pills">
        {[
          { value: '', label: 'Semua' },
          { value: 'Wholesale', label: 'Wholesale B2B' },
          { value: 'Regular', label: 'Retail Direct' },
          { value: 'VIP', label: 'VIP / Key Accounts' },
        ].map(seg => (
          <button key={seg.label} className={tier === seg.value ? 'selected' : ''} onClick={() => setTier(seg.value)}>{seg.label}</button>
        ))}
      </div>
      <div className="filter-bar">
        <div className="search-field">
          <Search size={18} />
          <input aria-label="Cari pelanggan" placeholder="Cari nama, telepon, atau kota…" value={search} onChange={event => setSearch(event.target.value)} />
        </div>
      </div>
      <Resource resource={resource}>{d => (
        <div>
          <div className="stats-grid three">
            <Stat label="Total pelanggan" value={number(d.summary.total_customers)} icon={Users} tone="lime" />
            <Stat label="Pelanggan VIP" value={number(d.summary.vip_customers)} icon={Users} />
            <Stat label="Customer Lifetime Value (LTV)" value={money(d.summary.total_spent)} icon={CircleDollarSign} />
          </div>
          <Card>
            {d.customers.length ? (
              <div className="customer-grid">
                {d.customers.map(item => {
                  const cleanPhone = String(item.phone || '').replace(/[^0-9]/g, '').replace(/^0/, '62');
                  return (
                    <article className="customer-card" key={item.id}>
                      <div className="card-heading">
                        <span className="avatar">{item.name.charAt(0)}</span>
                        <Badge tone={item.tier === 'VIP' ? 'lime' : ''}>{item.tier}</Badge>
                      </div>
                      <h3>{item.name}</h3>
                      <p>{item.phone}<br />{item.email || 'Tanpa email'}<br />{item.city}</p>
                      <div className="stock-line">
                        <span>{number(item.total_orders)} order</span>
                        <strong>LTV {money(item.total_spent)}</strong>
                      </div>
                      <div className="product-actions">
                        <a className="icon-button" href={`tel:${item.phone}`} title={`Telepon ${item.name}`} aria-label={`Telepon ${item.name}`}><Phone size={15} /></a>
                        <a className="icon-button" href={`https://wa.me/${cleanPhone}`} target="_blank" rel="noopener noreferrer" title={`WhatsApp ${item.name}`} aria-label={`WhatsApp ${item.name}`}><MessageCircle size={15} /></a>
                        <Button variant="secondary" onClick={() => setModal({ type: 'edit', item })}><Edit3 size={15} /> Ubah</Button>
                        <button className="icon-button danger-text" aria-label={`Hapus pelanggan ${item.name}`} onClick={() => setModal({ type: 'delete', item })}><Trash2 size={17} /></button>
                      </div>
                    </article>
                  );
                })}
              </div>
            ) : <Empty title="Pelanggan belum ditemukan" />}
          </Card>
        </div>
      )}</Resource>
      {modal?.type === 'delete' ? (
        <Confirm title="Hapus pelanggan?" onClose={() => setModal(null)} label="Hapus pelanggan" onConfirm={async () => { await request(`/customers/${modal.item.id}`, { method: 'DELETE' }); resource.reload(); }}>{modal.item.name} akan dihapus dari daftar pelanggan.</Confirm>
      ) : modal && (
        <RecordForm title={modal.type === 'edit' ? 'Ubah pelanggan' : 'Pelanggan baru'} fields={customerFields} initial={modal.item} onClose={() => setModal(null)} onSave={async values => { await request(modal.type === 'edit' ? `/customers/${modal.item.id}` : '/customers', { method: modal.type === 'edit' ? 'PUT' : 'POST', body: values }); resource.reload(); }} />
      )}
    </div>
  );
}

const outletFields = [
  { name: 'name', label: 'Nama outlet', required: true },
  { name: 'code', label: 'Kode unik outlet', required: true },
  { name: 'city', label: 'Kota', required: true },
  { name: 'address', label: 'Alamat lengkap', required: true },
  { name: 'manager', label: 'Nama manajer cabang', required: true },
  { name: 'phone', label: 'Telepon cabang', required: true },
  { name: 'operating_hours', label: 'Jam operasional', default: '09:00 - 22:00 WIB' },
  { name: 'terminals_count', label: 'Jumlah kasir aktif', type: 'number', min: 0, default: 1 },
  { name: 'staff_count', label: 'Jumlah staf bertugas', type: 'number', min: 0, default: 1 },
];

export function Outlets() {
  const resource = useResource('/stores');
  const [adding, setAdding] = useState(false);
  const action = useAction();

  return (
    <div>
      <SectionTitle eyebrow="MANAJEMEN MULTI-CABANG RITEL" title="Satu usaha. Banyak peluang." description="Monitoring operasional multi-outlet real-time dan saklar buka/tutup darurat.">
        <Button onClick={() => setAdding(true)}><Plus size={17} /> Tambah outlet</Button>
      </SectionTitle>
      <ActionNotice action={action} />
      <Resource resource={resource}>{d => (
        <div>
          <div className="stats-grid three">
            <Stat label="Outlet buka" value={`${d.summary.open_outlets} / ${d.summary.total_outlets}`} icon={Store} tone="lime" />
            <Stat label="Terminal kasir aktif" value={number(d.summary.total_terminals)} icon={ShoppingBag} />
            <Stat label="Staf bertugas" value={number(d.summary.total_staff)} icon={Users} />
          </div>
          <div className="product-grid">
            {d.outlets.map(outlet => (
              <Card key={outlet.id}>
                <div className="card-heading">
                  <span className="product-icon"><Store size={26} /></span>
                  <Badge tone={outlet.is_open ? 'success' : 'danger'}>{outlet.is_open ? 'BUKA' : 'TUTUP SEMENTARA'}</Badge>
                </div>
                <small className="eyebrow">{outlet.code} · {outlet.city}</small>
                <h3>{outlet.name}</h3>
                <p>{outlet.address}</p>
                <dl className="details">
                  <div><dt>Manajer</dt><dd>{outlet.manager}</dd></div>
                  <div><dt>Telepon</dt><dd>{outlet.phone}</dd></div>
                  <div><dt>Kasir / Staf</dt><dd>{outlet.terminals_count} POS · {outlet.staff_count} staf</dd></div>
                  <div><dt>Penjualan Harian</dt><dd>{money(outlet.daily_sales || 0)}</dd></div>
                </dl>
                <Button variant={outlet.is_open ? 'secondary' : 'primary'} busy={action.busy} onClick={() => action.run(async () => { await request(`/stores/${outlet.id}/toggle-status`, { method: 'PATCH' }); resource.reload(); }, 'Status operasional cabang diperbarui.')}>
                  {outlet.is_open ? 'Tutup Sementara' : 'Buka Toko'}
                </Button>
              </Card>
            ))}
          </div>
          {!d.outlets.length && <Card><Empty title="Belum ada outlet" /></Card>}
        </div>
      )}</Resource>
      {adding && <RecordForm title="Tambah outlet cabang" fields={outletFields} onClose={() => setAdding(false)} onSave={async values => { await request('/stores', { method: 'POST', body: values }); resource.reload(); }} />}
    </div>
  );
}
