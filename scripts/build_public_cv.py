#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
from xml.sax.saxutils import escape

import yaml
from reportlab.lib.colors import HexColor
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import (
    SimpleDocTemplate,
    Paragraph,
    Spacer,
    Table,
    TableStyle,
)

ROOT = Path(__file__).resolve().parents[1]
DATA = yaml.safe_load((ROOT / "site/data/cv.yml").read_text(encoding="utf-8"))

OUT = ROOT / "site/assets/files/Curriculum_Vitae_Joaquin_Zaragoza_Lopez.pdf"
OUT.parent.mkdir(parents=True, exist_ok=True)

FONT = "C:/Windows/Fonts/segoeui.ttf"
FONT_B = "C:/Windows/Fonts/segoeuib.ttf"

pdfmetrics.registerFont(TTFont("Segoe", FONT))
pdfmetrics.registerFont(TTFont("Segoe-Bold", FONT_B))

INK = HexColor("#1f2b36")
NAVY = HexColor("#193044")
MUTED = HexColor("#66727f")
LINE = HexColor("#ded8cf")
TERR = HexColor("#b4573d")
SOFT = HexColor("#f4f1eb")

styles = getSampleStyleSheet()

base = ParagraphStyle(
    "Base",
    parent=styles["BodyText"],
    fontName="Segoe",
    fontSize=8.35,
    leading=11.15,
    textColor=INK,
    spaceAfter=4,
)

small = ParagraphStyle(
    "Small",
    parent=base,
    fontSize=7.25,
    leading=9.2,
    textColor=MUTED,
)

name_style = ParagraphStyle(
    "Name",
    parent=base,
    fontName="Segoe-Bold",
    fontSize=19,
    leading=20.5,
    textColor=NAVY,
    spaceAfter=3,
)

headline_style = ParagraphStyle(
    "Headline",
    parent=base,
    fontName="Segoe-Bold",
    fontSize=9.5,
    leading=11.5,
    textColor=TERR,
    spaceAfter=7,
)

section_style = ParagraphStyle(
    "Section",
    parent=base,
    fontName="Segoe-Bold",
    fontSize=9.8,
    leading=11.5,
    textColor=NAVY,
    spaceBefore=5,
    spaceAfter=3,
    uppercase=True,
)

item_title = ParagraphStyle(
    "ItemTitle",
    parent=base,
    fontName="Segoe-Bold",
    fontSize=8.5,
    leading=10.4,
    textColor=NAVY,
    spaceAfter=1,
)

period_style = ParagraphStyle(
    "Period",
    parent=base,
    fontName="Segoe-Bold",
    fontSize=7.3,
    leading=8.8,
    textColor=MUTED,
)

detail_style = ParagraphStyle(
    "Detail",
    parent=base,
    fontSize=8.1,
    leading=10.5,
    textColor=INK,
    spaceAfter=2,
)

bullet_style = ParagraphStyle(
    "Bullet",
    parent=detail_style,
    leftIndent=8,
    firstLineIndent=-6,
    bulletIndent=0,
    spaceAfter=1.5,
)


def as_text(value) -> str:
    """Return an escaped string suitable for ReportLab Paragraph."""
    if value is None:
        return ""
    return escape(str(value))


def join_list(values) -> str:
    """Convert a YAML list to a readable semicolon-separated string."""
    if not values:
        return ""
    if isinstance(values, list):
        return "; ".join(as_text(value) for value in values)
    return as_text(values)


def footer(canvas, doc):
    canvas.saveState()

    width, _ = A4
    canvas.setStrokeColor(LINE)
    canvas.line(18 * mm, 14 * mm, width - 18 * mm, 14 * mm)

    canvas.setFont("Segoe", 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(
        18 * mm,
        9 * mm,
        "Curriculum Vitae · Joaquín Zaragoza López · Personal portfolio",
    )
    canvas.drawRightString(width - 18 * mm, 9 * mm, str(doc.page))

    canvas.restoreState()


def section_title(text: str):
    return [
        Spacer(1, 2),
        Paragraph(as_text(text).upper(), section_style),
    ]


def bullet_paragraphs(details):
    """Create ReportLab bullet paragraphs from a string or list."""
    if not details:
        return []

    if isinstance(details, str):
        details = [details]

    return [
        Paragraph(as_text(detail), bullet_style, bulletText="•")
        for detail in details
    ]


def two_column_block(period_value, title, subtitle="", details=None):
    """Build one CV entry with dates in the left column."""
    left = Paragraph(as_text(period_value), period_style)

    right = [Paragraph(as_text(title), item_title)]

    if subtitle:
        right.append(Paragraph(as_text(subtitle), base))

    right.extend(bullet_paragraphs(details))

    table = Table(
        [[left, right]],
        colWidths=[30 * mm, 142 * mm],
        hAlign="LEFT",
    )

    table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 1.5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                ("LINEBELOW", (0, 0), (-1, -1), 0.35, LINE),
            ]
        )
    )

    return table


story = []

headline_value = DATA.get(
    "headline",
    DATA.get("position", "M.Sc. Student in Economics | Research Assistant"),
)

