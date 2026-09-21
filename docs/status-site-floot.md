# Site Equipalok: status do projeto

Atualizado em 20/09/2026. Projeto no Floot: "Equipalok Locações". O site está em preview e ainda não foi publicado.

## O que foi feito

**Site (Floot).** Página única construída com os dados reais do catálogo 2026 deste repositório. Tem hero, problema e mecanismo, os três equipamentos (LAVIEEN, ENDOLASER - ELYON, SCIZER) com fotos, especificações e avisos do catálogo, perguntas frequentes, "como funciona" e formulário de consulta de disponibilidade. Identidade visual igual à do catálogo: azul-marinho #0b1220, verde-limão #a8e02e, Sora nos títulos e IBM Plex Sans no corpo. Não há preço, prazo, garantia, depoimento, endereço nem promessa de resultado que não esteja no catálogo. Os avisos de locação condicionada e de uso por profissional habilitado foram mantidos.

**Formulário e banco.** O formulário grava em uma tabela `leads` (nome, clínica, WhatsApp, cidade, equipamento, data pretendida, observações), com campo isca contra spam. Foi testado de ponta a ponta e as linhas de teste foram apagadas.

**Código do aviso de novo lead (pronto, ainda não ligado).** Depois de gravar o lead, o site faz um POST em um webhook do n8n, protegido por token no cabeçalho `X-Site-Token`. Há limite de 8 segundos, falha silenciosa (o visitante nunca vê erro do aviso), bloqueio de repetição do mesmo WhatsApp em 10 minutos e teto de 30 avisos por hora.

**Workflow n8n exclusivo da Equipalok.** Foi criado um workflow próprio (webhook, montagem da mensagem e envio pelo Evolution, instância `equipalok`), salvo no n8n em 20/09/2026 e inativo. A autenticação do webhook está temporariamente em "None" e não deve ser ativado assim. Decisão do cliente: o workflow é exclusivo da Equipalok, sem misturar credenciais nem fluxos de outros clientes, e não reutiliza o fluxo do SDR virtual.

**Leitura completa do fluxo do SDR virtual (Bia), para evitar duplicidade.** O combinado é que a Bia atende primeiro e, ao final, o SDR humano recebe o resumo e decide se assume. A leitura mostrou que a Bia só age quando o lead escreve pelo WhatsApp, que a abertura dela pergunta nome e clínica sem ler o formulário do site, e que há pontos do fluxo a confirmar no editor do n8n antes de qualquer envio ativo ao lead.

## O que ficou pendente

1. **Decidir o que o workflow do site faz com o lead** (ver "Próximo passo").
2. No n8n: voltar a autenticação do webhook para Header Auth e criar credenciais próprias da Equipalok (token do webhook e chave da instância `equipalok`), digitadas pelo cliente. Só depois ativar, e só quando o fluxo da Bia estiver confirmado.
3. Informar no Floot as duas variáveis do aviso pelo link de conexão do projeto.
4. Teste ponta a ponta com um lead de teste e limpeza da linha no banco.
5. Revisar as credenciais do fluxo da Bia: mover segredos escritos nos nós para credenciais do n8n e rotacionar as chaves.
6. Confirmar o direito de uso das fotos dos fabricantes. A foto do LAVIEEN é de baixa resolução (107 x 440 px).
7. E-mail e Instagram da Equipalok (não constam neste repositório).
8. Confirmar se o atendimento é só em São Paulo ou em outras cidades.
9. Revisão dos textos de procedimentos (neocolagênese, redução de gordura, skin tightening) pelo responsável técnico.
10. Verificar as numerações ANVISA no registro oficial.
11. Política de privacidade e aviso no formulário de que o contato será por WhatsApp.
12. Domínio próprio e publicação, somente depois dos itens 4, 6 e 11.

## Próximo passo

1. **Confirmar no editor do n8n o estado real do fluxo da Bia**, especialmente o envio do resumo ao SDR humano.
2. **Decidir o papel do workflow do site**, sem duplicar o que a Bia já faz:
   - **Opção 1:** só registrar o lead, sem aviso e sem mensagem. O humano recebe o resumo quando o lead escrever e a Bia concluir.
   - **Opção 2:** o workflow envia uma primeira mensagem curta ao lead, com os dados do formulário, e a Bia assume quando ele responder. Só faz sentido depois de a Bia receber o contexto do formulário, senão ela repete as perguntas.
   - **Opção 3:** aviso interno para um número diferente do SDR humano, sem interferir no fluxo da Bia.
3. Com a decisão tomada: ajustar o workflow, ativar com credenciais próprias, ligar as variáveis no Floot, testar com um número do cliente e só então avançar para fotos, privacidade e publicação.

Recomendação: começar pela Opção 1 (a menos arriscada) e corrigir o fluxo da Bia antes de qualquer envio ativo ao lead, para o atendimento não começar duplicado nem sem o resumo ao humano.
