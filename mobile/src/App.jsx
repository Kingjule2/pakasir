import { useEffect, useState } from 'react';
import { ArrowRight, Boxes, ChartNoAxesCombined, ChevronRight, CreditCard, Grid2X2, HelpCircle, LayoutDashboard, LogOut, Menu, Settings2, ShieldCheck, ShoppingBag, Sparkles, Store, Truck, Users, X } from 'lucide-react';
import { request, session, useAction } from './api';
import { ActionNotice, Badge, Button, Field, Notice } from './ui';
import { Dashboard, Inventory, Shipments, Customers, Outlets } from './Operations';
import { Cashier, Reports } from './Sales';
import { Help, Settings, Privacy, Supri } from './Workspace';
import { Billing } from './Billing';

const navigation = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, component: Dashboard },
  { id: 'inventory', label: 'Inventaris', icon: Boxes, component: Inventory },
  { id: 'cashier', label: 'Kasir POS', icon: ShoppingBag, component: Cashier },
  { id: 'shipments', label: 'Barang masuk', icon: Truck, component: Shipments },
  { id: 'customers', label: 'Pelanggan', icon: Users, component: Customers },
  { id: 'outlets', label: 'Outlet toko', icon: Store, component: Outlets },
  { id: 'reports', label: 'Laporan', icon: ChartNoAxesCombined, component: Reports },
  { id: 'billing', label: 'Paket & pembayaran', icon: CreditCard, component: Billing },
  { id: 'supri', label: 'Supri AI', icon: Sparkles, component: Supri },
  { id: 'help', label: 'Pusat bantuan', icon: HelpCircle, component: Help },
  { id: 'settings', label: 'Pengaturan', icon: Settings2, component: Settings },
  { id: 'privacy', label: 'Privasi & audit', icon: ShieldCheck, component: Privacy },
];
function currentPage() { return navigation.some(item => item.id === location.hash.slice(1)) ? location.hash.slice(1) : 'dashboard'; }
function Brand() { return <div className="brand"><span className="brand-mark"><Grid2X2 size={22} /></span><span>pakasir<span className="brand-dot">.</span></span></div>; }
function Login({ onLogin }) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const action = useAction();
  return <main className="login-layout"><section className="login-story"><Brand /><div className="login-copy"><span className="eyebrow">SATU RUANG. SEMUA KENDALI.</span><h1>Toko rapi.<br />Pikiran <em>lega.</em></h1><p>Dari stok pertama sampai transaksi terakhir. Kelola bisnismu dengan lebih tenang, bersama Pakasir.</p><div className="login-art" aria-hidden="true"><div className="art-block"><Boxes size={42} /><span>Stok terpantau</span></div><div className="art-block lime"><ChartNoAxesCombined size={44} /><span>Bisnis bertumbuh</span></div><div className="art-block"><Sparkles size={38} /><span>Supri menemani</span></div></div></div><small>Ruang kendali untuk usaha yang terus bergerak.</small></section><section className="login-panel"><div className="login-form"><Badge>SELAMAT DATANG KEMBALI</Badge><h2>Siap buka toko?</h2><p>Masuk ke akunmu untuk melanjutkan aktivitas.</p><form onSubmit={async event => { event.preventDefault(); const result = await action.run(() => request('/auth/login', { method: 'POST', body: { email, password } }), ''); if (result.ok) { session.set(result.data.token); onLogin(result.data.user); } }}><Field label="Email akun" type="email" autoComplete="username" placeholder="nama@tokomu.id" required value={email} onChange={event => setEmail(event.target.value)} /><Field label="Kata sandi" type="password" autoComplete="current-password" placeholder="Masukkan kata sandi" required value={password} onChange={event => setPassword(event.target.value)} /><ActionNotice action={action} /><Button busy={action.busy}>Masuk ke ruang kendali <ArrowRight size={18} /></Button></form><p className="login-note"><ShieldCheck size={17} /> Gunakan akun yang diberikan pengelola toko. Token sesi hanya disimpan pada tab browser ini.</p></div></section></main>;
}
export default function App() {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(Boolean(session.get()));
  const [authError, setAuthError] = useState('');
  const [page, setPage] = useState(currentPage);
  const [menu, setMenu] = useState(false);
  const logout = useAction();
  useEffect(() => {
    const change = () => { setPage(currentPage()); setMenu(false); window.scrollTo(0, 0); };
    const unauthorized = () => { setUser(null); setChecking(false); };
    window.addEventListener('hashchange', change);
    window.addEventListener('pakasir:unauthorized', unauthorized);
    if (session.get()) request('/auth/me').then(setUser).catch(error => { session.clear(); setAuthError(error.message); }).finally(() => setChecking(false));
    return () => { window.removeEventListener('hashchange', change); window.removeEventListener('pakasir:unauthorized', unauthorized); };
  }, []);
  useEffect(() => {
    if (!menu) return;
    const close = event => { if (event.key === 'Escape') setMenu(false); };
    window.addEventListener('keydown', close);
    return () => window.removeEventListener('keydown', close);
  }, [menu]);
  const navigate = id => { location.hash = id; setMenu(false); };
  if (checking) return <div className="session-loading"><Brand /><p role="status">Menghubungkan ruang kendali…</p></div>;
  if (!user) return <><Notice error>{authError}</Notice><Login onLogin={value => { setUser(value); setAuthError(''); }} /></>;
  const active = navigation.find(item => item.id === page);
  const Page = active.component;
  return <div className="app-shell"><a className="skip-link" href="#main-content" onClick={event => { event.preventDefault(); document.getElementById('main-content')?.focus(); }}>Lewati ke konten</a>{menu && <button className="nav-backdrop" aria-label="Tutup menu navigasi" onClick={() => setMenu(false)} />}<aside className={`sidebar ${menu ? 'is-open' : ''}`}><div className="sidebar-brand"><Brand /><button className="icon-button mobile-only" aria-label="Tutup menu" onClick={() => setMenu(false)}><X size={20} /></button></div><span className="nav-label">RUANG KENDALI</span><nav aria-label="Navigasi utama">{navigation.map(({ id, label, icon: Icon }, index) => <a key={id} href={`#${id}`} className={`${page === id ? 'active' : ''} ${id === 'billing' ? 'billing-nav' : ''} ${index === 9 ? 'nav-separated' : ''}`} aria-current={page === id ? 'page' : undefined} onClick={() => setMenu(false)}><Icon size={19} /><span>{label}</span>{id === 'billing' && <span className="nav-new">NEW</span>}</a>)}</nav><button className="sidebar-upgrade" onClick={() => navigate('billing')}><span className="upgrade-icon"><Sparkles size={20} /></span><strong>Ruang untuk bertumbuh.</strong><span>Temukan paket yang pas<ChevronRight size={15} /></span></button><div className="sidebar-user"><span className="avatar">{user.name?.charAt(0) || 'P'}</span><div><strong>{user.name}</strong><small>{user.role || 'Pengelola toko'}</small></div><button className="icon-button" disabled={logout.busy} aria-label="Keluar dari akun" onClick={async () => { const result = await logout.run(() => request('/auth/logout', { method: 'POST' }), ''); if (result.ok) { session.clear(); setUser(null); } }}><LogOut size={18} /></button></div><Notice error>{logout.error}</Notice></aside><div className="workspace"><header className="topbar"><div className="breadcrumbs"><button className="icon-button mobile-only" aria-label="Buka menu navigasi" aria-expanded={menu} onClick={() => setMenu(true)}><Menu size={22} /></button><span className="desktop-only">Workspace</span><ChevronRight className="desktop-only" size={14} /><strong>{active.label}</strong></div><div className="topbar-actions"><span className="workspace-label"><span className="status-dot" /> Toko utama</span><button className="assistant-button" aria-label="Tanya Supri" onClick={() => navigate('supri')}><Sparkles size={17} /><span>Tanya Supri</span></button><span className="avatar small">{user.name?.charAt(0) || 'P'}</span></div></header><main id="main-content" tabIndex={-1}><Page key={page} navigate={navigate} user={user} /></main><footer className="workspace-footer"><span>pakasir. <span className="muted">Bekerja lebih tenang.</span></span><span>Ruang kendali toko</span></footer></div><nav className="bottom-nav" aria-label="Navigasi cepat">{['dashboard', 'inventory', 'cashier', 'billing'].map(id => { const item = navigation.find(nav => nav.id === id); const Icon = item.icon; return <a key={id} href={`#${id}`} aria-current={page === id ? 'page' : undefined} className={page === id ? 'active' : ''}><Icon size={21} /><span>{id === 'billing' ? 'Paket' : id === 'cashier' ? 'Kasir' : item.label}</span></a>; })}<button onClick={() => setMenu(!menu)} aria-expanded={menu}><Menu size={21} /><span>Lainnya</span></button></nav></div>;
}
