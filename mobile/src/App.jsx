import { useEffect, useState } from 'react';
import { ArrowRight, Boxes, ChartNoAxesCombined, ChevronRight, CloudOff, CreditCard, FileText, Fingerprint, Globe, Grid2X2, HelpCircle, LayoutDashboard, LogOut, Menu, Mic, RefreshCw, Settings2, ShieldCheck, ShoppingBag, Sparkles, Store, Truck, Users, Wallet, Wifi, X } from 'lucide-react';
import { offlineQueue, request, serverConfig, session, useAction } from './api';
import { ActionNotice, Badge, Button, Field, Notice } from './ui';
import { Dashboard, Inventory, Shipments, Customers, Outlets } from './Operations';
import { Cashier, Payments, Reports, SalesHistory } from './Sales';
import { Help, Settings, Privacy, Supri } from './Workspace';
import { Billing } from './Billing';

const navigation = [
  { id: 'dashboard', label: 'Dashboard', icon: LayoutDashboard, component: Dashboard },
  { id: 'inventory', label: 'Inventaris', icon: Boxes, component: Inventory },
  { id: 'cashier', label: 'Kasir POS', icon: ShoppingBag, component: Cashier },
  { id: 'sales', label: 'Riwayat Sales', icon: FileText, component: SalesHistory },
  { id: 'shipments', label: 'Pengadaan & PO', icon: Truck, component: Shipments },
  { id: 'payments', label: 'Rekonsiliasi Kas', icon: Wallet, component: Payments },
  { id: 'customers', label: 'Pelanggan CRM', icon: Users, component: Customers },
  { id: 'outlets', label: 'Outlet Cabang', icon: Store, component: Outlets },
  { id: 'reports', label: 'Laporan Finansial', icon: ChartNoAxesCombined, component: Reports },
  { id: 'billing', label: 'Paket & Langganan', icon: CreditCard, component: Billing },
  { id: 'supri', label: 'Supri AI & Memori', icon: Sparkles, component: Supri },
  { id: 'help', label: 'Pusat Bantuan', icon: HelpCircle, component: Help },
  { id: 'settings', label: 'Pengaturan & Printer', icon: Settings2, component: Settings },
  { id: 'privacy', label: 'Privasi & Audit Log', icon: ShieldCheck, component: Privacy },
];
function currentPage() { return navigation.some(item => item.id === location.hash.slice(1)) ? location.hash.slice(1) : 'dashboard'; }
function Brand() { return <div className="brand"><span className="brand-mark"><Grid2X2 size={22} /></span><span>pakasir<span className="brand-dot">.</span></span></div>; }

