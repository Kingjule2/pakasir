import { useState } from 'react';
import { ArrowDownToLine, Camera, CircleDollarSign, CreditCard, FileText, MessageCircle, Minus, Package, Plus, Printer, QrCode, Receipt, RefreshCw, Search, ShoppingBag, Trash2, Wallet } from 'lucide-react';
import { date, downloadFile, formatEscPosReceipt, money, number, offlineQueue, query, request, useAction, useResource } from './api';
import { BarcodeScannerModal } from './Operations';
import { ActionNotice, Badge, Button, Card, Empty, Field, Modal, Notice, Pagination, Resource, SectionTitle, Stat } from './ui';

export function ThermalReceiptModal({ receipt, settings, onClose }) {
  if (!receipt) return null;
  const formatted = formatEscPosReceipt(receipt, settings);
  const waText = encodeURIComponent(`Struk Pembelian *${settings?.store_name || 'Pakasir Vault'}*\nNo. Faktur: ${receipt.invoice_number}\nTotal: ${money(receipt.total_amount)}\nMetode: ${receipt.payment_method}\n\n\`\`\`\n${formatted}\n\`\`\``);

  return (
    <Modal title={`Struk Thermal (${settings?.paper_width || '58mm'})`} onClose={onClose}>
      <pre className="thermal-preview">{formatted}</pre>
      <div className="form-actions" style={{ flexWrap: 'wrap', gap: 10 }}>
        <Button type="button" variant="secondary" onClick={() => window.print()}>
          <Printer size={16} /> Cetak Struk Thermal (ESC/POS)
        </Button>
        <a className="button primary" href={`https://wa.me/?text=${waText}`} target="_blank" rel="noopener noreferrer">
          <MessageCircle size={16} /> Kirim Struk via WhatsApp
        </a>
        <Button type="button" variant="dark" onClick={onClose}>Transaksi Baru</Button>
      </div>
    </Modal>
  );
}

