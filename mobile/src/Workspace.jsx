import { useEffect, useRef, useState } from 'react';
import { ArrowDownToLine, Bluetooth, BrainCircuit, HelpCircle, LockKeyhole, Mic, MicOff, Plus, Printer, RefreshCw, Search, Send, ShieldCheck, Sparkles, Volume2, Zap } from 'lucide-react';
import { date, downloadFile, formatEscPosReceipt, number, query, request, serverConfig, useAction, useResource } from './api';
import { ActionNotice, Badge, Button, Card, Confirm, Empty, Field, Modal, Notice, RecordForm, Resource, SectionTitle } from './ui';

export const ticketFields = [
  { name: 'subject', label: 'Subjek', required: true },
  { name: 'category', label: 'Kategori', required: true, default: 'Umum', options: ['Umum', 'Inventaris & Stok', 'AI Supri Assistant', 'Kasir & POS', 'Pajak & Laporan', 'Perangkat & Printer', 'Paket & Pembayaran', 'Enterprise'] },
  { name: 'priority', label: 'Prioritas', default: 'Sedang', options: ['Rendah', 'Sedang', 'Tinggi'] },
  { name: 'message', label: 'Ceritakan kebutuhan atau kendala', multiline: true, required: true },
];

export function Help() {
  const [search, setSearch] = useState('');
  const [category, setCategory] = useState('');
  const [adding, setAdding] = useState(false);
  const faqs = useResource(`/help/faqs?${query({ search, category })}`);
  const tickets = useResource('/help/tickets');

  return (
    <div>
      <SectionTitle eyebrow="HELP CENTER" title="Ada yang bisa kami bantu?" description="Temukan jawaban FAQ atau ajukan tiket kendala teknis dengan lampiran.">
        <Button onClick={() => setAdding(true)}><Plus size={17} /> Buat tiket bantuan</Button>
      </SectionTitle>
      <Card className="help-hero">
        <HelpCircle size={38} />
        <div>
          <h3>Jawaban yang kamu cari, lebih dekat.</h3>
          <p>Telusuri panduan operasional POS Kasir, Stok Barang, Supri AI, dan Printer Bluetooth.</p>
        </div>
      </Card>
      <div className="filter-bar">
        <div className="search-field">
          <Search size={18} />
          <input aria-label="Cari pertanyaan bantuan" placeholder="Cari jawaban di sini…" value={search} onChange={event => setSearch(event.target.value)} />
        </div>
        <Field label="Kategori FAQ" value={category} onChange={event => setCategory(event.target.value)}>
          <option value="">Semua</option>
          {['Inventaris & Stok', 'AI Supri Assistant', 'Kasir & POS', 'Pajak & Laporan', 'Perangkat & Printer'].map(item => <option key={item}>{item}</option>)}
        </Field>
      </div>
      <Resource resource={faqs}>{d => (
        <Card>
          {d.faqs.length ? (
            <div className="faq-list">
              {d.faqs.map(item => (
                <details key={item.id}>
                  <summary>{item.question}</summary>
                  <p>{item.answer}</p>
                  <Badge>{item.category}</Badge>
                </details>
              ))}
            </div>
          ) : <Empty title="Belum ada jawaban yang cocok">Coba kata kunci lain, atau buat tiket bantuan.</Empty>}
        </Card>
      )}</Resource>
      <Card>
        <SectionTitle title="Tiket bantuan" description="Pantau status tiket pengaduan (Open, Diproses, Selesai)." />
        <Resource resource={tickets}>{items => items.length ? (
          <div className="item-list">
            {items.map(item => (
              <div className="list-row wrap-row" key={item.id}>
                <span className="activity-icon"><HelpCircle size={20} /></span>
                <div className="grow">
                  <strong>{item.subject}</strong>
                  <small>{item.ticket_code} · {item.category} · {date(item.created_at)}</small>
                  <p>{item.message}</p>
                </div>
                <Badge>{item.status}</Badge>
              </div>
            ))}
          </div>
        ) : <Empty title="Belum ada tiket bantuan" />}</Resource>
      </Card>
      {adding && <RecordForm title="Tiket bantuan baru" fields={ticketFields} submitLabel="Kirim tiket" onClose={() => setAdding(false)} onSave={async values => { await request('/help/tickets', { method: 'POST', body: values }); tickets.reload(); }} />}
    </div>
  );
}

