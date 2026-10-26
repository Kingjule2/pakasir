import { useCallback, useEffect, useState } from 'react';

const TOKEN_KEY = 'pakasir.session';
const BASE_URL_KEY = 'pakasir.baseUrl';
const OFFLINE_QUEUE_KEY = 'pakasir.offlineQueue';

export const session = {
  get: () => sessionStorage.getItem(TOKEN_KEY) || localStorage.getItem(TOKEN_KEY),
  set: (token) => { sessionStorage.setItem(TOKEN_KEY, token); localStorage.setItem(TOKEN_KEY, token); },
  clear: () => { sessionStorage.removeItem(TOKEN_KEY); localStorage.removeItem(TOKEN_KEY); },
};

export const serverConfig = {
  getBaseUrl: () => localStorage.getItem(BASE_URL_KEY) || '/api',
  setBaseUrl: (url) => {
    const clean = (url || '/api').trim().replace(/\/+$/, '');
    localStorage.setItem(BASE_URL_KEY, clean || '/api');
  },
};

export const offlineQueue = {
  getAll: () => {
    try { return JSON.parse(localStorage.getItem(OFFLINE_QUEUE_KEY) || '[]'); } catch { return []; }
  },
  enqueue: (txPayload) => {
    const current = offlineQueue.getAll();
    const entry = {
      id: `OFFLINE-${Date.now()}`,
      invoice_number: `INV-OFFLINE-${String(current.length + 1).padStart(4, '0')}`,
      created_at: new Date().toISOString(),
      sync_status: 'pending',
      payload: txPayload,
      total_amount: txPayload.estimated_total || 0,
      payment_method: txPayload.payment_method || 'Cash',
      items: txPayload.items_preview || [],
    };
    current.push(entry);
    localStorage.setItem(OFFLINE_QUEUE_KEY, JSON.stringify(current));
    window.dispatchEvent(new Event('pakasir:offline-queue'));
    return entry;
  },
  clear: () => {
    localStorage.removeItem(OFFLINE_QUEUE_KEY);
    window.dispatchEvent(new Event('pakasir:offline-queue'));
  },
  flush: async () => {
    const queue = offlineQueue.getAll();
    if (!queue.length) return { synced: 0, remaining: 0 };
    const remaining = [];
    let synced = 0;
    for (const item of queue) {
      try {
        await request('/transactions', { method: 'POST', body: item.payload });
        synced += 1;
      } catch {
        remaining.push(item);
      }
    }
    localStorage.setItem(OFFLINE_QUEUE_KEY, JSON.stringify(remaining));
    window.dispatchEvent(new Event('pakasir:offline-queue'));
    return { synced, remaining: remaining.length };
  },
};