export function Cashier() {
  const products = useResource('/inventory');
  const customers = useResource('/customers');
  const outlets = useResource('/stores');
  const settings = useResource('/settings');
  const [page, setPage] = useState(1);
  const history = useResource(`/transactions?page=${page}`);
  const [cart, setCart] = useState([]);
  const [search, setSearch] = useState('');
  const [customer, setCustomer] = useState('');
  const [outlet, setOutlet] = useState('');
  const [method, setMethod] = useState('Tunai');
  const [discount, setDiscount] = useState(0);
  const [cashTendered, setCashTendered] = useState('');
  const [approvalCode, setApprovalCode] = useState('');
  const [receipt, setReceipt] = useState(null);
  const [showReceiptModal, setShowReceiptModal] = useState(false);
  const [scannerOpen, setScannerOpen] = useState(false);
  const action = useAction();

  const subtotal = cart.reduce((sum, item) => sum + Number(item.price) * item.quantity, 0);
  const taxable = Math.max(0, subtotal - Number(discount));
  const tax = settings.data?.tax_enabled ? taxable * Number(settings.data.tax_rate) / 100 : 0;
  const serviceFee = settings.data?.service_fee_enabled ? taxable * Number(settings.data.service_fee_rate) / 100 : 0;
  const grandTotal = Math.round(taxable + tax + serviceFee);
  const paidNumeric = Number(cashTendered) || grandTotal;
  const changeAmount = Math.max(0, paidNumeric - grandTotal);

  function add(product) {
    if (!product || Number(product.stock_in) <= 0) return;
    setReceipt(null);
    setCart(current => {
      const found = current.find(item => item.id === product.id);
      return found
        ? current.map(item => item.id === product.id ? { ...item, quantity: Math.min(item.quantity + 1, Number(product.stock_in)) } : item)
        : [...current, { ...product, quantity: 1 }];
    });
  }

  function quantity(id, value) {
    setCart(current => current.map(item => item.id === id ? { ...item, quantity: Math.max(1, Math.min(Number(item.stock_in), value)) } : item));
  }

  async function checkout(event) {
    event.preventDefault();
    const paymentMethod = method === 'Tunai' ? 'Cash' : method === 'Kartu debit' ? 'EDC' : method;
    const payload = {
      items: cart.map(item => ({ product_id: item.id, quantity: item.quantity })),
      customer_id: customer ? Number(customer) : null,
      store_outlet_id: Number(outlet) || 1,
      payment_method: paymentMethod,
      discount: Number(discount) || 0,
      amount_paid: paidNumeric,
      approval_code: approvalCode || undefined,
    };

    const result = await action.run(async () => {
      try {
        return await request('/transactions', { method: 'POST', body: payload });
      } catch (err) {
        if (err.isOffline || !navigator.onLine) {
          return offlineQueue.enqueue({
            ...payload,
            estimated_total: grandTotal,
            items_preview: cart.map(it => ({ product_name: it.name, quantity: it.quantity, subtotal: it.price * it.quantity })),
          });
        }
        throw err;
      }
    }, 'Transaksi berhasil dicatat. Siap cetak struk thermal.');

    if (result.ok) {
      const txData = { ...result.data, amount_paid: paidNumeric };
      setReceipt(txData);
      setShowReceiptModal(true);
      setCart([]);
      setDiscount(0);
      setCashTendered('');
      setApprovalCode('');
      products.reload();
      history.reload();
      customers.reload();
    }
  }

  return (
    <div>
      <SectionTitle eyebrow="TERMINAL KASIR POS (FAST CHECKOUT)" title="Transaksi lancar. Pelanggan senang." description="Scan barcode, pilih metode bayar, dan cetak struk Bluetooth ESC/POS.">
        <Button variant="secondary" onClick={() => setScannerOpen(true)}><Camera size={16} /> Scan Barcode</Button>
      </SectionTitle>
      <Notice>Pembayaran POS mencatat pembayaran multi-metode (Cash, QRIS Dinamis, EDC) serta mendukung Offline Mutation Queue saat koneksi terputus.</Notice>

      <div className="cashier-grid">
        <Card>
          <div className="search-field" style={{ marginBottom: 14 }}>
            <Search size={18} />
            <input aria-label="Cari produk kasir" placeholder="Cari nama atau scan SKU barcode…" value={search} onChange={event => setSearch(event.target.value)} />
            <button type="button" className="icon-button" aria-label="Scan barcode produk" onClick={() => setScannerOpen(true)}><Camera size={17} /></button>
          </div>
          <Resource resource={products}>{d => {
            const items = d.items.filter(item => `${item.name} ${item.sku}`.toLowerCase().includes(search.toLowerCase()));
            return items.length ? (
              <div className="pos-products">
                {items.map(item => (
                  <button className="pos-product" key={item.id} disabled={Number(item.stock_in) <= 0 || action.busy} onClick={() => add(item)}>
                    <span className="product-icon"><Package size={25} /></span>
                    <strong>{item.name}</strong>
                    <small>{Number(item.stock_in) <= 0 ? 'Out of Stock' : `${number(item.stock_in)} unit · ${item.sku}`}</small>
                    <span>{money(item.price)} <Plus size={16} /></span>
                  </button>
                ))}
              </div>
            ) : <Empty title="Produk tidak ditemukan" />;
          }}</Resource>
        </Card>

        <Card className="cart-card">
          <div className="card-heading">
            <h3>Keranjang Belanja</h3>
            <Badge tone="lime">{cart.reduce((s, i) => s + i.quantity, 0)} Item · {money(grandTotal)}</Badge>
          </div>
          <ActionNotice action={action} />
          {receipt && (
            <div className="receipt" style={{ cursor: 'pointer' }} onClick={() => setShowReceiptModal(true)}>
              <Receipt size={25} />
              <div>
                <strong>{receipt.invoice_number}</strong>
                <small style={{ display: 'block' }}>{date(receipt.created_at)} · Klik untuk Cetak Struk</small>
              </div>
              <span>{money(receipt.total_amount)}</span>
            </div>
          )}
          {!cart.length && !receipt && <Empty title="Keranjang masih kosong">Pilih atau scan produk untuk mulai transaksi.</Empty>}

          <form onSubmit={checkout}>
            <div className="cart-items">
              {cart.map(item => (
                <div className="cart-item" key={item.id}>
                  <div>
                    <strong>{item.name}</strong>
                    <small>{money(item.price)} / unit</small>
                  </div>
                  <button type="button" className="icon-button danger-text" aria-label={`Keluarkan ${item.name} dari keranjang`} disabled={action.busy} onClick={() => setCart(cart.filter(p => p.id !== item.id))}><Trash2 size={16} /></button>
                  <div className="quantity-control">
                    <button type="button" aria-label={`Kurangi ${item.name}`} disabled={item.quantity <= 1 || action.busy} onClick={() => quantity(item.id, item.quantity - 1)}><Minus size={14} /></button>
                    <input type="number" aria-label={`Jumlah ${item.name}`} min="1" max={item.stock_in} required value={item.quantity} disabled={action.busy} onChange={event => quantity(item.id, Number(event.target.value))} />
                    <button type="button" aria-label={`Tambah ${item.name}`} disabled={item.quantity >= item.stock_in || action.busy} onClick={() => quantity(item.id, item.quantity + 1)}><Plus size={14} /></button>
                  </div>
                  <strong>{money(item.price * item.quantity)}</strong>
                </div>
              ))}
            </div>

            <Field label="Outlet" value={outlet} required disabled={action.busy || outlets.loading} onChange={event => setOutlet(event.target.value)}>
              <option value="">Pilih outlet</option>
              {outlets.data?.outlets.filter(item => item.is_open).map(item => <option key={item.id} value={item.id}>{item.name}</option>)}
            </Field>
            <Notice error>{outlets.error}</Notice>

            <Field label="Pelanggan" value={customer} disabled={action.busy || customers.loading} onChange={event => setCustomer(event.target.value)}>
              <option value="">Walk-in Customer (Umum)</option>
              {customers.data?.customers.map(item => <option key={item.id} value={item.id}>{item.name} ({item.tier})</option>)}
            </Field>
            <Notice error>{customers.error}</Notice>

            <div className="form-grid">
              <Field label="Metode pembayaran" value={method} disabled={action.busy} onChange={event => setMethod(event.target.value)}>
                {['Tunai', 'QRIS', 'Transfer', 'Kartu debit'].map(value => <option key={value}>{value}</option>)}
              </Field>
              <Field label="Diskon (Rp)" type="number" min="0" max={subtotal} value={discount} disabled={action.busy} onChange={event => setDiscount(event.target.value)} />
            </div>

            {method === 'Tunai' && cart.length > 0 && (
              <div style={{ marginBottom: 14 }}>
                <Field label="Uang Tunai Diterima (Rp)" type="number" min="0" placeholder={String(grandTotal)} value={cashTendered} onChange={e => setCashTendered(e.target.value)} />
                <div className="filter-pills" style={{ marginBottom: 8 }}>
                  <button type="button" onClick={() => setCashTendered(String(grandTotal))}>Uang Pas</button>
                  {[50000, 100000, 200000].map(nom => (
                    <button type="button" key={nom} onClick={() => setCashTendered(String(nom))}>{money(nom)}</button>
                  ))}
                </div>
                <div className="stock-line">
                  <span>Estimasi Kembalian</span>
                  <strong>{money(changeAmount)}</strong>
                </div>
              </div>
            )}

            {method === 'QRIS' && cart.length > 0 && (
              <div className="qris-preview">
                <QrCode size={42} />
                <div>
                  <strong>QRIS Dinamis · {money(grandTotal)}</strong>
                  <small style={{ display: 'block' }}>Tunjukkan kode QR ke pelanggan untuk dipindai (GoPay/OVO/Mobile Banking)</small>
                </div>
              </div>
            )}

            {method === 'Kartu debit' && cart.length > 0 && (
              <Field label="Nomor Otorisasi / Approval Code EDC" placeholder="Contoh: APPR-882910" value={approvalCode} onChange={e => setApprovalCode(e.target.value)} />
            )}

            <Notice error>{settings.error}</Notice>
            <dl className="totals">
              <div><dt>Subtotal</dt><dd>{money(subtotal)}</dd></div>
              <div><dt>Diskon</dt><dd>−{money(discount)}</dd></div>
              <div><dt>PPN {settings.data?.tax_enabled ? `(${settings.data.tax_rate}%)` : ''}</dt><dd>{money(tax)}</dd></div>
              <div><dt>Service Fee</dt><dd>{money(serviceFee)}</dd></div>
              <div className="grand-total"><dt>Total Akhir</dt><dd>{money(grandTotal)}</dd></div>
            </dl>
            <small className="muted">Jumlah final dihitung dan divalidasi ulang oleh server.</small>
            <Button busy={action.busy} disabled={!cart.length || !outlet || settings.loading || Boolean(settings.error)} className="full-width">
              <CreditCard size={17} /> Catat Pembayaran & Cetak Struk
            </Button>
          </form>
        </Card>
      </div>

      {scannerOpen && (
        <BarcodeScannerModal
          items={products.data?.items || []}
          onClose={() => setScannerOpen(false)}
          onDetected={code => {
            const match = products.data?.items?.find(i => i.sku.toLowerCase() === code.toLowerCase() || i.name.toLowerCase().includes(code.toLowerCase()));
            if (match) add(match);
            else setSearch(code);
          }}
        />
      )}
      {showReceiptModal && receipt && (
        <ThermalReceiptModal receipt={receipt} settings={settings.data} onClose={() => setShowReceiptModal(false)} />
      )}
    </div>
  );
}

