#!/usr/bin/env python3
from __future__ import annotations

from pathlib import Path
import yaml
from reportlab.lib.colors import HexColor
from reportlab.lib.enums import TA_LEFT
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import ParagraphStyle, getSampleStyleSheet
from reportlab.lib.units import mm
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer, Table, TableStyle, KeepTogether, PageBreak

ROOT = Path(__file__).resolve().parents[1]
DATA = yaml.safe_load((ROOT / 'site/data/cv.yml').read_text(encoding='utf-8'))
OUT = ROOT / 'site/assets/files/Curriculum_Vitae__08_26_.pdf'
OUT.parent.mkdir(parents=True, exist_ok=True)

FONT = "C:/Windows/Fonts/segoeui.ttf"
FONT_B = "C:/Windows/Fonts/segoeuib.ttf"
pdfmetrics.registerFont(TTFont('Segoe', FONT))
pdfmetrics.registerFont(TTFont('Segoe-Bold', FONT_B))

INK = HexColor('#1f2b36')
NAVY = HexColor('#193044')
MUTED = HexColor('#66727f')
LINE = HexColor('#ded8cf')
TERR = HexColor('#b4573d')
SOFT = HexColor('#f4f1eb')

styles = getSampleStyleSheet()
base = ParagraphStyle('Base', parent=styles['BodyText'], fontName='Segoe', fontSize=8.35, leading=11.15, textColor=INK, spaceAfter=5)
small = ParagraphStyle('Small', parent=base, fontSize=7.25, leading=9.2, textColor=MUTED)
name = ParagraphStyle('Name', parent=base, fontName='Segoe-Bold', fontSize=19, leading=20.5, textColor=NAVY, spaceAfter=3)
headline = ParagraphStyle('Headline', parent=base, fontName='Segoe-Bold', fontSize=9.5, leading=11.5, textColor=TERR, spaceAfter=7)
section = ParagraphStyle('Section', parent=base, fontName='Segoe-Bold', fontSize=9.8, leading=11.5, textColor=NAVY, spaceBefore=5, spaceAfter=3, uppercase=True)
item_title = ParagraphStyle('ItemTitle', parent=base, fontName='Segoe-Bold', fontSize=8.5, leading=10.4, textColor=NAVY, spaceAfter=1)
period = ParagraphStyle('Period', parent=base, fontName='Segoe-Bold', fontSize=7.3, leading=8.8, textColor=MUTED)


def footer(canvas, doc):
    canvas.saveState()
    w, _ = A4
    canvas.setStrokeColor(LINE)
    canvas.line(18*mm, 14*mm, w-18*mm, 14*mm)
    canvas.setFont('Segoe', 7.5)
    canvas.setFillColor(MUTED)
    canvas.drawString(18*mm, 9*mm, 'Curriculum Vitae · Joaquín Zaragoza López · Portafolio personal')
    canvas.drawRightString(w-18*mm, 9*mm, str(doc.page))
    canvas.restoreState()


def section_title(text):
    return [Spacer(1, 2), Paragraph(text.upper(), section)]


def exp_block(item):
    left = Paragraph(str(item['period']), period)
    title = f"{item['role']} · {item['institution']}"
    right = [Paragraph(title, item_title), Paragraph(item['details'], base)]
    tbl = Table([[left, right]], colWidths=[30*mm, 142*mm], hAlign='LEFT')
    tbl.setStyle(TableStyle([
        ('VALIGN', (0,0), (-1,-1), 'TOP'),
        ('LEFTPADDING', (0,0), (-1,-1), 0),
        ('RIGHTPADDING', (0,0), (-1,-1), 4),
        ('TOPPADDING', (0,0), (-1,-1), 1.5),
        ('BOTTOMPADDING', (0,0), (-1,-1), 2.2),
        ('LINEBELOW', (0,0), (-1,-1), .35, LINE),
    ]))
    return tbl

story = []
contact = f"{DATA['email']}  ·  {DATA['github']}  ·  {DATA['linkedin']}"
header = Table([
    [Paragraph(DATA['name'], name)],
    [Paragraph(DATA['headline'], headline)],
    [Paragraph(contact, small)]
], colWidths=[174*mm])
header.setStyle(TableStyle([
    ('BACKGROUND', (0,0), (-1,-1), SOFT),
    ('BOX', (0,0), (-1,-1), .6, LINE),
    ('LEFTPADDING', (0,0), (-1,-1), 10),
    ('RIGHTPADDING', (0,0), (-1,-1), 10),
    ('TOPPADDING', (0,0), (-1,0), 10),
    ('BOTTOMPADDING', (0,-1), (-1,-1), 9),
]))
story += [header, Spacer(1, 5), Paragraph(DATA['summary'], base)]
story += section_title('Professional & Research Experience')
for item in DATA['experience']:
    story.append(exp_block(item))

story += section_title('Formación')
edu_rows = []
for e in DATA['education']:
    edu_rows.append([Paragraph(str(e['period']), period), Paragraph(f"<b>{e['degree']}</b><br/>{e['institution']}", base)])
edu = Table(edu_rows, colWidths=[30*mm, 142*mm], hAlign='LEFT')
edu.setStyle(TableStyle([
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('LEFTPADDING', (0,0), (-1,-1), 0),
    ('RIGHTPADDING', (0,0), (-1,-1), 4),
    ('TOPPADDING', (0,0), (-1,-1), 1.5),
    ('BOTTOMPADDING', (0,0), (-1,-1), 2.2),
    ('LINEBELOW', (0,0), (-1,-1), .35, LINE),
]))
story.append(edu)

story += section_title('Master \'s thesis')
story.append(KeepTogether([ 
    Paragraph(DATA['thesis']['title'], item_title),
    Paragraph(DATA['thesis']['details'], base)
]))

story += section_title('Technical skills')
skill_rows = []
for entry in DATA['skills']:
    key, value = next(iter(entry.items()))
    skill_rows.append([Paragraph(key, item_title), Paragraph(str(value), base)])
skills = Table(skill_rows, colWidths=[38*mm, 134*mm], hAlign='LEFT')
skills.setStyle(TableStyle([
    ('VALIGN', (0,0), (-1,-1), 'TOP'),
    ('LEFTPADDING', (0,0), (-1,-1), 0),
    ('RIGHTPADDING', (0,0), (-1,-1), 4),
    ('TOPPADDING', (0,0), (-1,-1), 2),
    ('BOTTOMPADDING', (0,0), (-1,-1), 3),
]))
story.append(skills)
story += section_title('Research interests')
story.append(Paragraph(DATA['interests'], base))

doc = SimpleDocTemplate(str(OUT), pagesize=A4, rightMargin=18*mm, leftMargin=18*mm, topMargin=11*mm, bottomMargin=15*mm,
                        title='Curriculum Vitae - Joaquín Zaragoza López', author='Joaquín Zaragoza López')
doc.build(story, onFirstPage=footer, onLaterPages=footer)

print(OUT)