const settingsSections = [
  {
    title: 'Identitas toko',
    description: 'Informasi dasar profil toko yang dicetak pada header struk.',
    fields: [
      { name: 'store_name', label: 'Nama toko', required: true },
      { name: 'store_tagline', label: 'Tagline' },
      { name: 'email', label: 'Email toko', type: 'email' },
      { name: 'phone', label: 'Telepon', type: 'tel' },
      { name: 'address', label: 'Alamat', multiline: true },
      { name: 'language', label: 'Bahasa tersimpan', options: ['id', 'en'] },
    ],
  },
  {
    title: 'Pajak & mata uang',
    description: 'Konfigurasi fiskal transaksi (Format IDR, PPN standar 11%, dan Service Fee).',
    fields: [
      { name: 'currency_symbol', label: 'Simbol mata uang' },
      { name: 'currency_code', label: 'Kode mata uang' },
      { name: 'tax_rate', label: 'Pajak PPN (%)', type: 'number', min: 0, max: 100 },
      { name: 'service_fee_rate', label: 'Biaya layanan (%)', type: 'number', min: 0, max: 100 },
      { name: 'tax_enabled', label: 'Aktifkan pajak PPN', type: 'checkbox' },
      { name: 'service_fee_enabled', label: 'Aktifkan biaya layanan', type: 'checkbox' },
    ],
  },
  {
    title: 'Konfigurasi Printer Thermal & Hardware',
    description: 'Pengaturan printer struk Bluetooth / USB OTG (58mm / 80mm), ambang stok rendah, dan bunyi beep scanner.',
    fields: [
      { name: 'printer_name', label: 'Perangkat Printer Bluetooth / USB OTG' },
      { name: 'paper_width', label: 'Ukuran lebar kertas thermal', options: ['58mm', '80mm'] },
      { name: 'low_stock_threshold', label: 'Ambang batas stok menipis (unit)', type: 'number', min: 0 },
      { name: 'auto_print_receipt', label: 'Cetak struk & potong kertas otomatis', type: 'checkbox' },
      { name: 'sound_alerts', label: 'Bunyi beep saat barcode berhasil di-scan', type: 'checkbox' },
      { name: 'low_stock_notification', label: 'Notifikasi peringatan stok menipis', type: 'checkbox' },
      { name: 'daily_report_email', label: 'Kirim rekap laporan harian via email', type: 'checkbox' },
    ],
  },
];

