/* On-page + terminology crawler (browser console)
 *
 * Runs in the browser console ON THE SITE'S OWN ORIGIN (same-origin fetch).
 * Open https://<your-site>/, paste this file, run.
 * Reads from the live DOM, not a markdown conversion, so <head> findings are real.
 * For 100+ page sitemaps, run in slices: a single call over ~45 s will time out.
 *
 * Before each run, refresh DEPRECATED from brand/glossary.md (banned / deprecated terms and the
 * canonical replacement). Deprecated terms on indexed pages are an SEO problem and a brand problem at once.
 */

const SITEMAP = location.origin + '/page-sitemap.xml';   // or '/sitemap.xml' - any urlset sitemap

// Deprecated terms, copied from brand/glossary.md. Re-check each month: the glossary moves.
const DEPRECATED = [
  { term: '<OLD_PRODUCT_NAME>', canonical: '<CURRENT_PRODUCT_NAME>' },
  { term: '<RETIRED_FEATURE_NAME>', canonical: '<NEW_FEATURE_NAME>' },
];

async function auditPage(u) {
  try {
    const r = await fetch(u);
    const d = new DOMParser().parseFromString(await r.text(), 'text/html');
    const q = s => d.querySelector(s);
    const md = q('meta[name="description"]'), can = q('link[rel="canonical"]'), rob = q('meta[name="robots"]');
    const imgs = [...d.querySelectorAll('img')];
    const txt = (d.body ? d.body.textContent : '') || '';
    const head = (d.title || '') + ' ' + (md ? md.content : '');
    const ld = [...d.querySelectorAll('script[type="application/ld+json"]')].map(s => {
      try { const j = JSON.parse(s.textContent); return (Array.isArray(j) ? j : [j]).map(x => x['@type'] || (x['@graph'] || []).map(y => y['@type'])).flat(); }
      catch (e) { return null; }
    }).flat().filter(Boolean);
    const esc = t => t.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

    return {
      url: u, status: r.status,
      title: d.title || '', tLen: (d.title || '').length,
      desc: md ? md.content : null, dLen: md ? md.content.length : 0,
      canon: can ? can.href : null,
      canonSelf: can ? can.href.replace(/\/$/, '') === u.replace(/\/$/, '') : null,
      noindex: /noindex/i.test(rob ? rob.content : ''),
      h1: d.querySelectorAll('h1').length,
      h1text: (d.querySelector('h1') || {}).textContent?.trim().slice(0, 80) || '',
      imgs: imgs.length,
      noAlt: imgs.filter(i => !i.getAttribute('alt') || !i.getAttribute('alt').trim()).length,
      schema: [...new Set(ld)].join('|'),
      deprecated: DEPRECATED.filter(x => new RegExp(esc(x.term), 'i').test(txt)).map(x => x.term),
      deprecatedInHead: DEPRECATED.filter(x => new RegExp(esc(x.term), 'i').test(head)).map(x => x.term),
      words: txt.split(/\s+/).filter(Boolean).length,
    };
  } catch (e) { return { url: u, error: String(e).slice(0, 80) }; }
}

async function crawl(from = 0, to = 45) {
  const xml = await fetch(SITEMAP).then(r => r.text());
  const urls = [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map(m => m[1]);
  window.__res = window.__res || [];
  const slice = urls.slice(from, to), B = 6;
  for (let i = 0; i < slice.length; i += B) {
    window.__res.push(...await Promise.all(slice.slice(i, i + B).map(auditPage)));
  }
  return { done: window.__res.length, ofTotal: urls.length };
}

function summarize() {
  const out = window.__res, ti = out.reduce((s, r) => s + (r.imgs || 0), 0), tn = out.reduce((s, r) => s + (r.noAlt || 0), 0);
  return {
    audited: out.length, altMissing: tn, altTotal: ti, altPct: ti ? Math.round(tn / ti * 100) : 0,
    counts: {
      errors: out.filter(r => r.error).length,
      noH1: out.filter(r => r.h1 === 0).length,
      multiH1: out.filter(r => r.h1 > 1).length,
      noDesc: out.filter(r => r.dLen === 0).length,
      longDesc: out.filter(r => r.dLen > 160).length,
      longTitle: out.filter(r => r.tLen > 60).length,
      canonMismatch: out.filter(r => r.canonSelf === false).length,
      noindex: out.filter(r => r.noindex).length,
      deprecatedInHead: out.filter(r => r.deprecatedInHead?.length).length,
    },
    noH1: out.filter(r => r.h1 === 0).map(r => r.url),
    multiH1: out.filter(r => r.h1 > 1).map(r => ({ u: r.url, n: r.h1 })),
    noDesc: out.filter(r => r.dLen === 0).map(r => r.url),
    canonMismatch: out.filter(r => r.canonSelf === false).map(r => ({ u: r.url, c: r.canon })),
    deprecated: out.filter(r => r.deprecatedInHead?.length).map(r => ({ u: r.url, t: r.deprecatedInHead })),
    worstAlt: out.filter(r => r.imgs > 10).sort((a, b) => b.noAlt - a.noAlt).slice(0, 10).map(r => `${r.url} ${r.noAlt}/${r.imgs}`),
  };
}

// Usage:
//   await crawl(0, 45);                                            // a small site, one pass
//   await crawl(0, 42); await crawl(42, 84); await crawl(84, 125); // ~125 pages, three passes
//   summarize();
//   copy(JSON.stringify(window.__res));   // paste into seo/reports/<YYYY-MM>/crawl-<site>.json
