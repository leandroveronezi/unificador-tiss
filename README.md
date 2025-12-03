# Manual: Gerar Unit TISS (Método de Substituição de Includes)

Este método consiste em abrir o arquivo principal e, linha por linha, substituir os comandos de `include` pelo conteúdo real dos arquivos referenciados.

## Passo 1: Preparação

Tenha na mesma pasta os 4 arquivos da versão (ex: 4.02.00) e também o `tissAssinaturaDigital_v1.01.xsd` e `xmldsig-core-schema.xsd`.

## Passo 2: O Arquivo Principal

1.  Abra o arquivo principal (ex: `tissV4_02_00.xsd`) no seu editor de texto (Notepad++, VSCode).
2.  Salve-o imediatamente como `UtissV4.02.00.xsd`.
3.  Localize o bloco de includes no topo. Deve se parecer com isso:

```xml
<import namespace="..." schemaLocation="xmldsig-core-schema.xsd"/>
<include schemaLocation="tissSimpleTypesV4_02_00.xsd"/>
<include schemaLocation="tissComplexTypesV4_02_00.xsd"/>
<include schemaLocation="tissGuiasV4_02_00.xsd"/>
```

## Passo 3: Substituir o `SimpleTypes`

1.  Abra o arquivo `tissSimpleTypesV4_02_00.xsd`.
2.  **Não dê "Select All"**. Selecione apenas o conteúdo **entre** as tags `<schema ...>` e `</schema>`.
    - _Dica:_ Começa na primeira tag `<simpleType...` e vai até o final, antes da última linha `</schema>`.
3.  Copie esse conteúdo.
4.  Volte para o `UtissV4.02.00.xsd`.
5.  Selecione a linha `<include schemaLocation="tissSimpleTypesV4_02_00.xsd"/>`.
6.  **Cole** o conteúdo copiado por cima dessa linha (apagando a linha de include e colocando o código no lugar).

## Passo 4: Substituir o `ComplexTypes`

1.  Abra o arquivo `tissComplexTypesV4_02_00.xsd`.
2.  Verifique se no topo dele existem linhas de `<include ...>`. Se houver, **apague essas linhas** (pois elas geralmente chamam o SimpleTypes, que você já colou no passo anterior).
3.  Selecione o conteúdo útil (entre `<schema...>` e `</schema>`).
4.  Copie.
5.  Volte para o `UtissV4.02.00.xsd`.
6.  Selecione a linha `<include schemaLocation="tissComplexTypesV4_02_00.xsd"/>`.
7.  **Cole** o conteúdo copiado por cima dessa linha.

## Passo 5: Substituir o `Guias`

1.  Abra o arquivo `tissGuiasV4_02_00.xsd`.
2.  Apague as linhas de `<include ...>` do topo deste arquivo (elas chamam SimpleTypes, ComplexTypes e Assinatura, que já estão ou estarão no arquivo principal).
3.  Selecione o conteúdo útil (entre `<schema...>` e `</schema>`).
4.  Copie.
5.  Volte para o `UtissV4.02.00.xsd`.
6.  Selecione a linha `<include schemaLocation="tissGuiasV4_02_00.xsd"/>`.
7.  **Cole** o conteúdo copiado por cima dessa linha.

## Passo 6: Ajuste da Assinatura Digital

1.  No arquivo `UtissV4.02.00.xsd`, verifique o topo.
2.  A linha `<include schemaLocation="tissAssinaturaDigital_v1.01.xsd"/>` **DEVE PERMANECER**. Não a substitua. O Delphi consegue ler esse arquivo externo se ele estiver na mesma pasta.
3.  A linha `<import ... schemaLocation="xmldsig-core-schema.xsd"/>` também deve permanecer.

## Passo 7: Salvar e Gerar

1.  Salve o arquivo `UtissV4.02.00.xsd`.
2.  No Delphi, use o **XML Data Binding Wizard**.
3.  Aponte para o arquivo `Utiss` criado.
4.  O Wizard deve carregar a estrutura corretamente. Selecione `mensagemTISS` como elemento raiz e gere a Unit.

---

### Resumo das regras para não errar manualmentes:

1.  Nunca cole as linhas `<?xml ...>` ou `<schema ...>` ou `</schema>` dentro do arquivo principal. Copie apenas o "recheio".
2.  Delete os `include` dos arquivos secundários antes de copiar, para não criar referências circulares ou duplicadas.
3.  Mantenha o `include` da assinatura digital intacto no topo do arquivo principal.