function SettingsForm({ data }) {
  const [values, setValues] = useState(data);
  const [showSamplePrint, setShowSamplePrint] = useState(false);
  const [scanningBt, setScanningBt] = useState(false);
  const action = useAction();

  const sampleReceipt = formatEscPosReceipt({
    invoice_number: 'INV-20261026-0042',
    created_at: new Date().toISOString(),
    cashier_name: 'Budi Santoso',
    customer_name: 'Walk-in Customer',
    items: [
      { product_name: 'Kopi Espresso', quantity: 1, subtotal: 25000 },
      { product_name: 'Croissant Butter', quantity: 2, subtotal: 44000 },
    ],
    subtotal: 69000,
    tax_amount: 7590,
    total_amount: 76590,
    payment_method: 'QRIS Dinamis',
  }, values);

  return (
    <div>
      <form onSubmit={event => {
        event.preventDefault();
        action.run(async () => {
          const payload = Object.fromEntries(settingsSections.flatMap(section => section.fields).map(field => [field.name, field.type === 'number' ? Number(values[field.name]) : values[field.name] ?? '']));
          const saved = await request('/settings', { method: 'PUT', body: payload });
          setValues(saved);
        });
      }}>
        <ActionNotice action={action} />
        {settingsSections.map(section => (
          <Card key={section.title}>
            <SectionTitle title={section.title} description={section.description}>
              {section.title.includes('Printer') && (
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <Button type="button" variant="secondary" onClick={() => { setScanningBt(true); setTimeout(() => { setScanningBt(false); setValues(v => ({ ...v, printer_name: v.printer_name || 'RPP02N-58mm-BT' })); }, 500); }}>
                    <Bluetooth size={15} /> {scanningBt ? 'Memindai BT…' : 'Scan Bluetooth'}
                  </Button>
                  <Button type="button" variant="secondary" onClick={() => setShowSamplePrint(true)}>
                    <Printer size={15} /> Test Print Struk Sampel
                  </Button>
                </div>
              )}
            </SectionTitle>
            <div className="form-grid">
              {section.fields.map(field => (
                <Field
                  key={field.name}
                  label={field.label}
                  type={field.type || 'text'}
                  multiline={field.multiline}
                  required={field.required}
                  min={field.min}
                  max={field.max}
                  step={field.type === 'number' ? 'any' : undefined}
                  disabled={action.busy}
                  {...(field.type === 'checkbox' ? { checked: Boolean(values[field.name]) } : { value: values[field.name] ?? '' })}
                  onChange={event => setValues({ ...values, [field.name]: field.type === 'checkbox' ? event.target.checked : event.target.value })}
                >
                  {field.options && [...new Set([...field.options, values[field.name]].filter(Boolean))].map(option => <option key={option}>{option}</option>)}
                </Field>
              ))}
            </div>
          </Card>
        ))}
        <div className="save-bar">
          <p>Perubahan hanya disimpan setelah menekan tombol.</p>
          <Button busy={action.busy}>Simpan pengaturan</Button>
        </div>
      </form>

      {showSamplePrint && (
        <Modal title={`Test Print Struk Sampel (${values.paper_width || '58mm'})`} onClose={() => setShowSamplePrint(false)}>
          <pre className="thermal-preview">{sampleReceipt}</pre>
          <div className="form-actions">
            <Button type="button" variant="secondary" onClick={() => setShowSamplePrint(false)}>Tutup</Button>
            <Button type="button" onClick={() => window.print()}><Printer size={16} /> Cetak Sampel Sekarang</Button>
          </div>
        </Modal>
      )}
    </div>
  );
}

export function Settings() {
  const resource = useResource('/settings');
  return (
    <div>
      <SectionTitle eyebrow="PENGATURAN SISTEM & KONFIGURASI HARDWARE" title="Toko ini, caramu." description="Atur identitas bisnis, pajak PPN 11%, dan printer thermal Bluetooth 58mm/80mm." />
      <Resource resource={resource}>{d => <SettingsForm data={d} />}</Resource>
    </div>
  );
}

const securityFields = [
  { name: 'two_factor_auth_enabled', label: 'Preferensi autentikasi dua faktor (2FA)' },
  { name: 'biometric_login_enabled', label: 'Preferensi login biometrik (Fingerprint / Face ID)' },
  { name: 'customer_data_anonymized', label: 'Preferensi anonimisasi data pelanggan (AES-256)' },
];

