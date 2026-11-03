# Data with Guilherme

Personal blog about data and AI, written in Brazilian Portuguese: papers, talks and engineering
posts read by a data engineer, always crediting the original sources.

Live at <https://datawithguilherme.pages.dev>. Built with [Astro](https://astro.build), based on
the official blog starter (itself based on [Bear Blog](https://github.com/HermanMartinus/bearblog/)).

## Writing a post

1. Copy `templates/artigo.md` to `src/content/blog/<slug>.md`.
2. Fill the frontmatter. Every source goes in `sources`: it renders the "Fontes e créditos"
   section automatically.
3. Keep `draft: true` while writing. Drafts show up in `npm run dev` and never in the production build.

## Commands

| Command           | Action                                   |
| :---------------- | :--------------------------------------- |
| `npm install`     | Install dependencies                     |
| `npm run dev`     | Dev server at `localhost:4321`           |
| `npm run build`   | Production build to `./dist/`            |
| `npm run preview` | Preview the production build locally     |

## Deploy

Cloudflare Pages (free tier) connected to this repo: build command `npm run build`, output `dist`.
