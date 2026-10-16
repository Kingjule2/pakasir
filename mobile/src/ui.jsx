import { useEffect, useId, useRef, useState } from 'react';
import { ArrowUpRight, Check, CircleAlert, LoaderCircle, PackageOpen, RefreshCw, X } from 'lucide-react';
import { useAction } from './api';

export function Button({ children, variant = 'primary', busy, className = '', ...props }) {
  return <button className={`button ${variant} ${className}`} {...props} disabled={busy || props.disabled}>{busy && <LoaderCircle className="spin" size={16} />}{children}</button>;
}
export function Badge({ children, tone = '' }) { return <span className={`badge ${tone}`}>{children}</span>; }
export function Card({ children, className = '', ...props }) { return <section className={`card ${className}`} {...props}>{children}</section>; }
export function SectionTitle({ eyebrow, title, description, children }) {
  return <div className="section-heading"><div>{eyebrow && <span className="eyebrow">{eyebrow}</span>}<h2>{title}</h2>{description && <p>{description}</p>}</div>{children && <div className="heading-actions">{children}</div>}</div>;
}
export function Notice({ children, error = false, success = false }) {
  if (!children) return null;
  return <div className={`notice ${error ? 'error' : success ? 'success' : ''}`} role={error ? 'alert' : 'status'}>{success ? <Check size={18} /> : <CircleAlert size={18} />}<span>{children}</span></div>;
}
export function ActionNotice({ action }) { return <><Notice error>{action.error}</Notice><Notice success>{action.success}</Notice></>; }
export function Empty({ title = 'Belum ada data', children }) { return <div className="empty"><PackageOpen size={32} /><h3>{title}</h3>{children && <p>{children}</p>}</div>; }
export function Resource({ resource, children }) {
  if (resource.loading) return <div className="loading" role="status"><LoaderCircle className="spin" size={24} /><span>Memuat data toko…</span></div>;
  if (resource.error) return <Card><Notice error>{resource.error}</Notice><Button variant="secondary" onClick={resource.reload}><RefreshCw size={16} /> Coba lagi</Button></Card>;
  return children(resource.data);
}
export function Stat({ label, value, detail, icon: Icon, tone = '' }) {
  return <Card className={`stat ${tone}`}><div className="stat-top"><span>{label}</span>{Icon && <Icon size={19} />}</div><strong>{value}</strong><span className="stat-detail">{detail || 'Data tersimpan di server'}<ArrowUpRight size={15} /></span></Card>;
}
export function Field({ label, children, hint, ...props }) {
  const id = useId();
  return <label className={`field ${props.type === 'checkbox' ? 'check-field' : ''}`} htmlFor={id}><span>{label}</span>{children ? <select id={id} {...props}>{children}</select> : props.multiline ? <textarea id={id} {...Object.fromEntries(Object.entries(props).filter(([key]) => key !== 'multiline'))} /> : <input id={id} {...props} />}{hint && <small>{hint}</small>}</label>;
}
export function Modal({ title, children, onClose }) {
  const dialog = useRef(null);
  const titleId = useId();
  useEffect(() => {
    const previous = document.activeElement;
    dialog.current.showModal();
    return () => { previous?.focus?.(); };
  }, []);
  return <dialog className="modal" ref={dialog} aria-labelledby={titleId} onCancel={event => { event.preventDefault(); onClose(); }}><div className="modal-heading"><h2 id={titleId}>{title}</h2><button className="icon-button" aria-label="Tutup dialog" onClick={onClose}><X size={20} /></button></div>{children}</dialog>;
}
export function RecordForm({ title, fields, initial = {}, onSave, onClose, submitLabel = 'Simpan' }) {
  const [values, setValues] = useState(() => Object.fromEntries(fields.map(field => [field.name, initial[field.name] ?? field.default ?? (field.type === 'checkbox' ? false : '')])));
  const action = useAction();
  async function submit(event) {
    event.preventDefault();
    const data = Object.fromEntries(fields.map(field => [field.name, field.type === 'number' ? Number(values[field.name]) : values[field.name]]));
    const result = await action.run(() => onSave(data));
    if (result.ok) onClose();
  }
  return <Modal title={title} onClose={() => { if (!action.busy) onClose(); }}><form onSubmit={submit}><div className="form-grid">{fields.map(field => <Field key={field.name} label={field.label} type={field.type || 'text'} required={field.required} min={field.min} max={field.max} step={field.step} multiline={field.multiline} disabled={field.disabled || action.busy} {...(field.type === 'checkbox' ? { checked: values[field.name] } : { value: values[field.name] })} onChange={event => setValues({ ...values, [field.name]: field.type === 'checkbox' ? event.target.checked : event.target.value })}>{field.options?.map(option => <option key={typeof option === 'object' ? option.value : option} value={typeof option === 'object' ? option.value : option}>{typeof option === 'object' ? option.label : option}</option>)}</Field>)}</div><ActionNotice action={action} /><div className="form-actions"><Button type="button" variant="secondary" disabled={action.busy} onClick={onClose}>Batal</Button><Button busy={action.busy}>{submitLabel}</Button></div></form></Modal>;
}
export function Confirm({ title, children, onConfirm, onClose, label = 'Ya, lanjutkan' }) {
  const action = useAction();
  return <Modal title={title} onClose={() => { if (!action.busy) onClose(); }}><p>{children}</p><ActionNotice action={action} /><div className="form-actions"><Button variant="secondary" disabled={action.busy} onClick={onClose}>Batal</Button><Button variant="danger" busy={action.busy} onClick={async () => { const result = await action.run(onConfirm); if (result.ok) onClose(); }}>{label}</Button></div></Modal>;
}
export function Pagination({ page, lastPage, onChange }) {
  if (lastPage <= 1) return null;
  return <div className="pagination"><Button variant="secondary" disabled={page <= 1} onClick={() => onChange(page - 1)}>Sebelumnya</Button><span>{page} / {lastPage}</span><Button variant="secondary" disabled={page >= lastPage} onClick={() => onChange(page + 1)}>Berikutnya</Button></div>;
}