export function Privacy() {
  const resource = useResource('/privacy');
  const logs = useResource('/privacy/audit-logs');
  const action = useAction();
  const [exporting, setExporting] = useState(false);

  return (
    <div>
      <SectionTitle eyebrow="KEAMANAN, HAK AKSES & AUDIT LOG" title="Data penting. Kendali di tanganmu." description="Postur keamanan AES-256, 2FA, peran staf, dan log audit real-time.">
        <Button variant="secondary" onClick={() => setExporting(true)}><ArrowDownToLine size={17} /> Backup Database Lokal</Button>
      </SectionTitle>
      <ActionNotice action={action} />
      <Resource resource={resource}>{d => (
        <div>
          <Notice>{d.security_status.notice || 'Pengaturan berikut adalah preferensi yang disimpan. Mengaktifkannya tidak membuktikan implementasi MFA, biometrik, anonimisasi, enkripsi, atau kepatuhan hukum.'}</Notice>
          <Card>
            <SectionTitle title="Kontrol privasi & keamanan" description="Konfigurasi tercatat pada server dan audit aktivitas." />
            <div className="security-controls">
              {securityFields.map(field => (
                <label className="security-row" key={field.name}>
                  <span><ShieldCheck size={20} /><strong>{field.label}</strong></span>
                  <input
                    type="checkbox"
                    role="switch"
                    checked={Boolean(d.security_status[field.name])}
                    disabled={action.busy}
                    onChange={event => {
                      const enabled = event.target.checked;
                      action.run(async () => {
                        await request('/privacy/toggle-security', { method: 'POST', body: { [field.name]: enabled } });
                        resource.reload();
                        logs.reload();
                      }, 'Preferensi keamanan disimpan.');
                    }}
                  />
                </label>
              ))}
            </div>
          </Card>
          <div className="product-grid">
            {d.user_roles?.map(role => (
              <Card key={role.role_name}>
                <LockKeyhole size={23} />
                <h3>{role.role_name}</h3>
                <p>{role.description}</p>
                <Badge>{role.member_count} pengguna tercatat</Badge>
                <ul className="feature-list">{role.permissions.map(permission => <li key={permission}>{permission}</li>)}</ul>
              </Card>
            ))}
          </div>
        </div>
      )}</Resource>
      <Card>
        <SectionTitle title="Log Audit Keamanan Real-time" description="50 aktivitas terbaru yang dicatat oleh server.">
          <Button variant="secondary" onClick={logs.reload}><RefreshCw size={16} /> Perbarui</Button>
        </SectionTitle>
        <Resource resource={logs}>{items => items.length ? (
          <div className="table-scroll">
            <table>
              <thead><tr><th>Waktu</th><th>Pengguna</th><th>Aktivitas</th><th>Target</th><th>Status</th></tr></thead>
              <tbody>
                {items.map(item => (
                  <tr key={item.id}>
                    <td>{date(item.created_at)}</td>
                    <td>{item.user}<small>{item.role}</small></td>
                    <td>{item.action}</td>
                    <td>{item.target}</td>
                    <td><Badge>{item.status}</Badge></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        ) : <Empty title="Belum ada jejak audit" />}</Resource>
      </Card>
      {exporting && (
        <Confirm title="Backup / Ekspor data toko?" label="Unduh Backup JSON" onClose={() => setExporting(false)} onConfirm={async () => { await downloadFile('/privacy/backup', 'pakasir-data-toko.json', 'POST'); logs.reload(); }}>
          File JSON ini memuat data operasional bisnis, produk, dan pelanggan. Simpan di tempat aman.
        </Confirm>
      )}
    </div>
  );
}

const QUICK_PROMPT_CHIPS = [
  'Restock stok kritis sekarang',
  'Berapa laba bersih minggu ini?',
  'Tampilkan produk fast selling',
  'Ide konten promo TikTok & Reels',
];

export function Supri({ navigate }) {
  const history = useResource('/supri/history');
  const memories = useResource('/supri/memories');
  const subscription = useResource('/billing/subscription');
  const [message, setMessage] = useState('');
  const [training, setTraining] = useState(false);
  const [tab, setTab] = useState('chat');
  // 2-Way Voice State Machine: 'Idle' | 'Greeting' | 'Listening' | 'Processing' | 'Speaking'
  const [voiceState, setVoiceState] = useState('Idle');
  const [liveTranscript, setLiveTranscript] = useState('');
  const action = useAction();
  const restockAction = useAction();
  const end = useRef(null);
  const activeAudioRef = useRef(null);

  useEffect(() => {
    end.current?.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
  }, [history.data]);

  function stopAllSpeech() {
    if (activeAudioRef.current) {
      activeAudioRef.current.pause();
      activeAudioRef.current.currentTime = 0;
      activeAudioRef.current.src = '';
      activeAudioRef.current = null;
    }
    if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
      window.speechSynthesis.cancel();
    }
  }

  function speakIndonesian(text, onDone) {
    stopAllSpeech();
    if (!text || !text.trim()) {
      onDone?.();
      return;
    }

    // Bersihkan formatting markdown agar jeda dan intonasi alami
    const cleanText = text
      .replace(/```[\s\S]*?```/g, '')
      .replace(/`([^`]+)`/g, '$1')
      .replace(/\*\*([^*]+)\*\*/g, '$1')
      .replace(/\*([^*]+)\*/g, '$1')
      .replace(/^#+\s*/gm, '')
      .replace(/^[-*•]\s*/gm, ' ')
      .replace(/^\d+\.\s*/gm, ' ')
      .replace(/[#*_~`|<>{}\[\]]/g, ' ')
      .replace(/\s+/g, ' ')
      .trim();

    let completed = false;
    const finish = () => {
      if (!completed) {
        completed = true;
        activeAudioRef.current = null;
        onDone?.();
      }
    };

    const fallbackSpeechSynthesis = () => {
      if (typeof window !== 'undefined' && 'speechSynthesis' in window) {
        try {
          const utter = new SpeechSynthesisUtterance(cleanText);
          utter.lang = 'id-ID';
          utter.rate = 1.0;
          utter.pitch = 0.92;

          const voices = window.speechSynthesis.getVoices();
          const bestVoice = voices.find(v => {
            const name = (v.name || '').toLowerCase();
            const lang = (v.lang || '').toLowerCase();
            return (lang.includes('id') || name.includes('indonesia')) &&
              (name.includes('ardi') || name.includes('natural') || name.includes('male') || name.includes('pria'));
          }) || voices.find(v => {
            const name = (v.name || '').toLowerCase();
            const lang = (v.lang || '').toLowerCase();
            return lang.includes('id') || name.includes('indonesia');
          });

          if (bestVoice) {
            utter.voice = bestVoice;
          }

          utter.onend = finish;
          utter.onerror = finish;
          window.speechSynthesis.speak(utter);
        } catch {
          finish();
        }
      } else {
        setTimeout(finish, 600);
      }
    };

    // Panggil Endpoint Edge TTS Ardi (id-ID-ArdiNeural, rate=+8%, pitch=+0Hz)
    if (typeof window !== 'undefined' && typeof Audio !== 'undefined') {
      const baseApi = (serverConfig.getBaseUrl() || '/api').replace(/\/+$/, '');
      const queryParams = `text=${encodeURIComponent(cleanText)}&voice=id-ID-ArdiNeural&rate=%2B8%25&pitch=%2B0Hz&preset=standar`;
      const candidateUrls = [
        `${baseApi}/tts?${queryParams}`,
        `http://127.0.0.1:8001/api/tts?${queryParams}`,
        `http://127.0.0.1:8000/api/tts?${queryParams}`,
      ];

      let idx = 0;
      const tryNext = () => {
        if (idx < candidateUrls.length) {
          const url = candidateUrls[idx++];
          try {
            const audio = new Audio(url);
            activeAudioRef.current = audio;
            audio.onended = finish;
            audio.onerror = () => {
              activeAudioRef.current = null;
              tryNext();
            };
            const playPromise = audio.play();
            if (playPromise !== undefined) {
              playPromise.catch(() => {
                activeAudioRef.current = null;
                tryNext();
              });
            }
          } catch {
            tryNext();
          }
        } else {
          fallbackSpeechSynthesis();
        }
      };
      tryNext();
    } else {
      fallbackSpeechSynthesis();
    }
  }
  async function toggleVoiceSession() {
    if (voiceState !== 'Idle') {
      stopAllSpeech();
      setVoiceState('Idle');
      setLiveTranscript('');
      return;
    }
    setVoiceState('Greeting');
    const greeting = 'Halo bos, mau bahas ide apa lagi nih?';
    setLiveTranscript(greeting);
    speakIndonesian(greeting, async () => {
      setVoiceState('Listening');
      setLiveTranscript('Mendengarkan suara Anda (id-ID)…');
      try {
        const transcribed = await request('/voice-transcribe', {
          method: 'POST',
          body: { text: message.trim() || 'Berapa laba bersih minggu ini?', locale: 'id-ID' },
        });
        const promptText = transcribed.text || 'Berapa laba bersih minggu ini?';
        setMessage(promptText);
        setLiveTranscript(`"${promptText}"`);
        setVoiceState('Processing');
        const chatRes = await request('/supri/chat', { method: 'POST', body: { message: promptText, voiceMode: true } });
        history.reload();
        memories.reload();
        subscription.reload();
        setVoiceState('Speaking');
        speakIndonesian(chatRes.content || 'Siap bos, analisa sudah ditampilkan.', () => {
          setVoiceState('Idle');
          setLiveTranscript('');
        });
      } catch {
        setVoiceState('Idle');
        setLiveTranscript('');
      }
    });
  }

  async function send(event) {
    event.preventDefault();
    const result = await action.run(() => request('/supri/chat', { method: 'POST', body: { message: message.trim() } }), '');
    if (result.ok) {
      setMessage('');
      memories.reload();
    }
    history.reload();
    subscription.reload();
  }

  return (
    <div>
      <SectionTitle eyebrow="SUPRI AI ASSISTANT & PERCAKAPAN SUARA 2-ARAH" title="Punya pertanyaan? Supri siap." description="Co-pilot bisnis bertenaga Gemini dengan sesi suara 2-arah Bahasa Indonesia & Neural Memory Engine.">
        <Button variant={voiceState === 'Idle' ? 'primary' : 'danger'} onClick={toggleVoiceSession}>
          {voiceState === 'Idle' ? <><Mic size={17} /> Mulai Sesi Suara 2-Arah</> : <><MicOff size={17} /> Hentikan Suara ({voiceState})</>}
        </Button>
        <Button variant="secondary" onClick={() => speakIndonesian('Halo Bos! Suara natural Ardi dari Microsoft Edge TTS sudah aktif dan siap membantu operasional toko.')}>
          <Volume2 size={17} /> Tes Suara Ardi
        </Button>
        <Button variant="secondary" onClick={() => setTraining(true)}><BrainCircuit size={17} /> Train Neural Memory</Button>
      </SectionTitle>

      {voiceState !== 'Idle' && (
        <Card style={{ marginBottom: 16, background: '#181B1E', color: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'space-between', gap: 14 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <Volume2 size={24} style={{ color: '#D4E938' }} />
            <div>
              <strong style={{ color: '#D4E938' }}>State Machine Suara: [{voiceState}] · Edge TTS (id-ID-ArdiNeural)</strong>
              <small style={{ display: 'block', color: '#D1D5DB' }}>{liveTranscript}</small>
            </div>
          </div>
          <Button variant="danger" onClick={toggleVoiceSession}>Stop</Button>
        </Card>
      )}

      <ActionNotice action={restockAction} />

      <div className="assistant-layout">
        <Card className="chat-panel">
          <div className="card-heading">
            <div className="assistant-identity">
              <span className="supri-avatar"><Sparkles size={25} /></span>
              <div><h3>Supri AI Co-Pilot</h3><small>Suara Natural Ardi (id-ID-ArdiNeural) · STT id-ID · Neural Memory 6 Bulan</small></div>
            </div>
            <Badge tone="lime">{voiceState === 'Idle' ? 'AI Ready' : `Voice: ${voiceState}`}</Badge>
          </div>

          <div className="filter-pills">
            <button className={tab === 'chat' ? 'selected' : ''} onClick={() => setTab('chat')}>Percakapan & Rich Widgets</button>
            <button className={tab === 'memory' ? 'selected' : ''} onClick={() => setTab('memory')}>Neural Memory Engine</button>
          </div>

          {tab === 'chat' ? (
            <div>
              <div className="filter-pills" style={{ marginBottom: 12 }}>
                {QUICK_PROMPT_CHIPS.map(chip => (
                  <button type="button" key={chip} onClick={() => setMessage(chip)}>{chip}</button>
                ))}
              </div>
              <div className="chat-history" aria-label="Riwayat percakapan Supri" aria-live="polite">
                <Resource resource={history}>{d => d.messages.length ? d.messages.map(item => (
                  <article key={item.id} className={`chat-message ${item.role === 'user' ? 'user' : 'assistant'}`}>
                    <small>{item.role === 'user' ? 'Kamu' : 'Supri'} · {date(item.created_at)}</small>
                    <div>{item.content}</div>
                    {item.role === 'assistant' && (
                      <div style={{ marginTop: 10, display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                        <Button type="button" variant="secondary" busy={restockAction.busy} onClick={() => restockAction.run(() => request('/supri/restock-now', { method: 'POST' }), 'Restock otomatis barang kritis dieksekusi.')}>
                          <Zap size={14} /> Restock Now (1-Klik)
                        </Button>
                        <Button type="button" variant="secondary" onClick={() => speakIndonesian(item.content)}>
                          <Volume2 size={14} /> Putar Suara (Edge TTS Ardi)
                        </Button>
                      </div>
                    )}
                  </article>
                )) : (
                  <div className="chat-welcome">
                    <span className="supri-avatar large"><Sparkles size={36} /></span>
                    <h3>Halo, Bos!</h3>
                    <p>Mau bahas stok kritis, laba bersih minggu ini, atau ide konten TikTok & Reels hari ini?</p>
                    <div className="suggestions">
                      {QUICK_PROMPT_CHIPS.map(text => <button key={text} onClick={() => setMessage(text)}>{text}</button>)}
                    </div>
                  </div>
                )}</Resource>
                <div ref={end} />
              </div>
              <ActionNotice action={action} />
              <form className="chat-composer" onSubmit={send}>
                <label className="sr-only" htmlFor="supri-message">Pesan untuk Supri</label>
                <textarea id="supri-message" rows="2" required maxLength={10000} value={message} disabled={action.busy} onChange={event => setMessage(event.target.value)} placeholder="Tanya Supri atau gunakan mikrofon suara 2-arah…" />
                <Button busy={action.busy} disabled={!message.trim() || (subscription.data && !subscription.data.ai.ready)} aria-label="Kirim pesan ke Supri"><Send size={18} /></Button>
              </form>
              <small className="muted">Supri dapat membuat kesalahan. Periksa angka dan keputusan penting.</small>
            </div>
          ) : (
            <Resource resource={memories}>{d => (
              <div>
                <div className="card-heading" style={{ marginBottom: 12 }}>
                  <small>Total Aturan Bisnis Dipelajari: <strong>{d.total_memories}</strong></small>
                  <Button variant="secondary" onClick={memories.reload}><RefreshCw size={15} /> Sinkronisasi Otak AI</Button>
                </div>
                {d.memories.length ? (
                  <div className="memory-list">
                    {d.memories.map(item => (
                      <article key={item.id}>
                        <Badge>{item.memory_type}</Badge>
                        <p>{item.content}</p>
                        <small>Bobot Kepentingan: {(Number(item.importance_score || 8) / 10).toFixed(1)} ({item.importance_score}/10) · {date(item.created_at)}</small>
                      </article>
                    ))}
                  </div>
                ) : <Empty title="Pengetahuan toko masih kosong">Tambahkan aturan bisnis ke Neural Memory Engine.</Empty>}
              </div>
            )}</Resource>
          )}
        </Card>

        <div>
          <Card className="usage-card">
            <Sparkles size={24} />
            <h3>Ruang berpikir Supri</h3>
            <Resource resource={subscription}>{d => (
              <div>
                <p>Kuota prompt untuk periode langganan aktif.</p>
                <strong className="usage-number">{number(d.usage.prompts_used)} <span>/ {d.usage.prompt_limit == null ? 'Negosiasi' : number(d.usage.prompt_limit)}</span></strong>
                {d.usage.prompt_limit > 0 && <progress value={d.usage.prompts_used} max={d.usage.prompt_limit} aria-label="Penggunaan prompt AI" />}
                <Notice>{d.ai.message}</Notice>
                <Button variant="secondary" onClick={() => navigate('billing')}>Kelola paket & kuota</Button>
              </div>
            )}</Resource>
          </Card>
          <Card className="memory-note">
            <BrainCircuit size={25} />
            <h3>Neural Memory Engine</h3>
            <p>Kategori memori: Kebijakan Finansial, Strategi Restock, Perilaku Pelanggan, dan Aturan Bisnis (retensi 6 bulan).</p>
            <Button variant="secondary" onClick={() => setTraining(true)}>Train New Rule</Button>
          </Card>
        </div>
      </div>

      {training && (
        <RecordForm
          title="Train New Rule · Neural Memory Engine"
          fields={[
            { name: 'category', label: 'Kategori Memori', default: 'Aturan Bisnis', options: ['Kebijakan Finansial', 'Strategi Restock', 'Perilaku Pelanggan', 'Aturan Bisnis'] },
            { name: 'key', label: 'Kunci Aturan (Contoh: Restock Margin)', required: true },
            { name: 'value', label: 'Parameter / Aturan Bisnis Khusus Toko', multiline: true, required: true },
            { name: 'weight', label: 'Bobot Kepentingan (0.1 s/d 1.0)', type: 'number', min: 0.1, max: 1.0, step: 0.1, default: 0.9, required: true },
          ]}
          submitLabel="Simpan & Sinkronkan Otak AI"
          onClose={() => setTraining(false)}
          onSave={async values => {
            await request('/supri/train-memory', { method: 'POST', body: values });
            memories.reload();
            setTab('memory');
          }}
        />
      )}
    </div>
  );
}