export function SalesHistory({ navigate }) {
  const [page, setPage] = useState(1);
  const [statusFilter, setStatusFilter] = useState('Semua');
  const [selectedTx, setSelectedTx] = useState(null);
  const [voidPinModal, setVoidPinModal] = useState(null);
  const [pin, setPin] = useState('');
  const history = useResource(`/transactions?page=${page}`);
  const settings = useResource('/settings');

  return (
    <div>
      <SectionTitle eyebrow="RIWAYAT TRANSAKSI & PENJUALAN (SALES)" title="Jejak setiap faktur kasir." description="Lacak faktur penjualan, cetak ulang struk thermal, atau ajukan void dengan PIN Manager.">
        <Button variant="secondary" onClick={history.reload}><RefreshCw size={16} /> Perbarui</Button>
        {navigate && <Button onClick={() => navigate('cashier')}><Plus size={17} /> Transaksi Baru</Button>}
      </SectionTitle>

      <div className="filter-pills">
        {['Semua', 'Completed', 'Processing', 'Cancelled'].map(st => (
          <button key={st} className={statusFilter === st ? 'selected' : ''} onClick={() => setStatusFilter(st)}>{st}</button>
        ))}
      </div>

      <Resource resource={history}>{d => {
        const rows = (d.data || []).filter(tx => {
          if (statusFilter === 'Semua') return true;
          if (statusFilter === 'Completed') return tx.payment_status === 'paid';
          if (statusFilter === 'Processing') return tx.payment_status === 'pending';
          return tx.payment_status === 'cancelled';
        });
        const grossRevenue = rows.reduce((s, tx) => s + Number(tx.total_amount || 0), 0);
        const aov = rows.length ? Math.round(grossRevenue / rows.length) : 0;

        return (
          <div>
            <div className="stats-grid three">
              <Stat label="Omzet Kotor (Halaman Ini)" value={money(grossRevenue)} icon={CircleDollarSign} tone="lime" />
              <Stat label="Transaksi Sukses" value={number(rows.length)} icon={FileText} />
              <Stat label="Average Order Value (AOV)" value={money(aov)} icon={ShoppingBag} tone="dark" />
            </div>

            <Card>
              {rows.length ? (
                <div className="table-scroll">
                  <table>
                    <thead>
                      <tr>
                        <th>No. Faktur</th>
                        <th>Waktu</th>
                        <th>Pelanggan</th>
                        <th>Metode Bayar</th>
                        <th>Total</th>
                        <th>Aksi</th>
                      </tr>
                    </thead>
                    <tbody>
                      {rows.map(item => (
                        <tr key={item.id}>
                          <td><strong>{item.invoice_number}</strong></td>
                          <td>{date(item.created_at)}</td>
                          <td>{item.customer?.name || 'Walk-in Customer'}</td>
                          <td><Badge>{item.payment_method}</Badge></td>
                          <td><strong>{money(item.total_amount)}</strong></td>
                          <td>
                            <div style={{ display: 'flex', gap: 6 }}>
                              <Button variant="secondary" onClick={() => setSelectedTx(item)}><Printer size={14} /> Struk</Button>
                              <Button variant="secondary" onClick={() => setVoidPinModal(item)}>Void</Button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              ) : <Empty title="Belum ada transaksi untuk filter ini" />}
              <Pagination page={page} lastPage={d.last_page} onChange={setPage} />
            </Card>
          </div>
        );
      }}</Resource>

      {selectedTx && (
        <ThermalReceiptModal receipt={selectedTx} settings={settings.data} onClose={() => setSelectedTx(null)} />
      )}
      {voidPinModal && (
        <Modal title={`Otorisasi Refund / Void · ${voidPinModal.invoice_number}`} onClose={() => { setVoidPinModal(null); setPin(''); }}>
          <p>Masukkan PIN Supervisor / Manager untuk membatalkan faktur senilai <strong>{money(voidPinModal.total_amount)}</strong>.</p>
          <Field label="PIN Otorisasi Supervisor" type="password" placeholder="Masukkan 6 digit PIN (contoh: 123456)" value={pin} onChange={e => setPin(e.target.value)} />
          <div className="form-actions">
            <Button type="button" variant="secondary" onClick={() => { setVoidPinModal(null); setPin(''); }}>Batal</Button>
            <Button type="button" variant="danger" disabled={pin.length < 4} onClick={() => { setVoidPinModal(null); setPin(''); }}>Konfirmasi Void</Button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export function Payments() {
  const [channels, setChannels] = useState([
    { id: 'qris', name: 'E-Wallet & QRIS Dinamis (GoPay, OVO, ShopeePay)', mdr: '0.7%', payout: 'H+1 Otomatis', enabled: true },
    { id: 'va', name: 'Virtual Account Bank (BCA, Mandiri, BRI)', mdr: 'Rp 4.000 / tx', payout: 'Real-time / H+1', enabled: true },
    { id: 'card', name: 'Kartu Debit / Kredit EDC (Visa / Mastercard)', mdr: '1.5% - 2.2%', payout: 'H+2 Settlement', enabled: true },
    { id: 'cash', name: 'Uang Tunai (Cash Laci Kasir)', mdr: '0% (Tanpa MDR)', payout: 'Langsung di Laci Kasir', enabled: true },
  ]);
  const [openingCash, setOpeningCash] = useState(500000);
  const [recordedCashSales, setRecordedCashSales] = useState(2450000);
  const [physicalCash, setPhysicalCash] = useState(2950000);
  const expectedCash = Number(openingCash || 0) + Number(recordedCashSales || 0);
  const variance = Number(physicalCash || 0) - expectedCash;

  return (
    <div>
      <SectionTitle eyebrow="KANAL PEMBAYARAN & REKONSILIASI KAS" title="Kontrol gateway & laci kasir." description="Atur metode pembayaran yang diterima di kasir dan rekonsiliasi fisik uang kas akhir shift." />
      <div className="two-column">
        <Card>
          <SectionTitle title="Kanal Pembayaran Kasir" description="Aktifkan/nonaktifkan metode pembayaran pada terminal POS." />
          <div className="security-controls">
            {channels.map(ch => (
              <label className="security-row" key={ch.id}>
                <span>
                  <Wallet size={20} />
                  <div>
                    <strong>{ch.name}</strong>
                    <small style={{ display: 'block', color: '#6B7280' }}>MDR: {ch.mdr} · Pencairan: {ch.payout}</small>
                  </div>
                </span>
                <input
                  type="checkbox"
                  role="switch"
                  checked={ch.enabled}
                  onChange={e => setChannels(channels.map(item => item.id === ch.id ? { ...item, enabled: e.target.checked } : item))}
                />
              </label>
            ))}
          </div>
        </Card>

        <Card>
          <SectionTitle title="Buka & Tutup Kasir (End of Day Reconciliation)" description="Hitung selisih kas fisik di laci kasir (over/short balance)." />
          <Field label="Modal Kas Awal Shift (Rp)" type="number" value={openingCash} onChange={e => setOpeningCash(e.target.value)} />
          <Field label="Penjualan Tunai Tercatat Sistem (Rp)" type="number" value={recordedCashSales} onChange={e => setRecordedCashSales(e.target.value)} />
          <Field label="Hitungan Fisik Uang di Laci Kasir Saat Tutup Shift (Rp)" type="number" value={physicalCash} onChange={e => setPhysicalCash(e.target.value)} />
          <dl className="totals">
            <div><dt>Total Kas Seharusnya di Laci</dt><dd>{money(expectedCash)}</dd></div>
            <div><dt>Hitungan Fisik Aktual</dt><dd>{money(physicalCash)}</dd></div>
            <div className="grand-total">
              <dt>Selisih Kas (Over / Short)</dt>
              <dd style={{ color: variance === 0 ? '#1E9E4F' : '#D83A3A' }}>
                {variance === 0 ? 'BALANCE (Rp 0)' : `${variance > 0 ? '+' : ''}${money(variance)}`}
              </dd>
            </div>
          </dl>
        </Card>
      </div>
    </div>
  );
}

export function Reports() {
  const [period, setPeriod] = useState('Bulan Ini');
  const resource = useResource(`/reports?${query({ period })}`);
  const action = useAction();

  return (
    <div>
      <SectionTitle eyebrow="LAPORAN FINANSIAL & ARUS KAS" title="Angka yang bercerita." description="Evaluasi Laba Rugi (P&L), HPP, Kas di Tangan, dan Distribusi Alokasi Dana.">
        <Button variant="dark" busy={action.busy} onClick={() => action.run(() => downloadFile(`/reports/export?${query({ period, type: 'csv' })}`, `pakasir-laporan-${period.replaceAll(' ', '-').toLowerCase()}.csv`), 'Laporan CSV telah diunduh.')}>
          <ArrowDownToLine size={17} /> Unduh CSV
        </Button>
      </SectionTitle>
      <div className="filter-pills">
        {['Hari Ini', 'Minggu Ini', 'Bulan Ini', 'Tahun Ini'].map(value => (
          <button className={period === value ? 'selected' : ''} key={value} onClick={() => setPeriod(value)}>{value}</button>
        ))}
      </div>
      <ActionNotice action={action} />
      <Resource resource={resource}>{d => {
        const gross = Number(d.summary.gross_profit || 0);
        return (
          <div>
            <Notice>{d.note || 'Laporan menggunakan data yang tersedia pada backend. Laba kotor tidak sama dengan laba bersih.'}</Notice>
            <div className="stats-grid three">
              <Stat label="Omzet Bruto (Revenue)" value={money(d.summary.total_revenue)} detail="Di luar pajak PPN" icon={CircleDollarSign} tone="lime" />
              <Stat label="HPP / COGS" value={money(d.summary.total_hpp)} detail="Harga modal historis barang terjual" icon={Package} />
              <Stat label="Laba Kotor (Gross Profit)" value={money(d.summary.gross_profit)} detail="Sebelum biaya operasional" icon={ShoppingBag} tone="dark" />
            </div>
            <div className="two-column">
              <Card>
                <SectionTitle title="Ringkasan Keuangan (P&L)" description={d.period} />
                <dl className="details financial">
                  <div><dt>Omzet Bruto (Revenue)</dt><dd>{money(d.summary.total_revenue)}</dd></div>
                  <div><dt>HPP (COGS)</dt><dd>−{money(d.summary.total_hpp)}</dd></div>
                  <div className="emphasis"><dt>Laba Kotor</dt><dd>{money(d.summary.gross_profit)}</dd></div>
                  <div><dt>Beban Operasional (Opex)</dt><dd>{d.summary.operational_cost == null ? 'Belum dicatat' : money(d.summary.operational_cost)}</dd></div>
                  <div><dt>Laba Bersih Riil</dt><dd>{d.summary.net_profit == null ? 'Belum dapat dihitung' : money(d.summary.net_profit)}</dd></div>
                  {d.summary.tax_collected != null && <div><dt>Pajak PPN Terkumpul</dt><dd>{money(d.summary.tax_collected)}</dd></div>}
                  {d.summary.payments_received != null && <div><dt>Kas di Tangan (Cash on Hand)</dt><dd>{money(d.summary.payments_received)}</dd></div>}
                </dl>
              </Card>

              <Card>
                <SectionTitle title="Distribusi Alokasi Dana & Metode Bayar" description="Rekomendasi alokasi kas bisnis dan komposisi kanal pembayaran." />
                <div style={{ marginBottom: 18 }}>
                  {[
                    { label: 'Anggaran Restock Inventaris (35%)', pct: 0.35 },
                    { label: 'Biaya Operasional Toko (25%)', pct: 0.25 },
                    { label: 'Dana Cadangan Darurat (15%)', pct: 0.15 },
                    { label: 'Laba Dibagi / Prive (25%)', pct: 0.25 },
                  ].map(alloc => (
                    <div className="payment-method" key={alloc.label}>
                      <div><strong>{alloc.label}</strong><span>{money(Math.round(gross * alloc.pct))}</span></div>
                      <progress max="1" value={alloc.pct} aria-label={alloc.label} />
                    </div>
                  ))}
                </div>
                {d.payment_methods?.length ? d.payment_methods.map(item => (
                  <div className="payment-method" key={item.method}>
                    <div><strong>{item.method}</strong><span>{item.share}</span></div>
                    <progress max="1" value={item.value} aria-label={item.method} />
                    {item.amount != null && <small>{money(item.amount)}</small>}
                  </div>
                )) : <Empty title="Belum ada pembayaran" />}
              </Card>
            </div>
          </div>
        );
      }}</Resource>
    </div>
  );
}
