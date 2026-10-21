// Lista de compras sem login (migration 9; mesmas regras de app/lib/features/lista/lista.dart).
// Quem tem o código tem acesso: o de dono fica neste navegador; os de "marcar"/"ver" vão no link.
import { rpc } from './api';
import { supabaseUrl, supabaseChave } from './config';

export interface Item {
  id: number; texto: string; quantidade: number; pego: boolean;
  oferta_id: number | null; rede_id: number | null; rede_nome: string | null; rede_slug: string | null; validade_fim: string | null;
}
interface Lida {
  id: string; permissao: 'dono' | 'marcar' | 'ver'; nome_dono: string | null; atualizado_em: string;
  codigos?: { marcar: string; ver: string }; itens: Item[];
}

const CHAVE = 'lista_codigo_dono';
const guardado = () => { try { return localStorage.getItem(CHAVE); } catch { return null; } };
const guardar = (c: string | null) => { try { c ? localStorage.setItem(CHAVE, c) : localStorage.removeItem(CHAVE); } catch { /* navegador sem storage: a lista vale só nesta aba */ } };

export class Lista {
  lida: Lida | null = null;
  erro = false;
  private ouvintes = new Set<() => void>();
  private canal: { unsubscribe(): unknown } | null = null;

  private constructor(private codigo: string | null, private readonly doNavegador: boolean) {}

  /** A lista deste navegador; nasce no primeiro "Adicionar". */
  static minha = () => (daqui ??= new Lista(guardado(), true));
  /** A lista de um link /l/<código>. */
  static recebida = (codigo: string) => new Lista(codigo, false);

  get itens() { return this.lida?.itens ?? []; }
  get podeMarcar() { return !this.lida || this.lida.permissao !== 'ver'; }
  itemDaOferta = (ofertaId: number) => this.itens.find((i) => i.oferta_id === ofertaId);

  ouvir(f: () => void) { this.ouvintes.add(f); return () => { this.ouvintes.delete(f); }; }
  private avisar() { this.ouvintes.forEach((f) => f()); }

  async carregar() {
    if (!this.codigo) return this.avisar();
    try {
      this.lida = await rpc<Lida>('lista_ler', { codigo: this.codigo });
      this.erro = false;
      this.tempoReal();
    } catch (e) {
      this.erro = true;
      // Lista apagada no servidor: some da tela; a deste navegador recomeça no próximo "Adicionar".
      if (String(e).includes('não encontrada')) {
        this.lida = null;
        if (this.doNavegador) { this.codigo = null; guardar(null); }
      }
    }
    this.avisar();
  }

  /** O banco avisa "mudou" no canal da lista (trigger da migration 9); recarregamos. */
  private async tempoReal() {
    if (this.canal || !this.lida) return;
    const id = this.lida.id;
    this.canal = { unsubscribe() {} }; // reserva: evita abrir dois canais enquanto a biblioteca carrega
    const { createClient } = await import('@supabase/supabase-js');
    this.canal = createClient(supabaseUrl, supabaseChave)
      .channel(`lista-${id}`).on('broadcast', { event: 'mudou' }, () => this.recarregarLogo()).subscribe();
  }

  // O canal é público (quem tem o link sabe o id): no máximo uma leitura por segundo, mesmo com rajada de avisos.
  private espera: ReturnType<typeof setTimeout> | null = null;
  private recarregarLogo() {
    if (this.espera) return;
    this.espera = setTimeout(() => { this.espera = null; this.carregar(); }, 1000);
  }

  private async chamar(funcao: string, args: Record<string, unknown>) {
    if (!this.codigo) {
      const c = await rpc<{ dono: string }>('lista_criar');
      this.codigo = c.dono;
      if (this.doNavegador) guardar(c.dono);
    }
    await rpc(funcao, { codigo: this.codigo, ...args });
    await this.carregar();
  }

  /** A oferta vai para o grupo do mercado dela; a mesma oferta de novo soma 1. */
  adicionar = (ofertaId: number, texto: string) => this.chamar('lista_adicionar', { oferta_id: ofertaId, texto, quantidade: 1 });
  /** 0 tira da lista. */
  quantidade = (item: Item, q: number) => this.chamar('lista_quantidade', { item_id: item.id, quantidade: q });
  marcar = (item: Item, pego: boolean) => this.chamar('lista_marcar', { item_id: item.id, pego });
  nomear = (nome: string) => this.chamar('lista_nomear', { nome_dono: nome });

  /** Apaga a lista inteira no banco (só o dono; migration 10) e esquece o código neste navegador. */
  async apagar() {
    if (!this.codigo) return;
    await rpc('lista_apagar', { codigo: this.codigo });
    this.canal?.unsubscribe();
    this.canal = null;
    this.codigo = null;
    this.lida = null;
    if (this.doNavegador) guardar(null);
    this.avisar();
  }

  /** Grupos por mercado, na ordem em que aparecem; itens sem mercado no fim. */
  grupos() {
    const g = new Map<number | null, Item[]>();
    for (const i of this.itens) g.set(i.rede_id, [...(g.get(i.rede_id) ?? []), i]);
    return [...g.entries()].sort(([a], [b]) => (a === null ? 1 : b === null ? -1 : 0)).map(([, itens]) => itens);
  }
}

let daqui: Lista | undefined; // a lista deste navegador (uma por página)
