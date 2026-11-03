---
title: 'O RAG está reinventando o metadado (e alguém precisa ser dono disso)'
description: 'Anthropic, Jina e OpenAI atacaram o chunk sem contexto de três jeitos. Os três são problema de engenharia de dados, e quase ninguém trata assim.'
pubDate: '2026-11-03'
tags: [rag, contextual-retrieval, embeddings, databricks]
draft: false
sources:
  - title: 'Introducing Contextual Retrieval'
    author: 'Anthropic (Daniel Ford)'
    url: 'https://www.anthropic.com/research/contextual-retrieval'
    kind: post
    date: '2024-09-19'
  - title: 'Late Chunking: Contextual Chunk Embeddings Using Long-Context Embedding Models'
    author: 'Michael Günther, Isabelle Mohr, Daniel James Williams, Bo Wang, Han Xiao (Jina AI, Weaviate)'
    url: 'https://arxiv.org/abs/2409.04701'
    kind: paper
    date: '2024-09-07'
  - title: 'Retrieval'
    author: 'OpenAI'
    url: 'https://developers.openai.com/api/docs/guides/retrieval'
    kind: docs
  - title: 'File search'
    author: 'OpenAI'
    url: 'https://developers.openai.com/api/docs/guides/tools-file-search'
    kind: docs
---

Já vi um bot ligado direto em tabelas do Databricks responder errado com toda a confiança do mundo.
A pergunta era sobre os dados, os dados estavam lá, e a resposta saía errada mesmo assim.


O diagnóstico que todo mundo dá nessa hora é "o modelo alucinou". Troca o modelo, ajusta o prompt,
tenta de novo. Só que o modelo fez exatamente o que dava para fazer com o que recebeu: linhas sem
explicação. Ele não sabia o que cada coluna significava, qual regra de negócio valia, qual era o grão
da tabela. Recebeu dado sem contexto e devolveu uma resposta sem contexto.

Guarda essa cena, porque ela volta no final.

Em setembro de 2024, com 12 dias de diferença, a Jina AI e a Anthropic publicaram duas soluções para
uma versão desse mesmo problema, a versão em texto. A OpenAI não publicou estudo nenhum, mas o
`file_search` dela é o RAG que muita gente usa sem pensar no assunto. Li as três e saí com uma
conclusão que nenhuma delas escreve: o que essas empresas estão chamando de "contexto do chunk" é
metadado. E metadado sempre foi trabalho de quem cuida do dado.

## O chunk que esqueceu de onde veio

Todo RAG começa cortando documento em pedaços de algumas centenas de tokens. O corte é necessário,
porque ninguém cabe uma base inteira no prompt e a busca funciona melhor com trechos curtos. O preço
do corte quase ninguém paga de forma consciente.

O exemplo da Anthropic é o melhor que eu conheço. Um relatório financeiro da ACME é cortado e um dos
pedaços diz que "a receita cresceu 3% sobre o trimestre anterior". Qual empresa? Qual trimestre? O
pedaço não sabe. O nome da ACME e o "2º trimestre de 2023" estavam parágrafos acima, em outro chunk.
Quando alguém pergunta quanto a ACME cresceu no 2º trimestre de 2023, o vetor desse trecho não tem
nada de "ACME" nem de "2023" para casar com a pergunta. O trecho certo existe e não é encontrado.

A Anthropic resume assim: "traditional RAG solutions remove context when encoding information, which
often results in the system failing to retrieve the relevant information from the knowledge base."

Para quem vem de dados, isso tem nome antigo: é uma linha que perdeu a chave estrangeira. O valor está
lá, a referência que dava sentido a ele foi embora no corte.

## A Anthropic pagou um LLM para escrever metadado

