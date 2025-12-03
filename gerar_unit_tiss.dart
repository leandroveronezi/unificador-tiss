import 'dart:convert';
import 'dart:io';

void main() async {
  // --- CONFIGURAÇÃO ---
  // Altere para a versão exata dos seus arquivos
  const versaoUnderline = '4_02_00';

  const diretorioArquivos = './xsds';
  // --------------------

  final versaoPonto = versaoUnderline.replaceAll('_', '.');

  // Nomes dos arquivos de ENTRADA
  final arquivoPrincipal = 'tissV$versaoUnderline.xsd';
  final arquivoSimple = 'tissSimpleTypesV$versaoUnderline.xsd';
  final arquivoComplex = 'tissComplexTypesV$versaoUnderline.xsd';
  final arquivoGuias = 'tissGuiasV$versaoUnderline.xsd';

  // Arquivo de SAÍDA
  final arquivoSaida = 'UtissV$versaoPonto.xsd';

  try {
    print('--- Gerando Unit TISS Unificada (Base: $arquivoPrincipal) ---');

    final dir = Directory(diretorioArquivos);
    if (!await dir.exists()) {
      print('Erro: Pasta "$diretorioArquivos" não encontrada.');
      return;
    }

    final bufferFinal = StringBuffer();

    // ----------------------------------------------------------------
    // 1. CAPTURAR O CABEÇALHO (Namespace e Schema Attributes)
    // ----------------------------------------------------------------
    // O arquivo principal dita as regras de namespace (xmlns:ans, targetNamespace, etc)
    print('Lendo cabeçalho de: $arquivoPrincipal');
    final linesPrincipal = await lerArquivo(diretorioArquivos, arquivoPrincipal);

    String cabecalhoSchema = "";
    String prefixoSchema = ""; // pode ser vazio, "xs:", "xsd:", etc.

    // Regex para achar <schema ou <xs:schema ou <xsd:schema
    final regexSchemaOpen = RegExp(r'<([a-zA-Z0-9]+:)?schema\s+');

    for (var linha in linesPrincipal) {
      if (regexSchemaOpen.hasMatch(linha)) {
        cabecalhoSchema = linha;
        // Tenta descobrir o prefixo usado (ex: "xs:")
        final match = regexSchemaOpen.firstMatch(linha);
        prefixoSchema = match?.group(1) ?? ""; // Se for null, vira ""
        break;
      }
    }

    if (cabecalhoSchema.isEmpty) {
      // Fallback: se o regex falhar, tenta achar simples
      if (linesPrincipal.any((l) => l.contains('<schema'))) {
        cabecalhoSchema = linesPrincipal.firstWhere((l) => l.contains('<schema'));
      } else {
        throw Exception('Não foi possível encontrar a tag de abertura do Schema no arquivo principal.');
      }
    }

    // Escreve o XML e o cabeçalho do Schema detectado
    bufferFinal.writeln('<?xml version="1.0" encoding="ISO-8859-1"?>');
    bufferFinal.writeln(cabecalhoSchema);

    // ----------------------------------------------------------------
    // 2. IMPORTAR ASSINATURA (Fixo no topo)
    // ----------------------------------------------------------------
    // Independente de onde esteja nos arquivos originais, colocamos aqui.
    // Usamos o prefixo detectado (ex: <xs:include> ou <include>)
    bufferFinal.writeln('<${prefixoSchema}include schemaLocation="tissAssinaturaDigital_v1.01.xsd"/>');

    // Se o arquivo principal tiver um IMPORT (ex: xmldsig), precisamos mantê-lo.
    // Vamos varrer o principal rapidinho pra ver se tem <import> de namespace externo
    for (var l in linesPrincipal) {
      if (l.trim().startsWith('<${prefixoSchema}import') || l.trim().startsWith('<import')) {
        bufferFinal.writeln(l);
      }
    }

    // ----------------------------------------------------------------
    // 3. INJETAR CONTEÚDOS (Na ordem de dependência)
    // ----------------------------------------------------------------
    // Ordem: Simple -> Complex -> Guias -> Principal

    print('Processando: $arquivoSimple');
    await injetarConteudoLimpo(diretorioArquivos, arquivoSimple, bufferFinal);

    print('Processando: $arquivoComplex');
    await injetarConteudoLimpo(diretorioArquivos, arquivoComplex, bufferFinal);

    print('Processando: $arquivoGuias');
    await injetarConteudoLimpo(diretorioArquivos, arquivoGuias, bufferFinal);

    print('Processando Principal: $arquivoPrincipal');
    await injetarConteudoLimpo(diretorioArquivos, arquivoPrincipal, bufferFinal);

    // ----------------------------------------------------------------
    // 4. FECHAR O SCHEMA
    // ----------------------------------------------------------------
    bufferFinal.writeln('</${prefixoSchema}schema>');

    // Salvar
    final fileOut = File('$diretorioArquivos/$arquivoSaida');
    await fileOut.writeAsString(bufferFinal.toString(), encoding: latin1);

    print('---------------------------------------------------------');
    print('SUCESSO! Arquivo gerado: $diretorioArquivos/$arquivoSaida');
  } catch (e) {
    print('ERRO CRÍTICO: $e');
  }
}

// --- FUNÇÃO DE LIMPEZA E INJEÇÃO ---

Future<void> injetarConteudoLimpo(String dir, String nome, StringBuffer buffer) async {
  final lines = await lerArquivo(dir, nome);

  // Regex para identificar tags de schema (abertura e fechamento) com qualquer prefixo
  final regexSchemaTag = RegExp(r'<\/?([a-zA-Z0-9]+:)?schema');

  for (var linha in lines) {
    String l = linha.trim();

    // 1. Remove cabeçalho XML
    if (l.startsWith('<?xml')) continue;

    // 2. Remove tags de <schema> e </schema> (pois já temos a principal)
    if (regexSchemaTag.hasMatch(l)) continue;

    // 3. REMOVE INCLUDES E IMPORTS INTRA-TISS
    // Aqui está a mágica: Removemos qualquer tentativa de incluir Simple, Complex, Guias ou Assinatura
    // pois eles já foram (ou serão) colados manualmente ou adicionados no topo.
    if (l.startsWith('<include') ||
        l.startsWith('<xs:include') ||
        l.startsWith('<import') ||
        l.startsWith('<xs:import')) {
      if (linha.contains('tissSimpleTypes') ||
          linha.contains('tissComplexTypes') ||
          linha.contains('tissGuias') ||
          linha.contains('tissAssinaturaDigital')) {
        continue; // PULA ESSA LINHA
      }
      // Se for xmldsig no arquivo principal, já tratamos no topo, então remove aqui pra não duplicar
      if (linha.contains('xmldsig')) {
        continue;
      }
    }

    // 4. Se passou pelos filtros, escreve
    buffer.writeln(linha);
  }
}

Future<List<String>> lerArquivo(String dir, String nome) async {
  final file = File('$dir/$nome');
  if (!await file.exists()) throw Exception('Arquivo não encontrado: $nome');
  try {
    return await file.readAsLines(encoding: latin1);
  } catch (e) {
    return await file.readAsLines(encoding: utf8);
  }
}
