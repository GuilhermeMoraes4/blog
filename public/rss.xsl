<?xml version="1.0" encoding="UTF-8"?>
<!-- Deixa o feed legível quando aberto no navegador; leitores de RSS ignoram este arquivo. -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
	<xsl:output method="html" encoding="UTF-8" indent="yes" />
	<xsl:template match="/">
		<html lang="pt-BR">
			<head>
				<meta charset="utf-8" />
				<meta name="viewport" content="width=device-width,initial-scale=1" />
				<title>RSS | <xsl:value-of select="/rss/channel/title" /></title>
				<style>
					body { max-width: 68ch; margin: 3rem auto; padding: 0 1rem; font-family: Georgia, serif; line-height: 1.6; color: #1c1c1c; background: #faf8f3; }
					.box { padding: 1rem 1.25rem; border: 1px solid #e2ddd3; border-radius: 8px; background: #fff; font-family: system-ui, sans-serif; font-size: 0.95rem; }
					code { background: #f1ede4; padding: 0.1rem 0.35rem; border-radius: 4px; }
					a { color: #0f5c63; }
					li { margin-bottom: 1.25rem; }
					time { display: block; color: #6b6b6b; font-size: 0.85rem; font-family: system-ui, sans-serif; }
				</style>
			</head>
			<body>
				<div class="box">
					<strong>Este é o feed RSS do blog.</strong> Copie a URL desta página
					(<code>https://datawithguilherme.pages.dev/rss.xml</code>) e cole no seu leitor
					de RSS (Feedly, Inoreader, NetNewsWire...) para receber os artigos novos.
				</div>
				<h1><xsl:value-of select="/rss/channel/title" /></h1>
				<p><xsl:value-of select="/rss/channel/description" /></p>
				<xsl:choose>
					<xsl:when test="count(/rss/channel/item) = 0">
						<p><em>Nenhum artigo publicado ainda.</em></p>
					</xsl:when>
					<xsl:otherwise>
						<ul>
							<xsl:for-each select="/rss/channel/item">
								<li>
									<time><xsl:value-of select="pubDate" /></time>
									<a href="{link}"><xsl:value-of select="title" /></a>
									<div><xsl:value-of select="description" /></div>
								</li>
							</xsl:for-each>
						</ul>
					</xsl:otherwise>
				</xsl:choose>
				<p><a href="/">Voltar ao blog</a></p>
			</body>
		</html>
	</xsl:template>
</xsl:stylesheet>
