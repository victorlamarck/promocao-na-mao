// Lista que alguém compartilhou (/l/<código>; protótipo Web-ListaRecebida.dc.html).
// Quem recebe marca o que pegou; quem mandou vê na hora (tempo real em lib/lista.ts).
import { useEffect, useMemo, useState } from 'preact/hooks';
import { Lista, type Item } from '../lib/lista';
import { mercado } from '../lib/formato';
import { usarLista } from './usarLista';
import Vence from './Vence';

function ha(iso: string) {
  const m = Math.floor((Date.now() - new Date(iso).getTime()) / 60000);
  return m < 1 ? 'agora' : m < 60 ? `há ${m} min` : m < 1440 ? `há ${Math.floor(m / 60)} h` : `há ${Math.floor(m / 1440)} d`;
}

export default function ListaRecebida() {
  const codigo = location.pathname.split('/').filter(Boolean)[1] ?? '';
  const lista = usarLista(useMemo(() => Lista.recebida(codigo), [codigo]));
  const [falhou, setFalhou] = useState(false);
  useEffect(() => { lista.carregar(); }, [lista]);

  const l = lista.lida;
  if (!l) {
    return lista.erro
      ? <p class="tracejado">Não achamos esta lista. Confira o link com quem mandou. <a href="/">Ver ofertas de hoje</a></p>
      : <p class="suave" role="status">Abrindo a lista…</p>;
  }

  const quem = l.nome_dono;
  const total = l.itens.length, pegos = l.itens.filter((i) => i.pego).length;
  const faltando = l.itens.filter((i) => !i.pego).map((i) => i.texto);
  const mensagem = faltando.length === 0 ? 'Terminei as compras da lista! ✔' : `Terminei as compras. Faltou: ${faltando.join(', ')}`;

  async function marcar(i: Item, pego: boolean) {
    try { await lista.marcar(i, pego); setFalhou(false); } catch { setFalhou(true); }
  }

  return (
    <>
      <section class="destaque" style={{ flexDirection: 'column', alignItems: 'stretch', gap: '8px', padding: '20px' }}>
        <span style={{ fontSize: '14px', fontWeight: 700, color: 'var(--verde-claro)' }}>
          {quem ? `${quem} compartilhou esta lista com você` : 'Compartilharam esta lista com você'} · atualizada {ha(l.atualizado_em)}
        </span>
        <h1 style={{ fontSize: '28px', lineHeight: '34px' }}>{pegos} de {total} itens pegos</h1>
        <div style={{ height: '8px', borderRadius: '4px', background: 'rgba(255,255,255,.25)', overflow: 'hidden' }}
          role="progressbar" aria-label="Itens pegos" aria-valuemin={0} aria-valuemax={total} aria-valuenow={pegos}>
          <div style={{ height: '100%', borderRadius: '4px', background: 'var(--verde-claro)', width: `${total ? Math.round((pegos / total) * 100) : 0}%` }} />
        </div>
        <span style={{ fontSize: '13px' }}>
          {lista.podeMarcar ? `Marque o que já pegou. ${quem ?? 'Quem mandou'} vê na hora, sem precisar instalar nada.` : 'Você pode ver a lista; só quem mandou altera.'}
        </span>
      </section>

      {falhou && <p class="tracejado" role="alert">Não deu para marcar. Confira a internet e tente de novo.</p>}

      {lista.grupos().map((itens) => {
        const p = itens[0], m = mercado(p.rede_slug), feitos = itens.filter((i) => i.pego).length;
        return (
          <section class="grupo" key={p.rede_id ?? 'sem'}>
            <div class="grupo-topo" style={{ padding: '12px 16px', gap: '12px' }}>
              <span class="avatar" style={{ background: m.cor, width: '32px', height: '32px', fontSize: '12px' }}>{p.rede_id ? m.sigla : '?'}</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <h2 style={{ fontSize: '17px', lineHeight: '22px' }}>{p.rede_nome ?? 'Onde preferir'}</h2>
                <span class="suave">{feitos} de {itens.length} pegos</span>
              </div>
              {p.rede_nome && (
                <a class="botao" target="_blank" rel="noopener" aria-label={`Como chegar ao ${p.rede_nome}`}
                  href={`https://www.google.com/maps/search/${encodeURIComponent(`${p.rede_nome} Governador Valadares`)}`}>Como chegar</a>
              )}
            </div>
            {itens.map((i) => (
              <label class="grupo-item" key={i.id} style={{ minHeight: '56px', padding: '4px 16px', gap: '12px', fontSize: '15px', cursor: lista.podeMarcar ? 'pointer' : 'default' }}>
                <input type="checkbox" checked={i.pego} disabled={!lista.podeMarcar} onChange={(e) => marcar(i, e.currentTarget.checked)}
                  style={{ width: '22px', height: '22px', margin: 0, flex: 'none', accentColor: 'var(--verde)' }} />
                <span class={i.pego ? 'pego' : ''} style={{ fontWeight: 600, flex: 1, minWidth: 0 }}>{i.texto} <Vence fim={i.validade_fim} /></span>
                <strong class="suave">{i.quantidade}×</strong>
              </label>
            ))}
          </section>
        );
      })}

      {lista.podeMarcar && total > 0 && (
        <a class={`botao botao-grande ${faltando.length === 0 ? 'botao-cheio' : ''}`} target="_blank" rel="noopener"
          href={`https://wa.me/?text=${encodeURIComponent(mensagem)}`}>
          {faltando.length === 0 ? `Avisar ${quem ?? 'quem mandou'} que terminei` : `Avisar que terminei (${faltando.length} faltando)`}
        </a>
      )}

      <div class="tracejado" style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '12px' }}>
        <span style={{ flex: '1 1 240px' }}>Quer montar a sua lista com as ofertas de GV?</span>
        <a href="/" class="botao botao-claro">Ver ofertas de hoje</a>
      </div>
    </>
  );
}
