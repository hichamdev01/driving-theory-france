from pathlib import Path

from reportlab.lib.colors import HexColor, white
from reportlab.lib.enums import TA_CENTER
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.pdfgen import canvas
from reportlab.platypus import Paragraph


OUTPUT = Path("output/pdf/CV_Hicham_Labani_FR.pdf")

PAGE_W, PAGE_H = A4
MARGIN_X = 44
DATE_X = 44
CONTENT_X = 134
CONTENT_W = PAGE_W - CONTENT_X - MARGIN_X

BLUE = HexColor("#3F73E5")
DARK = HexColor("#202023")
TEXT = HexColor("#575757")
MUTED = HexColor("#707070")

FONT_DIR = Path("/System/Library/Fonts/Supplemental")
pdfmetrics.registerFont(TTFont("ArialNarrow", str(FONT_DIR / "Arial Narrow.ttf")))
pdfmetrics.registerFont(TTFont("ArialNarrow-Bold", str(FONT_DIR / "Arial Narrow Bold.ttf")))
pdfmetrics.registerFont(TTFont("ArialNarrow-Italic", str(FONT_DIR / "Arial Narrow Italic.ttf")))
pdfmetrics.registerFont(TTFont("Arial", str(FONT_DIR / "Arial.ttf")))
pdfmetrics.registerFont(TTFont("Arial-Bold", str(FONT_DIR / "Arial Bold.ttf")))
pdfmetrics.registerFont(TTFont("Arial-Italic", str(FONT_DIR / "Arial Italic.ttf")))

BODY = ParagraphStyle(
    "body",
    fontName="ArialNarrow",
    fontSize=10.8,
    leading=13.1,
    textColor=TEXT,
    spaceAfter=0,
)
BODY_TIGHT = ParagraphStyle(
    "body-tight",
    parent=BODY,
    fontSize=10.5,
    leading=12.2,
)
ENTRY_TITLE = ParagraphStyle(
    "entry-title",
    parent=BODY,
    fontName="ArialNarrow-Bold",
    fontSize=11.2,
    leading=13.4,
)
ENTRY_ROLE = ParagraphStyle(
    "entry-role",
    parent=BODY,
    fontName="ArialNarrow-Italic",
    fontSize=11.1,
    leading=13.2,
    textColor=MUTED,
)
DATE = ParagraphStyle(
    "date",
    fontName="ArialNarrow",
    fontSize=11.3,
    leading=13.8,
    textColor=MUTED,
)
EDU_TITLE = ParagraphStyle(
    "edu-title",
    parent=ENTRY_TITLE,
    fontSize=11.0,
    leading=13.0,
)
EDU_SCHOOL = ParagraphStyle(
    "edu-school",
    parent=ENTRY_ROLE,
    fontSize=10.9,
    leading=13.0,
)


def draw_paragraph(c, html, style, x, top_y, width):
    paragraph = Paragraph(html, style)
    _, height = paragraph.wrap(width, PAGE_H)
    paragraph.drawOn(c, x, top_y - height)
    return top_y - height


def draw_section(c, title, top_y):
    c.setStrokeColor(BLUE)
    c.setLineWidth(0.8)
    c.line(MARGIN_X, top_y, PAGE_W - MARGIN_X, top_y)
    c.setFillColor(BLUE)
    c.setFont("ArialNarrow", 17.2)
    c.drawString(MARGIN_X, top_y - 19, title)
    c.setLineWidth(0.55)
    c.line(MARGIN_X, top_y - 25, PAGE_W - MARGIN_X, top_y - 25)
    return top_y - 38


def draw_house(c, x, y):
    c.setStrokeColor(white)
    c.setFillColor(white)
    c.setLineWidth(1.2)
    c.line(x - 4, y, x, y + 4)
    c.line(x, y + 4, x + 4, y)
    c.rect(x - 3.2, y - 4, 6.4, 4.5, stroke=1, fill=0)
    c.rect(x - 0.8, y - 4, 1.6, 2.8, stroke=0, fill=1)


def draw_phone(c, x, y):
    c.setStrokeColor(white)
    c.setLineWidth(2.0)
    c.arc(x - 4, y - 4, x + 4, y + 4, startAng=142, extent=115)
    c.setLineWidth(1.2)
    c.line(x - 3.2, y + 2.3, x - 1.5, y + 0.7)
    c.line(x + 1.6, y - 0.8, x + 3.4, y - 2.4)


def draw_envelope(c, x, y):
    c.setStrokeColor(white)
    c.setLineWidth(0.9)
    c.rect(x - 4.5, y - 3.2, 9, 6.4, stroke=1, fill=0)
    c.line(x - 4.5, y + 3.2, x, y - 0.2)
    c.line(x, y - 0.2, x + 4.5, y + 3.2)


