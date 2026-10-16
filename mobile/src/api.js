import { useCallback, useEffect, useState } from 'react';

const TOKEN_KEY = 'pakasir.session';
export const session = {
  get: () => sessionStorage.getItem(TOKEN_KEY),
  set: (token) => sessionStorage.setItem(TOKEN_KEY, token),
  clear: () => sessionStorage.removeItem(TOKEN_KEY),
};

export async function request(path, { method = 'GET', body, signal, download = false } = {}) {
  let response;
  try {
    response = await fetch(`/api${path}`, {
      method, signal,
      headers: { Accept: download ? '*/*' : 'application/json', ...(body ? { 'Content-Type': 'application/json' } : {}), ...(session.get() ? { Authorization: `Bearer ${session.get()}` } : {}) },
      ...(body ? { body: JSON.stringify(body) } : {}),
    });
  } catch (error) {
    if (error.name === 'AbortError') throw error;
    throw new Error('Server tidak dapat dihubungi. Periksa koneksi dan pastikan layanan API aktif.');
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
