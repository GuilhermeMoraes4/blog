import { getCollection } from 'astro:content';

// Rascunhos aparecem no `npm run dev`, mas nunca entram no build de produção.
export async function getPosts() {
	const posts = await getCollection('blog', ({ data }) => !import.meta.env.PROD || !data.draft);
	return posts.sort((a, b) => b.data.pubDate.valueOf() - a.data.pubDate.valueOf());
}
