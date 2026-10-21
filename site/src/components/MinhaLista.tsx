// "Minha lista" ao lado das ofertas (protótipo Web-Inicio): grupos por mercado + compartilhar.
import { useState } from 'preact/hooks';
import { Lista } from '../lib/lista';
import { mercado } from '../lib/formato';
import { usarLista } from './usarLista';
import Vence from './Vence';

export default function MinhaLista() {
  const lista = usarLista(Lista.minha());
  const [aberto, setAberto] = useState(false);
  const [copiado, setCopiado] = useState(false);
  const grupos = lista.grupos();
  const mercados = grupos.filter((g) => g[0].rede_id != null).length;
  const n = lista.itens.length;
  const codigos = lista.lida?.codigos;
  const link = codigos ? `${location.origin}/l/${codigos.marcar}` : '';
  const nome = lista.lida?.nome_dono ?? '';

  async function apagar() {
    if (!confirm('Apagar a lista inteira? Quem recebeu o link também deixa de ver. Não dá para desfazer.')) return;
    try { await lista.apagar(); setAberto(false); } catch { alert('Não deu para apagar agora. Confira a internet e tente de novo.'); }
  }

  async function copiar() {
    try { await navigator.clipboard.writeText(link); setCopiado(true); } catch { setCopiado(false); }
  }

  return (
    <aside id="lista" class="lista" aria-labelledby="lista-titulo">
      <div class="lista-topo">
        <div>
          <h2 id="lista-titulo">Minha lista</h2>
          <span class="suave">{n === 0 ? 'Nada ainda' : `${n} ${n === 1 ? 'item' : 'itens'}${mercados ? ` em ${mercados} ${mercados === 1 ? 'mercado' : 'mercados'}` : ''}`}</span>
        </div>
        {n > 0 && codigos && (
          <button type="button" class="botao botao-cheio" aria-expanded={aberto} onClick={() => { setAberto(!aberto); setCopiado(false); }}>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><circle cx="18" cy="5" r="3" /><circle cx="6" cy="12" r="3" /><circle cx="18" cy="19" r="3" /><path d="m8.6 13.5 6.8 4M15.4 6.5l-6.8 4" /></svg>
            Compartilhar
          </button>
        )}
      </div>

      {aberto && codigos && (
        <div class="compartilhar">
          <strong>Sempre o mesmo link, sempre atualizado</strong>
          <label class="campo">
            <span class="so-leitor">Seu nome</span>
            <input placeholder="Seu nome (aparece para quem recebe)" maxLength={40} value={nome}
              onBlur={(e) => { const v = e.currentTarget.value.trim(); if (v && v !== nome) lista.nomear(v); }} />
          </label>
          <div class="campo">
            <span style={{ flex: 1, minWidth: 0, fontSize: '13px', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{link}</span>
            <button type="button" class="botao" style={{ border: 0 }} onClick={copiar}>{copiado ? 'Copiado' : 'Copiar'}</button>
          </div>
          <a class="botao botao-cheio" target="_blank" rel="noopener"
            href={`https://wa.me/?text=${encodeURIComponent(`Minha lista de compras: ${link}`)}`}>Enviar pelo WhatsApp</a>
          <span style={{ fontSize: '13px' }}>Quem abrir o link marca o que já pegou, e você vê aqui na hora.</span>
        </div>
      )}

      {n === 0 && <p class="tracejado" style={{ margin: 0 }}>Toque em <strong>Adicionar</strong> nas ofertas para montar sua lista.</p>}

      {grupos.map((itens) => {
        const p = itens[0];
        return (
          <div class="grupo" key={p.rede_id ?? 'sem'}>
            <div class="grupo-topo">
              <span class="ponto" style={{ background: mercado(p.rede_slug).cor, width: '10px', height: '10px' }} />
              <strong>{p.rede_nome ?? 'Onde preferir'}</strong>
              <span class="suave">{itens.length} {itens.length === 1 ? 'item' : 'itens'}</span>
            </div>
            {itens.map((i) => (
              <div class="grupo-item" key={i.id}>
                <span class={i.pego ? 'pego' : ''}>{i.texto} <Vence fim={i.validade_fim} /></span>
                <strong>{i.quantidade}×</strong>
              </div>
            ))}
          </div>
        );
      })}

      {n > 0 && (
        <div class="tracejado suave" style={{ display: 'flex', flexWrap: 'wrap', alignItems: 'center', gap: '8px' }}>
          <span style={{ flex: '1 1 160px' }}>Sua lista fica salva neste navegador.</span>
          <button type="button" class="botao" style={{ color: '#B3261E', borderColor: '#B3261E' }} onClick={apagar}>Apagar minha lista</button>
        </div>
      )}
    </aside>
  );
}
