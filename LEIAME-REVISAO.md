# CliniFlow – revisão

## O que mudou
**Velocidade**
- `@import` de fonte dentro do CSS (carrega em cadeia) → `<link>` com `preconnect` + `display=swap`.
- Font Awesome carrega sem bloquear a renderização.
- Favicon embutido (antes gerava uma requisição 404).
- Servidor: cache para estáticos, `no-cache` para HTML.

**Imagens**: o projeto não tem nenhuma imagem (logo e ícones são CSS/fonte). Nada a comprimir. Ao adicionar: WebP/AVIF, `width`/`height`, `loading="lazy"` abaixo da dobra.

**Celular**
- Campos com 16 px no celular (evita zoom automático do iOS); `inputmode`/`autocomplete` no telefone e nome.
- Cabeçalho só com ícones no celular (antes estourava a largura); métricas 2×2; alvos de toque maiores; toast em largura total; modal rolável; tabela com rolagem horizontal.

**Código sem repetição**
- Estilos repetidos (8 labels, 9 campos, cards) → classes `.label`, `.field`, `.card`, `.role-btn`, `.btn-sm`.
- Médicos, horários, status, papéis e métricas definidos uma vez e usados para gerar HTML e selects.
- 3 cópias do cálculo de cor de status → `badgeStatus()`; várias chamadas de `render*` → `refreshAll()`.
- `onclick` inline → um único listener (`data-action`).

**Bugs corrigidos**
- XSS: nome/motivo digitados eram inseridos com `innerHTML` (confirmado no original: `<img onerror>` executava). Agora tudo passa por `esc()`.
- Data padrão fixa em 2026-11-20 era menor que o `min` → formulário não enviava. Agora usa hoje/amanhã.
- `toISOString()` usa UTC e errava o dia à noite no Brasil → data local.
- Botões do simulador de WhatsApp agiam na primeira consulta da lista, não na exibida.
- `bg-brand-200` não existia no tema (badge sem fundo) → cor adicionada.
- `localStorage` com try/catch; `Esc` fecha o modal; `server.ps1` sem caminho fixo, bloqueia `../` e não cai com erro em uma requisição.

## Ainda recomendado (não foi possível aqui: sem internet)
O maior custo de carregamento é o **Tailwind CDN** (compila CSS no navegador, ~300 KB de JS, mostra página sem estilo por instantes) e o **Font Awesome completo** (~100 KB + fontes). Para produção:
```
npm i -D tailwindcss@3
npx tailwindcss init   # content: ["./index.html"] + cores brand do tailwind.config
npx tailwindcss -i entrada.css -o tailwind.css --minify
```
(`entrada.css` = `@tailwind base; @tailwind components; @tailwind utilities;` + o bloco `@layer components` do `index.html`.) Depois troque o `<script src="cdn.tailwindcss.com">` e o bloco `<style type="text/tailwindcss">` por `<link rel="stylesheet" href="tailwind.css">`. Para os ícones, use só os ~35 usados (SVG inline ou subset do Font Awesome).