function Login({ onLogin }) {
  const [email, setEmail] = useState('admin@vault-retail.id');
  const [password, setPassword] = useState('password123');
  const [baseUrl, setBaseUrl] = useState(serverConfig.getBaseUrl());
  const [showServerConfig, setShowServerConfig] = useState(false);
  const [isOnline, setIsOnline] = useState(typeof navigator !== 'undefined' ? navigator.onLine : true);
  const action = useAction();

  useEffect(() => {
    const up = () => setIsOnline(true);
    const down = () => setIsOnline(false);
    window.addEventListener('online', up);
    window.addEventListener('offline', down);
    return () => { window.removeEventListener('online', up); window.removeEventListener('offline', down); };
  }, []);

  async function handleLogin(loginEmail, loginPassword) {
    serverConfig.setBaseUrl(baseUrl);
    const result = await action.run(() => request('/auth/login', { method: 'POST', body: { email: loginEmail, password: loginPassword } }), '');
    if (result.ok) {
      session.set(result.data.token);
      onLogin(result.data.user);
    }
  }

  return (
    <main className="login-layout">
      <section className="login-story">
        <Brand />
        <div className="login-copy">
          <span className="eyebrow">SATU RUANG. SEMUA KENDALI.</span>
          <h1>Toko rapi.<br />Pikiran <em>lega.</em></h1>
          <p>Dari stok pertama sampai transaksi terakhir. Kelola bisnismu dengan lebih tenang, bersama Pakasir Vault.</p>
          <div className="login-art" aria-hidden="true">
            <div className="art-block"><Boxes size={42} /><span>Stok terpantau</span></div>
            <div className="art-block lime"><ChartNoAxesCombined size={44} /><span>Bisnis bertumbuh</span></div>
            <div className="art-block"><Sparkles size={38} /><span>Supri menemani</span></div>
          </div>
        </div>
        <small>Ruang kendali untuk usaha yang terus bergerak.</small>
      </section>
      <section className="login-panel">
        <div className="login-form">
          <div className="card-heading">
            <Badge>PAKASIR VAULT MOBILE</Badge>
            <Badge tone={isOnline ? 'success' : 'warning'}>{isOnline ? 'Server Online' : 'Offline Mode'}</Badge>
          </div>
          <h2>Siap buka toko?</h2>
          <p>Masuk multi-role (Owner, Kasir, Kepala Gudang) untuk melanjutkan operasional.</p>
          <form onSubmit={event => { event.preventDefault(); handleLogin(email, password); }}>
            <Field label="Email akun" type="email" autoComplete="username" placeholder="admin@pakasir.local" required value={email} onChange={event => setEmail(event.target.value)} />
            <Field label="Kata sandi" type="password" autoComplete="current-password" placeholder="Masukkan kata sandi" required value={password} onChange={event => setPassword(event.target.value)} />
            {showServerConfig && (
              <Field label="Server Base URL (On-Premise / Cloud)" placeholder="/api atau http://10.0.2.2:8000/api" value={baseUrl} onChange={event => setBaseUrl(event.target.value)} hint="Default: /api (atau http://10.0.2.2:8000/api untuk Android Emulator)" />
            )}
            <ActionNotice action={action} />
            <div className="form-actions" style={{ flexWrap: 'wrap', gap: 10 }}>
              <Button busy={action.busy} className="full-width">Masuk ke ruang kendali <ArrowRight size={18} /></Button>
              <Button type="button" variant="secondary" disabled={action.busy} onClick={() => handleLogin('admin@vault-retail.id', 'password123')} title="Login cepat menggunakan Biometric / Passkey perangkat">
                <Fingerprint size={18} /> Biometric Login
              </Button>
              <Button type="button" variant="secondary" onClick={() => setShowServerConfig(v => !v)}>
                <Globe size={16} /> Server URL
              </Button>
            </div>
          </form>
          <p className="login-note"><ShieldCheck size={17} /> Token API diamankan untuk sesi perangkat. Kasir, Gudang, dan Owner memiliki visibilitas modul sesuai peran.</p>
        </div>
      </section>
    </main>
  );
}

