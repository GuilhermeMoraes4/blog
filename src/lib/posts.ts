import { type CollectionEntry, getCollection } from 'astro:content';

type Post = CollectionEntry<'blog'>;

// Rascunhos aparecem no `npm run dev`, mas nunca entram no build de produção.
export async function getPosts() {
	const posts = await getCollection('blog', ({ data }) => !import.meta.env.PROD || !data.draft);
	return posts.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}

export function readingTime(post: Post) {
	const words = (post.body ?? '').split(/\s+/).filter(Boolean).length;
	return Math.max(1, Math.round(words / 220));
}

export function groupByMonth(posts: Post[]) {
	const groups = new Map<string, { label: string; posts: Post[] }>();
	for (const post of posts) {
		const d = post.data.pubDate;
		const key = `${d.getUTCFullYear()}-${d.getUTCMonth()}`;
		if (!groups.has(key)) {
			const label = d.toLocaleDateString('pt-BR', { month: 'long', year: 'numeric', timeZone: 'UTC' });
			groups.set(key, { label, posts: [] });
		}
		groups.get(key)!.posts.push(post);
	}
	return [...groups.values()];
}

export function relatedPosts(post: Post, all: Post[], limit = 3) {
	return all
		.filter((p) => p.id !== post.id)
		.map((p) => ({ p, score: p.data.tags.filter((t) => post.data.tags.includes(t)).length }))
		.filter(({ score }) => score > 0)
		.sort((a, b) => b.score - a.score || b.p.data.pubDate.valueOf() - a.p.data.pubDate.valueOf())
		.slice(0, limit)
		.map(({ p }) => p);
}