def draw_lightning(c, x, y):
    c.setFillColor(BLUE)
    path = c.beginPath()
    path.moveTo(x + 2.2, y + 7.0)
    path.lineTo(x - 2.0, y + 0.8)
    path.lineTo(x + 0.5, y + 0.8)
    path.lineTo(x - 1.2, y - 7.0)
    path.lineTo(x + 4.5, y + 0.3)
    path.lineTo(x + 1.8, y + 0.3)
    path.close()
    c.drawPath(path, stroke=0, fill=1)


def draw_header(c):
    c.setFillColor(DARK)
    c.rect(0, 599, PAGE_W, PAGE_H - 599, stroke=0, fill=1)

    c.setFillColor(white)
    c.setFont("Arial", 29)
    c.drawCentredString(PAGE_W / 2, 767, "LABANI HICHAM")
    c.setStrokeColor(white)
    c.setLineWidth(0.75)
    c.line(MARGIN_X, 744, PAGE_W - MARGIN_X, 744)

    c.setFont("Arial-Italic", 13.4)
    c.drawCentredString(PAGE_W / 2, 717, "INGÉNIEUR FULL-STACK SENIOR")
    c.setStrokeColor(BLUE)
    c.setLineWidth(0.7)
    c.line(MARGIN_X, 703, PAGE_W - MARGIN_X, 703)

    c.setFillColor(BLUE)
    c.setFont("ArialNarrow", 17.2)
    c.drawString(MARGIN_X, 684, "CONTACT")
    c.setStrokeColor(BLUE)
    c.setLineWidth(0.55)
    c.line(MARGIN_X, 677, PAGE_W - MARGIN_X, 677)

    c.setFont("ArialNarrow", 10.6)
    c.setFillColor(white)
    rows = [
        (651, draw_house, "Porto, Portugal"),
        (637, draw_phone, "+351 912 902 357"),
        (623, draw_envelope, "Hicham.labani.dev@gmail.com"),
    ]
    for y, icon, label in rows:
        icon(c, 54, y + 2)
        c.drawString(63, y, label)


def draw_footer(c):
    c.setFillColor(DARK)
    c.rect(0, 0, PAGE_W, 16, stroke=0, fill=1)


def draw_entry(c, top_y, dates, title, role, blocks, body_style=BODY):
    draw_paragraph(c, dates, DATE, DATE_X, top_y, 78)
    y = draw_paragraph(c, title, ENTRY_TITLE, CONTENT_X, top_y, CONTENT_W)
    y = draw_paragraph(c, role, ENTRY_ROLE, CONTENT_X, y, CONTENT_W)
    for html, gap_before in blocks:
        y -= gap_before
        y = draw_paragraph(c, html, body_style, CONTENT_X, y, CONTENT_W)
    return y


def draw_page_one(c):
    draw_header(c)

    y = draw_section(c, "PROFIL", 582)
    profile = (
        "Ingénieur logiciel Full-Stack avec cinq ans d'expérience en Java et Angular, "
        "concevant des solutions évolutives et centrées sur l'utilisateur dans les secteurs "
        "de la banque, des paiements en ligne, de l'IoT et des applications cloud. Maîtrise "
        "des API REST, des microservices et du développement front-end, avec une expérience "
        "pratique des principales plateformes cloud (AWS, Azure, GCP). Passionné par "
        "l'architecture logicielle et les méthodes agiles, j'ai commencé à programmer à "
        "l'âge de 15 ans et ai notamment développé, à titre personnel, une application mobile "
        "destinée aux étudiants qui a dépassé les 124 000 installations sur Google Play."
    )
    draw_paragraph(c, profile, BODY, MARGIN_X, y, PAGE_W - 2 * MARGIN_X)

    draw_section(c, "EXPÉRIENCE", 438)

    draw_entry(
        c,
        399,
        "10/2023 -<br/>aujourd'hui",
        "Natixis | BPCE",
        "Ingénieur Full-Stack, Portugal",
        [
            (
                "- Migration d'une application héritée d'AngularJS vers Angular 20 et du back-end de Java 7 vers Java 17.<br/>"
                "- Optimisation des performances des services back-end.<br/>"
                "- Développement de nouvelles fonctionnalités (back-end et front-end).<br/>"
                "- Accompagnement technique et encadrement des développeurs juniors.",
                0,
            ),
            (
                "<b>Stack :</b> Java 7/8/11/17, Spring Boot, microservices, API REST, Angular, "
                "TypeScript, Oracle, Maven",
                0,
            ),
        ],
    )

    draw_entry(
        c,
        251,
        "01/2023 -<br/>09/2023",
        "Centoria services | Purse (anciennement UpstreamPay)",
        "Ingénieur back-end, France",
        [
            (
                "J'ai travaillé comme consultant pour l'entreprise française Purse "
                "(anciennement UpstreamPay), où nous avons étudié et intégré les solutions des "
                "différents prestataires de paiement disponibles sur le marché, notamment "
                "PayPal, Ingenico, Stripe, Klarna et Dalenys, en utilisant l'orchestrateur de "
                "paiements UpstreamPay comme cœur de notre solution.",
                0,
            ),
            (
                "<b>Stack :</b> Java 17, Google Cloud, PostgreSQL, MongoDB, microservices, "
                "Docker, Spring Boot",
                0,
            ),
        ],
    )

    draw_footer(c)
    c.showPage()