export async function request(path, { method = 'GET', body, signal, download = false } = {}) {
  let response;
  const token = session.get();
  const baseUrl = serverConfig.getBaseUrl();
  try {
    response = await fetch(`${baseUrl}${path}`, {
      method, signal,
      headers: {
        Accept: download ? '*/*' : 'application/json',
        ...(body ? { 'Content-Type': 'application/json' } : {}),
        ...(token ? { Authorization: `Bearer ${token}`, 'X-API-TOKEN': token } : {}),
      },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  } catch (error) {
    if (error.name === 'AbortError') throw error;
    const offlineErr = new Error('Server tidak dapat dihubungi. Periksa koneksi dan pastikan layanan API aktif.');
    offlineErr.isOffline = true;
    throw offlineErr;
  }
  if (response.status === 401 && !path.startsWith('/auth/login')) {
    session.clear();
    window.dispatchEvent(new Event('pakasir:unauthorized'));
  }
  if (download && response.ok) return response.blob();
  const payload = await response.json().catch(() => null);
  if (!response.ok || payload?.success === false || !payload) {
    const details = payload?.errors ? Object.values(payload.errors).flat().join(' ') : '';
    const error = new Error(details || payload?.message || `Permintaan gagal (${response.status}). Silakan coba lagi.`);
    error.status = response.status;
    throw error;
  }
  return payload.data ?? payload;
}

export function useResource(path) {
  const [state, setState] = useState({ data: null, loading: true, error: '' });
  const [version, setVersion] = useState(0);
  const reload = useCallback(() => setVersion(v => v + 1), []);
  useEffect(() => {
    const controller = new AbortController();
    setState({ data: null, loading: true, error: '' });
    request(path, { signal: controller.signal }).then(data => {
      if (!controller.signal.aborted) setState({ data, loading: false, error: '' });
    }).catch(error => {
      if (!controller.signal.aborted) setState({ data: null, loading: false, error: error.message });
    });
    return () => controller.abort();
  }, [path, version]);
  return { ...state, reload };
}

export function useAction() {
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  async function run(callback, message = 'Perubahan berhasil disimpan.') {
    setBusy(true); setError(''); setSuccess('');
    try {
      const result = await callback();
      setSuccess(message);
      return { ok: true, data: result };
    } catch (err) {
      setError(err.message);
      return { ok: false };
    } finally { setBusy(false); }
  }
  return { busy, error, success, run };
}

export async function downloadFile(path, filename, method = 'GET') {
  const blob = await request(path, { method, download: true });
  const url = URL.createObjectURL(blob);
  const link = document.createElement('a');
  link.href = url; link.download = filename;
  document.body.append(link); link.click(); link.remove();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
}

export const money = value => new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', maximumFractionDigits: 0 }).format(Number(value) || 0);
export const number = value => new Intl.NumberFormat('id-ID').format(Number(value) || 0);
export const date = value => value ? new Date(value).toLocaleString('id-ID', { dateStyle: 'medium', timeStyle: 'short' }) : '—';
export const query = values => new URLSearchParams(Object.entries(values).filter(([, value]) => value !== '' && value != null)).toString();

export function formatEscPosReceipt(tx, settings = {}) {
  const width = settings?.paper_width === '80mm' ? 48 : 32;
  const line = (ch = '-') => ch.repeat(width);
  const center = (text) => {
    const s = String(text || '').slice(0, width);
    const pad = Math.max(0, Math.floor((width - s.length) / 2));
    return ' '.repeat(pad) + s;
  };
  const row = (left, right) => {
    const l = String(left || '');
    const r = String(right || '');
    const space = Math.max(1, width - l.length - r.length);
    return l.slice(0, Math.max(1, width - r.length - 1)) + ' '.repeat(space) + r;
  };
  const storeName = (settings?.store_name || 'PAKASIR VAULT').toUpperCase();
  const outletName = tx?.outlet?.name || 'SCBD Flagship Store';
  const address = settings?.address || 'Jl. Jend. Sudirman Kav. 52';
  const phone = settings?.phone || '+62 812-3456-7890';
  const items = tx?.items || [];
  return [
    line('='),
    center(storeName),
    center(outletName),
    center(address),
    center(`Telp: ${phone}`),
    line('='),
    `No. Faktur : ${tx?.invoice_number || 'INV-SAMPLE-0042'}`,
    `Waktu      : ${date(tx?.created_at || new Date().toISOString())}`,
    `Kasir      : ${tx?.cashier_name || 'Budi Santoso'}`,
    `Pelanggan  : ${tx?.customer?.name || tx?.customer_name || 'Walk-in Customer'}`,
    line('-'),
    ...items.map(it => row(`${it.quantity}x ${it.product_name || it.name}`, money(it.subtotal ?? (it.price * it.quantity)))),
    line('-'),
    row('Subtotal', money(tx?.subtotal ?? tx?.total_amount ?? 0)),
    ...(Number(tx?.discount) > 0 ? [row('Diskon', `-${money(tx.discount)}`)] : []),
    row(`PPN (${settings?.tax_rate ?? 11}%)`, money(tx?.tax_amount ?? 0)),
    ...(Number(tx?.service_fee) > 0 ? [row('Service Fee', money(tx.service_fee))] : []),
    line('-'),
    row('TOTAL AKHIR', money(tx?.total_amount ?? 0)),
    ...(Number(tx?.amount_paid) > 0 ? [
      row('Tunai Dibayar', money(tx.amount_paid)),
      row('Kembalian', money(Math.max(0, Number(tx.amount_paid) - Number(tx.total_amount || 0)))),
    ] : []),
    `Metode Bayar : ${tx?.payment_method || 'QRIS Dinamis'}`,
    `Status       : ${tx?.sync_status === 'pending' ? 'ANTRIAN OFFLINE' : 'LUNAS'}`,
    line('='),
    center('Terima kasih atas kunjungan'),
    center('Barang yang sudah dibeli'),
    center('tidak dapat ditukar kembali'),
    line('='),
  ].join('\n');
}

export function playBeep() {
  try {
    const Ctx = window.AudioContext || window.webkitAudioContext;
    if (!Ctx) return;
    const ctx = new Ctx();
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = 1046.5;
    gain.gain.value = 0.08;
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    setTimeout(() => { osc.stop(); ctx.close(); }, 65);
  } catch {}
}
