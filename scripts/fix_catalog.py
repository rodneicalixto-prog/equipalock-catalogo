import fitz
from pathlib import Path

SRC = Path('base-catalogo.pdf')
OUT = Path('catalogo-equipalok-locacao-whatsapp-FINAL-CTA-v2.pdf')


def rgb(value: str):
    value = value.lstrip('#')
    return tuple(int(value[i:i+2], 16) / 255 for i in (0, 2, 4))

DARK = rgb('#071826')
LIGHT = rgb('#f2f6f8')
WHITE = (1, 1, 1)
INK = DARK
MUTED = rgb('#607684')

doc = fitz.open(SRC)

redacts = {
    0: [(fitz.Rect(36, 762, 332, 780), DARK)],
    1: [(fitz.Rect(56, 544, 278, 569), LIGHT)],
    2: [
        (fitz.Rect(36, 101, 388, 138), LIGHT),
        (fitz.Rect(56, 544, 281, 570), LIGHT),
        (fitz.Rect(56, 592, 285, 648), LIGHT),
    ],
    4: [(fitz.Rect(55, 346, 229, 374), WHITE)],
    5: [(fitz.Rect(53, 318, 215, 340), WHITE)],
}

for page_number, items in redacts.items():
    page = doc[page_number]
    for rect, fill in items:
        page.add_redact_annot(rect, fill=fill)
    page.apply_redactions(images=0, graphics=0, text=0)

# Capa
page = doc[0]
page.insert_text(
    (38, 776.5),
    'LAVIEEN  |  ENDOLASER - ELYON  |  SCIZER',
    fontname='hebo', fontsize=12, color=WHITE,
)

# Lavieen - Agenda dinâmica
page = doc[1]
page.insert_text(
    (58, 554.8),
    'A sua clínica divulga protocolos rápidos e baixo',
    fontname='helv', fontsize=8.5, color=MUTED,
)
page.insert_text(
    (58, 566.3),
    'tempo de recuperação, conforme avaliação.',
    fontname='helv', fontsize=8.5, color=MUTED,
)

# Endolaser - Elyon
page = doc[2]
page.insert_text(
    (38, 132.5), 'ENDOLASER - ELYON',
    fontname='hebo', fontsize=27, color=INK,
)
page.insert_text(
    (58, 554.8),
    'Tratamento para neocolagênese, redução de gordura',
    fontname='helv', fontsize=8.2, color=MUTED,
)
page.insert_text(
    (58, 566.0), 'e skin tightening.',
    fontname='helv', fontsize=8.2, color=MUTED,
)

mobility_lines = [
    'Ultra leve e Fácil de transportar,',
    'com apenas 5,6 kg você transporta o equipamento',
    'com total facilidade entre as salas',
    'ou em rotinas externas.',
]
y = 602.5
for line in mobility_lines:
    page.insert_text(
        (58, y), line,
        fontname='helv', fontsize=7.7, color=MUTED,
    )
    y += 10.3

# Página de escolha
page = doc[4]
page.insert_text(
    (58, 368), 'ENDOLASER - ELYON',
    fontname='hebo', fontsize=14.5, color=INK,
)

# Fontes
page = doc[5]
page.insert_text(
    (55, 334.8), 'ENDOLASER - ELYON',
    fontname='hebo', fontsize=11.5, color=INK,
)

meta = doc.metadata
meta['title'] = 'Catálogo Equipalok 2026 - Oficial'
doc.set_metadata(meta)
doc.save(OUT, garbage=4, deflate=True, clean=True)
doc.close()

# Validação mínima: 6 páginas, fotos preservadas e links esperados.
check = fitz.open(OUT)
assert check.page_count == 6, f'Esperado 6 páginas, recebido {check.page_count}'
assert sum(len(p.get_images(full=True)) for p in check) >= 3, 'Imagens dos equipamentos não foram preservadas.'

links = [[item.get('uri') for item in p.get_links()] for p in check]
assert 'https://wa.me/5511975713886' in links[0]
assert any(uri and '5511912739685' in uri for uri in links[4]), 'Link antigo de disponibilidade da página 5 foi perdido.'
assert links[5].count('https://wa.me/5511975713886') >= 3

text = '\n'.join(p.get_text() for p in check)
for required in [
    'ENDOLASER - ELYON',
    'A sua clínica divulga protocolos rápidos e baixo',
    'Tratamento para neocolagênese',
    'Ultra leve e Fácil de transportar',
]:
    assert required in text, f'Texto não encontrado: {required}'

check.close()
print(f'Catálogo corrigido e validado: {OUT}')