A solução da Anthropic, o *contextual retrieval*, é direta. Na ingestão, para cada chunk, o Claude 3
Haiku recebe o documento inteiro mais o chunk e escreve um texto curto, normalmente de 50 a 100
tokens, situando aquele pedaço no documento. Algo como "trecho do relatório da ACME sobre o 2º
trimestre de 2023, seção de receita". Esse texto é colado na frente do chunk antes de gerar o
embedding e antes de montar o índice de palavras-chave BM25.

Os números, medidos como taxa de falha no top-20 (a fração de casos em que o trecho certo não aparece
entre os 20 primeiros), na média de quatro domínios: código, ficção, papers do arXiv e artigos
científicos.

| Configuração | Falha no top-20 | Redução |
|---|---|---|
| Embedding comum | 5,7% | base |
| Com contexto no embedding | 3,7% | 35% |
| + contexto no BM25 | 2,9% | 49% |
| + reranking (Cohere, de 150 para 20 chunks) | 1,9% | 67% |

O custo de gerar o contexto é de US$ 1,02 por milhão de tokens de documento, pago uma vez, com chunks
de 800 tokens e documentos de 8 mil. Fica barato por causa do *prompt caching*: o documento entra no
cache uma vez e é reaproveitado em todas as chamadas dos chunks dele.

Agora olha o que aquele texto de 50 a 100 tokens contém. Nome do documento, entidade, período, seção.
É ficha catalográfica escrita em linguagem natural por um LLM. A Anthropic chama de contexto. Eu chamo
de metadado gerado.

Um detalhe do post reforça isso. Eles testaram colar um resumo genérico do documento em cada chunk e o
ganho foi "muito limitado". O que funciona é o metadado *específico daquele chunk*: onde ele está e do
que ele fala. Qualquer pessoa que já desenhou uma dimensão sabe a diferença entre um atributo do
documento e um atributo da linha.

## A Jina escondeu o contexto dentro do vetor

A Jina chegou ao mesmo problema por outro caminho. Em vez de cortar o texto e depois gerar embeddings,
ela passa o documento inteiro por um modelo de embedding de contexto longo (8.192 tokens no
jina-embeddings-v2-small) e só depois corta. Cada token "viu" o documento todo na atenção do
transformer, então a média dos vetores de um trecho já carrega algo do resto do texto. Eles chamam de
*late chunking*, porque o corte acontece no fim. Documento maior que a janela do modelo é processado
em janelas com sobreposição.

Não tem LLM no caminho, e os autores fazem questão de dizer: "Late chunking requires no additional
training and is applicable to a wide range of embedding models."

O ganho é mais modesto, e o paper é honesto sobre isso. Em quatro datasets do benchmark BEIR, com três
modelos de embedding, o nDCG@10 médio sobe entre 1,5 e 1,9 pontos absolutos, conforme a estratégia de
corte. Ajuda mais com chunks pequenos. Com chunks grandes, em algumas tarefas de leitura, o corte
comum ganhou.


Aqui mora a diferença que importa para quem opera. O contexto da Anthropic é texto: dá para ler,
consultar, testar, versionar. O contexto da Jina é uma direção num espaço de centenas de dimensões.
Ninguém consegue abrir um vetor e conferir se ele "sabe" que aquele trecho é da ACME.

Para protótipo, isso não importa. Para um sistema em que alguém vai perguntar "por que a busca trouxe
esse documento e não aquele?", importa muito. Metadado que ninguém consegue ler também não dá para
auditar.

## A OpenAI escondeu o problema inteiro

O `file_search` da OpenAI é RAG gerenciado. Você sobe o arquivo num *vector store* e ele é cortado,
vetorizado e indexado sozinho. O corte padrão é de 800 tokens com 400 de sobreposição (configurável de
100 a 4.096). A busca pode combinar palavra-chave e semântica, tem reescrita de query, reranker e
filtro por atributos que você define.

Nas páginas de documentação que li não há nada sobre dar contexto ao chunk, nem sobre qual modelo de
embedding indexa seus arquivos. O que fica com você: tamanho do corte, até 16 atributos de metadado
por arquivo e os parâmetros de busca.


