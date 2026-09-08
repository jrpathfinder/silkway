import { useState } from 'react';
import { api, ApiError } from '../api';

export function ImportExportPanel({ onUnauthorized }: { onUnauthorized: () => void }) {
  const [error, setError] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);
  const [importText, setImportText] = useState('');
  const [busy, setBusy] = useState(false);

  const handleError = (err: unknown) => {
    if (err instanceof ApiError && err.status === 401) return onUnauthorized();
    setError(err instanceof ApiError ? err.message : 'Что-то пошло не так');
  };

  const exportNow = async () => {
    setError(null);
    setBusy(true);
    try {
      const data = await api.exportCatalog();
      const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
      const url = URL.createObjectURL(blob);
      const link = document.createElement('a');
      link.href = url;
      link.download = `catalog-export-${new Date().toISOString().slice(0, 10)}.json`;
      link.click();
      URL.revokeObjectURL(url);
    } catch (err) {
      handleError(err);
    } finally {
      setBusy(false);
    }
  };

  const importNow = async () => {
    setError(null);
    setResult(null);
    setBusy(true);
    try {
      const payload = JSON.parse(importText);
      const summary = await api.importCatalog(payload);
      setResult(`Импортировано: ${summary.categories} категорий, ${summary.items} блюд, ${summary.modifiers} модификаторов, ${summary.promotions} акций.`);
      setImportText('');
    } catch (err) {
      if (err instanceof SyntaxError) setError('Не удалось разобрать JSON — проверьте формат.');
      else handleError(err);
    } finally {
      setBusy(false);
    }
  };

  return (
    <section>
      <div className="heading">
        <div>
          <p className="eyebrow">Каталог</p>
          <h1>Импорт / Экспорт</h1>
        </div>
      </div>

      {error && <div className="form-error">{error}</div>}
      {result && <div className="form-success">{result}</div>}

      <div className="panel form-panel">
        <div className="panel-title">
          <h2>Экспорт</h2>
        </div>
        <p className="muted">
          Скачивает текущий каталог (категории, блюда, модификаторы, акции) в виде JSON — авторские цены, без
          применённых скидок. Этот же файл можно вставить обратно в форму импорта ниже — для резервной копии или
          переноса на другую базу.
        </p>
        <button className="primary" onClick={exportNow} disabled={busy}>
          Скачать catalog-export.json
        </button>
      </div>

      <div className="panel form-panel">
        <div className="panel-title">
          <h2>Импорт</h2>
        </div>
        <p className="muted">
          Вставьте JSON в формате экспорта выше. Позиции обновляются по id — можно смело импортировать один и тот же
          файл повторно, начислений не будет.
        </p>
        <textarea
          rows={10}
          placeholder='{"categories": [...], "items": [...], "promotions": [...]}'
          value={importText}
          onChange={(e) => setImportText(e.target.value)}
        />
        <button className="primary" onClick={importNow} disabled={busy || !importText.trim()}>
          Импортировать
        </button>
      </div>
    </section>
  );
}