contact_parts = [
    DATA.get("email"),
    DATA.get("phone"),
    DATA.get("address"),
    DATA.get("linkedin"),
    DATA.get("github"),
]
contact = "  ·  ".join(as_text(value) for value in contact_parts if value)

header = Table(
    [
        [Paragraph(as_text(DATA.get("name", "")), name_style)],
        [Paragraph(as_text(headline_value), headline_style)],
        [Paragraph(contact, small)],
    ],
    colWidths=[174 * mm],
)

header.setStyle(
    TableStyle(
        [
            ("BACKGROUND", (0, 0), (-1, -1), SOFT),
            ("BOX", (0, 0), (-1, -1), 0.6, LINE),
            ("LEFTPADDING", (0, 0), (-1, -1), 10),
            ("RIGHTPADDING", (0, 0), (-1, -1), 10),
            ("TOPPADDING", (0, 0), (-1, 0), 10),
            ("BOTTOMPADDING", (0, -1), (-1, -1), 9),
        ]
    )
)

story += [header, Spacer(1, 5)]

# Research and professional experience
if DATA.get("experience"):
    story += section_title("Professional & Research Experience")

    for item in DATA["experience"]:
        title = item.get("position", "")
        institution = item.get("institution", "")
        location = item.get("location", "")

        role_line = f"{title} · {institution}" if institution else title
        subtitle = location

        story.append(
            two_column_block(
                item.get("period", ""),
                role_line,
                subtitle,
                item.get("details", []),
            )
        )

# Education
if DATA.get("education"):
    story += section_title("Education")

    for item in DATA["education"]:
        degree = item.get("degree", "")
        institution = item.get("institution", "")
        location = item.get("location", "")

        degree_line = f"{degree} · {institution}" if institution else degree
        story.append(
            two_column_block(
                item.get("period", ""),
                degree_line,
                location,
                item.get("details", []),
            )
        )

# Research outputs: thesis and term papers
if DATA.get("papers"):
    story += section_title("Research Papers")

    for item in DATA["papers"]:
        title = item.get("title", "")
        paper_type = item.get("type", "")
        year = item.get("year", "")

        story.append(
            two_column_block(
                year,
                title,
                paper_type,
                item.get("details", []),
            )
        )

# Courses and summer schools
if DATA.get("courses"):
    story += section_title("Courses & Summer Schools")

    for item in DATA["courses"]:
        story.append(
            two_column_block(
                item.get("year", ""),
                item.get("name", ""),
                item.get("institution", ""),
                item.get("details", ""),
            )
        )

# Technical skills
technical_skills = DATA.get("technical_skills", {})
if technical_skills:
    story += section_title("Technical Skills")

    skill_rows = []

    if isinstance(technical_skills, dict):
        for category, skills in technical_skills.items():
            label = as_text(str(category).replace("_", " ").title())
            skill_rows.append(
                [
                    Paragraph(label, item_title),
                    Paragraph(join_list(skills), base),
                ]
            )
    elif isinstance(technical_skills, list):
        for entry in technical_skills:
            if isinstance(entry, dict):
                category, skills = next(iter(entry.items()))
                label = as_text(str(category).replace("_", " ").title())
                skill_rows.append(
                    [
                        Paragraph(label, item_title),
                        Paragraph(join_list(skills), base),
                    ]
                )

    if skill_rows:
        skills_table = Table(
            skill_rows,
            colWidths=[38 * mm, 134 * mm],
            hAlign="LEFT",
        )

        skills_table.setStyle(
            TableStyle(
                [
                    ("VALIGN", (0, 0), (-1, -1), "TOP"),
                    ("LEFTPADDING", (0, 0), (-1, -1), 0),
                    ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                    ("TOPPADDING", (0, 0), (-1, -1), 2),
                    ("BOTTOMPADDING", (0, 0), (-1, -1), 3),
                ]
            )
        )

        story.append(skills_table)

# Research interests
if DATA.get("research_interests"):
    story += section_title("Research Interests")
    story.append(Paragraph(join_list(DATA["research_interests"]), base))

# Languages
if DATA.get("languages"):
    story += section_title("Languages")

    language_rows = [
        [
            Paragraph(as_text(item.get("language", "")), item_title),
            Paragraph(as_text(item.get("level", "")), base),
        ]
        for item in DATA["languages"]
    ]

    languages_table = Table(
        language_rows,
        colWidths=[45 * mm, 127 * mm],
        hAlign="LEFT",
    )

    languages_table.setStyle(
        TableStyle(
            [
                ("VALIGN", (0, 0), (-1, -1), "TOP"),
                ("LEFTPADDING", (0, 0), (-1, -1), 0),
                ("RIGHTPADDING", (0, 0), (-1, -1), 4),
                ("TOPPADDING", (0, 0), (-1, -1), 1.5),
                ("BOTTOMPADDING", (0, 0), (-1, -1), 2),
            ]
        )
    )

    story.append(languages_table)

doc = SimpleDocTemplate(
    str(OUT),
    pagesize=A4,
    rightMargin=18 * mm,
    leftMargin=18 * mm,
    topMargin=11 * mm,
    bottomMargin=15 * mm,
    title="Curriculum Vitae - Joaquín Zaragoza López",
    author="Joaquín Zaragoza López",
)

doc.build(story, onFirstPage=footer, onLaterPages=footer)

print(OUT)