def draw_page_two(c):
    c.setStrokeColor(BLUE)
    c.setLineWidth(0.8)
    c.line(MARGIN_X, 822, PAGE_W - MARGIN_X, 822)

    draw_entry(
        c,
        796,
        "01/2022 -<br/>01/2023",
        "Centoria services | ConnectedCycle",
        "Ingénieur Full-Stack, France",
        [
            (
                "Il s'agit d'une plateforme internationale déployée sur Google Cloud pour gérer "
                "des flottes de vélos électriques et mécaniques dans différents pays "
                "(États-Unis, Royaume-Uni, Espagne, Canada). La plateforme gère principalement "
                "les vélos électriques, leurs traceurs, leur position, leurs trajets et leurs "
                "statistiques (batterie, kilomètres, etc.). Elle s'appuie sur une base de données "
                "MongoDB de plus de 300 Go et plus de 10 microservices.",
                0,
            ),
            ("Missions :", 1),
            (
                "- Développement de nouvelles fonctionnalités (back-end et front-end)<br/>"
                "- Développement de microservices à partir de zéro<br/>"
                "- Correction de bugs (back-end et front-end)<br/>"
                "- Développement de l'application mobile native et déploiement sur Google Play<br/>"
                "- Tests unitaires avant la mise en production<br/>"
                "- Déploiement de microservices (Cloud Run, serveurs Linux, Kubernetes)<br/>"
                "- Réunions avec les clients pour recueillir les besoins et définir les tâches",
                2,
            ),
        ],
        BODY_TIGHT,
    )

    draw_entry(
        c,
        552,
        "02/2021 -<br/>01/2022",
        "DSI Conseil & Services",
        "Ingénieur Full-Stack, Maroc",
        [
            (
                "Participation au développement de la plateforme française de location de "
                "véhicules ucar.fr.",
                0,
            ),
            ("Missions :", 1),
            (
                "- Développement de nouvelles fonctionnalités (back-end et front-end)<br/>"
                "- Correction de bugs (back-end et front-end)<br/>"
                "- Tests d'intégration<br/>"
                "- Déploiement de l'application",
                0,
            ),
        ],
        BODY_TIGHT,
    )

    draw_section(c, "FORMATION", 405)

    draw_paragraph(c, "2022 - 2023", DATE, DATE_X, 365, 82)
    y = draw_paragraph(
        c,
        "Licence en ingénierie du cloud computing",
        EDU_TITLE,
        CONTENT_X,
        365,
        CONTENT_W,
    )
    draw_paragraph(
        c,
        "École nationale des sciences appliquées (ENSA), Maroc",
        EDU_SCHOOL,
        CONTENT_X,
        y,
        CONTENT_W,
    )

    draw_paragraph(c, "2019 - 2021", DATE, DATE_X, 319, 82)
    y = draw_paragraph(
        c,
        "Diplôme de technicien spécialisé en développement informatique",
        EDU_TITLE,
        CONTENT_X,
        319,
        CONTENT_W,
    )
    draw_paragraph(c, "OFPPT, Maroc", EDU_SCHOOL, CONTENT_X, y, CONTENT_W)

    draw_section(c, "LANGUES", 260)
    c.setFillColor(BLUE)
    c.setFont("Arial-Bold", 16)
    c.setFillColor(TEXT)
    c.setFont("ArialNarrow-Bold", 11.5)
    languages = ["Anglais", "Français", "Arabe", "Portugais"]
    y = 216
    for language in languages:
        draw_lightning(c, 56, y + 2)
        c.setFillColor(TEXT)
        c.setFont("ArialNarrow-Bold", 11.5)
        c.drawString(70, y, language)
        y -= 28

    draw_footer(c)
    c.showPage()


def main():
    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    pdf = canvas.Canvas(str(OUTPUT), pagesize=A4)
    pdf.setTitle("CV - Hicham Labani - Français")
    pdf.setAuthor("Hicham Labani")
    pdf.setSubject("CV en français")
    draw_page_one(pdf)
    draw_page_two(pdf)
    pdf.save()


if __name__ == "__main__":
    main()