Repara que o único lugar onde a OpenAI te deixa pôr contexto é justamente o metadado. Ela não resolve
o chunk sem contexto, ela te entrega o campo para você resolver. Se ninguém do seu lado preencher
esses atributos com cuidado, o problema continua lá, só que dentro de uma caixa que você não abre.

## Três respostas, nenhum placar

| | Anthropic | Jina | OpenAI |
|---|---|---|---|
| Onde o contexto mora | texto gerado, colado no chunk | dentro do vetor | nos atributos que você preencher |
| Dá para ler e auditar? | sim | não | só o que você preencheu |
| Custo extra na ingestão | 1 chamada de LLM por chunk, com cache | 1 passada do documento inteiro | incluso; armazenamento acima de 1 GB a US$ 0,10/GB/dia |
| Ajuda a busca por palavra-chave? | sim | não | sem contexto, não |
| Métrica publicada | falha no top-20 | nDCG@10 | nenhuma |

As métricas são diferentes, então não existe placar entre as três, e desconfio de quem montar um. Dá
para comparar o desenho: onde o contexto mora e quanto custa mantê-lo certo.

E manter certo é onde o assunto vira engenharia de dados.

## Contexto tem raio de reprocessamento

Num RAG sem contexto, mudou um parágrafo, você refaz o embedding daquele chunk. Com contextual
retrieval, o texto de cada chunk foi escrito lendo o documento inteiro. Mudou uma tabela na página 3?
O contexto do chunk da página 7 pode ter ficado errado. O seguro é refazer o documento todo: uma
chamada de LLM e um embedding por chunk.

O late chunking tem o mesmo raio, porque também precisa passar o documento inteiro de novo, só que sem
a conta do LLM. No `file_search` você reenvia o arquivo e torce. A própria doc avisa que a remoção é
*eventually consistent*: por um tempo, a busca pode devolver conteúdo do arquivo que você apagou.

A boa notícia é que o raio é o documento, não o índice, desde que o pipeline seja incremental. A
infraestrutura existe: no Databricks, o Delta Sync Index do Vector Search sincroniza a partir do Change
Data Feed da tabela Delta. O trabalho é decidir quais documentos voltam para a contextualização. Um hash
do conteúdo resolve, junto com a versão do prompt que gera o contexto:

```sql
WITH documentos_atuais AS (
  SELECT
    doc_id,
    SHA2(content, 256) AS content_hash
  FROM docs_silver.documents__current
)
SELECT DISTINCT d.doc_id
FROM documentos_atuais AS d
LEFT JOIN rag_silver.chunks__contextualized AS c
  ON d.doc_id = c.doc_id
WHERE c.doc_id IS NULL
   OR c.content_hash <> d.content_hash
   OR c.context_prompt_version <> 'v2'
```

Documento novo, documento alterado ou prompt novo voltam para a fila. Documento removido precisa de um
passo à parte, que apaga os chunks dele.

Agora a parte que dói. Dois eventos derrubam o índice inteiro: trocar o modelo de embedding (vale para
as três abordagens) e trocar o prompt de contextualização (no caso da Anthropic). Isso quer dizer que
aquele prompt de quatro linhas faz parte do schema do índice. Quem edita o prompt sem versionar está
fazendo `ALTER TABLE` em produção sem migração.

## Contexto gerado é coluna derivada sem teste

O texto que o LLM escreve para cada chunk fica gravado e vai para a busca. Se ele erra, trocando o
trimestre ou atribuindo o número à empresa errada, o erro entra no índice e ninguém vê, porque ninguém
lê contexto de chunk.

Em qualquer camada Silver, uma coluna derivada sem teste seria barrada no review. Aqui ela entra direto
no caminho da resposta. O mínimo:

