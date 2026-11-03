import { defineCollection } from 'astro:content';
import { glob } from 'astro/loaders';
import { z } from 'astro/zod';

// Toda fonte usada no artigo entra aqui: vira a seção "Fontes e créditos" automaticamente.
const source = z.object({
	title: z.string(),
	author: z.string(),
	url: z.url(),
	kind: z.enum(['paper', 'video', 'talk', 'post', 'docs', 'repo']),
	date: z.coerce.date().optional(),
});

const blog = defineCollection({
	loader: glob({ base: './src/content/blog', pattern: '**/*.{md,mdx}' }),
	schema: ({ image }) =>
		z.object({
			title: z.string(),
			description: z.string(),
			pubDate: z.coerce.date(),
			updatedDate: z.coerce.date().optional(),
			heroImage: z.optional(image()),
			tags: z.array(z.string()).default([]),
			series: z.string().optional(),
			draft: z.boolean().default(false),
			sources: z.array(source).default([]),
		}),
});

export const collections = { blog };