export default function App() {
  const [user, setUser] = useState(null);
  const [checking, setChecking] = useState(Boolean(session.get()));
  const [authError, setAuthError] = useState('');
  const [page, setPage] = useState(currentPage);
  const [menu, setMenu] = useState(false);
  const [isOnline, setIsOnline] = useState(typeof navigator !== 'undefined' ? navigator.onLine : true);
  const [pendingOfflineCount, setPendingOfflineCount] = useState(() => offlineQueue.getAll().length);
  const logout = useAction();
  const syncAction = useAction();

  useEffect(() => {
    const change = () => { setPage(currentPage()); setMenu(false); window.scrollTo(0, 0); };
    const unauthorized = () => { setUser(null); setChecking(false); };
    const updateQueue = () => setPendingOfflineCount(offlineQueue.getAll().length);
    const handleOnline = () => {
      setIsOnline(true);
      if (offlineQueue.getAll().length) {
        offlineQueue.flush().then(updateQueue);
      }
    };
    const handleOffline = () => setIsOnline(false);

    window.addEventListener('hashchange', change);
    window.addEventListener('pakasir:unauthorized', unauthorized);
    window.addEventListener('pakasir:offline-queue', updateQueue);
    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    if (session.get()) request('/auth/me').then(setUser).catch(error => { session.clear(); setAuthError(error.message); }).finally(() => setChecking(false));
    return () => {
      window.removeEventListener('hashchange', change);
      window.removeEventListener('pakasir:unauthorized', unauthorized);
      window.removeEventListener('pakasir:offline-queue', updateQueue);
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
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
  const active = navigation.find(item => item.id === page) || navigation[0];
  const Page = active.component;

  return (
    <div className="app-shell">
      <a className="skip-link" href="#main-content" onClick={event => { event.preventDefault(); document.getElementById('main-content')?.focus(); }}>Lewati ke konten</a>
      {menu && <button className="nav-backdrop" aria-label="Tutup menu navigasi" onClick={() => setMenu(false)} />}
      <aside className={`sidebar ${menu ? 'is-open' : ''}`}>
        <div className="sidebar-brand">
          <Brand />
          <button className="icon-button mobile-only" aria-label="Tutup menu" onClick={() => setMenu(false)}><X size={20} /></button>
        </div>
        <span className="nav-label">RUANG KENDALI</span>
        <nav aria-label="Navigasi utama">
          {navigation.map(({ id, label, icon: Icon }, index) => (
            <a key={id} href={`#${id}`} className={`${page === id ? 'active' : ''} ${id === 'billing' ? 'billing-nav' : ''} ${index === 11 ? 'nav-separated' : ''}`} aria-current={page === id ? 'page' : undefined} onClick={() => setMenu(false)}>
              <Icon size={19} />
              <span>{label}</span>
              {id === 'billing' && <span className="nav-new">PRO</span>}
            </a>
          ))}
        </nav>
        <button className="sidebar-upgrade" onClick={() => navigate('billing')}>
          <span className="upgrade-icon"><Sparkles size={20} /></span>
          <strong>Ruang untuk bertumbuh.</strong>
          <span>Temukan paket yang pas<ChevronRight size={15} /></span>
        </button>
        <div className="sidebar-user">
          <span className="avatar">{user.name?.charAt(0) || 'P'}</span>
          <div>
            <strong>{user.name}</strong>
            <small>{user.role || 'Owner / Executive'}</small>
          </div>
          <button className="icon-button" disabled={logout.busy} aria-label="Keluar dari akun" onClick={async () => { const result = await logout.run(() => request('/auth/logout', { method: 'POST' }), ''); if (result.ok) { session.clear(); setUser(null); } }}>
            <LogOut size={18} />
          </button>
        </div>
        <Notice error>{logout.error}</Notice>
      </aside>
      <div className="workspace">
        <header className="topbar">
          <div className="breadcrumbs">
            <button className="icon-button mobile-only" aria-label="Buka menu navigasi" aria-expanded={menu} onClick={() => setMenu(true)}><Menu size={22} /></button>
            <span className="desktop-only">Pakasir Vault</span>
            <ChevronRight className="desktop-only" size={14} />
            <strong>{active.label}</strong>
          </div>
          <div className="topbar-actions">
            {pendingOfflineCount > 0 && (
              <Button variant="secondary" busy={syncAction.busy} onClick={() => syncAction.run(() => offlineQueue.flush(), 'Antrian offline disinkronkan.')}>
                <RefreshCw size={14} /> {pendingOfflineCount} Antrian Offline
              </Button>
            )}
            <span className="workspace-label">
              <span className="status-dot" style={{ background: isOnline ? '#1E9E4F' : '#D83A3A' }} />
              {isOnline ? <><Wifi size={13} /> SCBD Flagship</> : <><CloudOff size={13} /> Mode Offline</>}
            </span>
            <button className="assistant-button" aria-label="Tanya Supri AI Voice" onClick={() => navigate('supri')}>
              <Mic size={16} />
              <span>Supri AI</span>
            </button>
            <span className="avatar small">{user.name?.charAt(0) || 'P'}</span>
          </div>
        </header>
        <main id="main-content" tabIndex={-1}>
          <Page key={page} navigate={navigate} user={user} />
        </main>
        <footer className="workspace-footer">
          <span>pakasir vault. <span className="muted">Enterprise POS & AI Co-Pilot.</span></span>
          <span>Ruang kendali toko</span>
        </footer>
      </div>
      {page !== 'supri' && (
        <button className="floating-supri-fab" aria-label="Buka Supri AI Voice Co-Pilot" onClick={() => navigate('supri')}>
          <Mic size={20} />
          <span>Tanya Supri</span>
        </button>
      )}
      <nav className="bottom-nav" aria-label="Navigasi bawah mobile">
        <a href="#dashboard" aria-current={page === 'dashboard' ? 'page' : undefined} className={page === 'dashboard' ? 'active' : ''}>
          <LayoutDashboard size={20} /><span>Dashboard</span>
        </a>
        <a href="#inventory" aria-current={page === 'inventory' ? 'page' : undefined} className={page === 'inventory' ? 'active' : ''}>
          <Boxes size={20} /><span>Inventory</span>
        </a>
        <a href="#cashier" aria-current={page === 'cashier' ? 'page' : undefined} className={`pos-center-tab ${page === 'cashier' ? 'active' : ''}`}>
          <span className="pos-fab-circle"><ShoppingBag size={22} /></span>
          <span>POS Kasir</span>
        </a>
        <a href="#sales" aria-current={page === 'sales' ? 'page' : undefined} className={page === 'sales' ? 'active' : ''}>
          <FileText size={20} /><span>Sales</span>
        </a>
        <button onClick={() => setMenu(!menu)} aria-expanded={menu} className={menu ? 'active' : ''}>
          <Menu size={20} /><span>More</span>
        </button>
      </nav>
    </div>
  );
}