- guardar o contexto separado do chunk original, nunca só a versão concatenada;
- guardar qual modelo e qual versão do prompt geraram cada contexto;
- checar por amostragem se o contexto bate com o documento, mesmo que seja um LLM-as-judge calibrado
  contra algumas dezenas de casos revisados por gente.

A própria Anthropic sugere separar o que é contexto do que é chunk na hora de gerar a resposta. Para
isso, você precisa ter guardado os dois separados.


E antes de pagar LLM por chunk, vale testar o óbvio: colar no chunk o título do documento e o caminho
de seções que você já tem no parser. Pode ser que boa parte do ganho esteja no metadado que já existe
e ninguém aproveitou. Não vi esse teste feito contra o contextual retrieval nas fontes que li, então
fica como hipótese.

## A tabela também esqueceu de onde veio

Volta ao bot do começo.

A tentação, quando um bot erra sobre dado tabular, é dizer que faltou RAG: vetorizar as linhas e
plugar um vector search. Isso piora o problema. Vector search devolve trechos parecidos com a pergunta.
Ele não soma, não filtra período, não faz join. Pergunta a receita de março e o modelo recebe vinte
linhas "parecidas" para inventar um total.

O bot e o chunk da ACME têm a mesma doença. Nos dois casos, o dado chegou ao modelo sem o que dava
sentido a ele. A diferença é o remédio. No texto, o contexto é a frase que diz de onde o trecho veio.
Na tabela, o contexto é descrição de coluna no catálogo, regra de negócio escrita, métrica definida uma
vez numa camada semântica (as *metric views* do Unity Catalog, por exemplo) e o modelo gerando SQL em
cima disso. O vector search fica para o que é texto de verdade: documentação, política, dicionário de
dados.

Contextual retrieval resolve uma parte do problema de contexto. O resto é catálogo, semântica e
governança, coisas que a engenharia de dados faz há muito tempo, só que para humanos lerem.

## O que esses números não provam

**Recuperar não é responder.** Os 35%, 49% e 67% da Anthropic medem se o trecho certo apareceu entre
os 20 primeiros. O post não mostra quanto a resposta final melhorou, e o eval não é aberto: não há
tamanho de amostra nem variância publicados. Medir recuperação separado da resposta é boa prática,
porque mostra onde está a falha, e se o trecho certo não chega, nenhum prompt salva. Mas o número da
manchete não é o que o usuário sente. Para quem é cobrado pela resposta errada, a qualidade da resposta
pesa mais, e essa metade do eval ficou de fora.


**A comparação entre as duas técnicas não existe.** O paper da Jina coloca as duas lado a lado em um
documento fictício e uma pergunta, e os resultados ficam parecidos. Isso ilustra a ideia, mas não
sustenta conclusão. A pergunta que decide arquitetura continua aberta: o late chunking chega perto do
contextual retrieval por uma fração do custo?

**Ninguém mediu o custo de manter.** Os três falam de custo de indexar. Nenhum fala de quanto custa
manter o índice certo ao longo de um mês de documentos mudando, que é o custo que aparece na fatura de
verdade.

## Metadado sempre foi nosso

Boa parte da conversa sobre RAG gira em torno de qual modelo é mais inteligente, qual embedding é
melhor e quantos chunks colocar no prompt. Enquanto isso, a Anthropic cortou quase metade das falhas de
busca, antes de qualquer reranking, fazendo uma coisa só: escrevendo em cada pedaço de dado de onde ele
veio.

Isso tem nome. É metadado, e catálogo, lineage e dicionário de dados existem para isso. A diferença é
que agora quem lê o metadado é um modelo, e um modelo sem metadado responde errado com a mesma
confiança de quando acerta.

O bot do começo não precisava de um modelo melhor. Precisava de alguém que tratasse o contexto como
dado: com dono, versão, teste e SLA.

O próximo erro do seu RAG provavelmente não vai estar no modelo. Vai estar num dado sem contexto que
ninguém versionou.
