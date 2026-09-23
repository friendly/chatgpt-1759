"""Derive apa7-notes.csl (footnote variant) from apa7.csl.

Footnote = full APA reference at the first citation of a source, short form
(Author, year, locator) afterwards.  Only the short form abbreviates authors to "et al."
"""
import re
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"

s = (ASSETS / "apa7.csl").read_text(encoding="utf-8")
s = s.replace('class="in-text"', 'class="note"', 1)
s = re.sub(r"<title>.*?</title>", "<title>APA 7th edition (footnotes variant, Statistique et Société)</title>", s, count=1, flags=re.S)
s = re.sub(r"<id>.*?</id>", "<id>http://www.zotero.org/styles/apa-7-footnotes-statsoc</id>", s, count=1)

citation = """<citation disambiguate-add-year-suffix="true">
    <layout delimiter="; " suffix=".">
      <choose>
        <if position="first">
          <text macro="bibliography"/>
        </if>
        <else>
          <group delimiter=", ">
            <text macro="author-short"/>
            <text macro="date-short"/>
            <text macro="label-locator"/>
          </group>
        </else>
      </choose>
    </layout>
  </citation>"""
s = re.sub(r"<citation .*?</citation>", citation, s, count=1, flags=re.S)

# short-form author lists: "Vaswani et al." (three or more authors)
start = s.index('<macro name="author-short">')
end = s.index("</macro>", start)
block = s[start:end].replace('<name and="symbol" form="short"/>',
                             '<name and="symbol" form="short" et-al-min="3" et-al-use-first="1"/>')
s = s[:start] + block + s[end:]
(ASSETS / "apa7-notes.csl").write_text(s, encoding="utf-8")
print("apa7-notes.csl written")
