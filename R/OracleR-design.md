# OracleR — design notes

Migneret's 1759 "verse factory" as an R function, written for the *Statistique et Société* chronique
(planned as an Annex) and as a way to settle what Steps 5–6 of the pamphlet really do.
This file describes how the code was built, step by step, and is updated as we go
(the *process* is meant to be describable in the article, see "Ideas for the article").

**Status (20 September 2026):** Steps 1–6 implemented. `Oracle()` reproduces both verses printed in the pamphlet, and every intermediate stage of the marriage example (numbers, parts, cells). Not yet done: the "fancy" output and the Annex. A first version of the new wording for Steps 4–6 is in `chronique.qmd`, for the author to review.
Files: `oracle.R` (the code), `oracle-tests.R` (`Rscript oracle-tests.R`, 40 checks, all passing).
Page numbers are the pamphlet's **printed** pages (scan PDF page = printed + 8, except after the fold-out plate: p. 55 is PDF page 65).

---

## 1. Aims and decisions

Agreed 20 September 2026:

| Decision | Choice | Why |
|---|---|---|
| Interface | `Oracle(question, output = c("plain", "fancy"), show.steps = FALSE)` | `Oracle(inputtext)` is already in the text. `output` and `show.steps` only change *printing*. |
| Return value | An S3 object of class `"oracle"` holding every intermediate result (`words`, `sums`, `key`, `triangle`, `grid`, `numbers`, `parts`, `cells`, `verse`) | The steps are always available (`Oracle(q)$triangle`); the arithmetic is separate from the display. |
| Packaging | One file, base R only (`oracle.R`) | It is for a journal annex: readers should not need packages. The annex can include the very file that is tested. |
| Language of output | Latin verse only, no translation | The machine's output is Latin; input is French (any language works arithmetically, see section 7). Migneret gives no translation, and we only have translations for two verses. |
| Wrong number of words | A *Helpful Oracle*: an error that says how many words it counted (showing them), how many to add or remove, and quotes Migneret's reassurance (p. 20) | Chosen by the author: the Oracle should encourage, not scold. |
| Input | A single string, or a character vector of words | The vector lets someone bypass the tokenizer and count words as they like. |

"fancy" is accepted but currently identical to "plain".

## 2. The pipeline

| Step | Function | Pamphlet | What it does | Status |
|---|---|---|---|---|
| 1 | `normalize_question()`, `check_nine()` | pp. 20–21 | Lower-case; split on spaces; a euphonic *-t-* stays with the word before it; strip punctuation; require exactly 9 words | done |
| 2 | `word_sums()`, `letter_values`, `strip_accents()` | pp. 22–25 | Letter → number (A=1 … Z=23, I=J, U=V, no W), sum per word | done |
| 3 | `mod9()` | pp. 25–26 | Remainder of each sum divided by 9; a remainder of 0 counts as 9 (`(x - 1) %% 9 + 1`) | done |
| 4 | `mix_triangle()` | pp. 26–30 | Rows of mod-9 sums of adjacent pairs: 9 digits, 8, …, 1. Eight mixing operations, nine rows | done |
| 5 | `triangle_columns()`, `grid_from_triangle()`, `grid_numbers()` | pp. 33–43 | Read the triangle in columns → a grid of 6 lines × 7 columns (A–G) → six numbers per line | done |
| 6 | `look_up()`, `tabula_prima`, `tabula_secunda` | pp. 46–52, plate | Numbers → parts of the numeric table → cells of the letter table → six Latin words | done |

`Oracle()` chains them; `format_steps()`, `format_verse()` and `print.oracle()` display them.

## 3. What the pamphlet says (checked on the scan)

**Steps 1–3**
- Migneret says the question must be reduced to nine words and that "il sera toujours facile d'en exprimer le sens dans ce nombre de termes" (p. 20).
- Each of his four examples (pp. 20–21) contains a *-t-il* / *-t-elle* form (*deviendra-t-il* twice, *allumera-t-il*, *comblera-t-elle*), and each reaches nine words only if the word is split after the *t*: "deviendra-t-" + "il", and so on. The p. 53 example does the same with "sera-t-" + "elle". An elision such as *j'aime* or *l'himen* is one word.
- Alphabet (p. 23): A=1 … H=8, J,I=9, K=10 … T=19, V,U=20, X=21, Y=22, Z=23. No W.
- Divide by 9 and use only the remainders, never the quotients; a zero remainder counts as 9 (p. 26).

**Step 4 and Step 5 (pp. 26–43), in Migneret's words and my reading**
1. The triangle has nine digits on each face. Read its digits in *columns*: column 1 is the right edge (nine digits, starting from the bottom tip and going up), column 2 the next line to its left (eight digits), and so on to column 9 (one digit). "Les deux colonnes huitième & neuvième … qui sont barrés ne servent jamais" (p. 36): columns 8 and 9 are unused.
2. The other 42 digits are laid out in order, six at a time, in seven vertical lines A to G, six rows each (I–VI). (p. 34–35: A gets the first six digits of column 1, B the last three of column 1 and the first three of column 2, C the next five of column 2 and the first of column 3, …)
3. Each digit x in columns B–G becomes the remainder of (3 × x + the digit of column A on the same line) divided by 9, zero counting as 9 (pp. 36–41).
4. To that remainder add 9 (column B), 18 (C), 27 (D), 36 (E), 45 (F) or 54 (G), plus the digit of column A of the same line (pp. 42–43). The results, 11 to 72, are the numbers printed in the *Tabula prima numerica*.

**Step 6 (pp. 46–52)**
- The digit of column A on a line is the **band** (row 1–9) of both tables ("chiffre indicateur").
- Look up each of the line's six numbers, left to right, in that band of the *Tabula prima*; note the **part** (B–G) where it is found.
- In the same band and part of the *Tabula secunda*, take the cell whose **case** (I–VI) is the number of the line. A "+" gives nothing. The letters, in order, spell the word; the six lines give the six words of the hexameter.
- The pamphlet's own application (pp. 49–52) is the marriage example, line by line; our output matches every number, part and cell I could read.

**The two worked examples are both the pamphlet's own**
- Marriage question: verse *Ecce equidem licitè prædicit talia numen* (p. 52).
- Peace question: "La paix sera-t-elle prochaine & avantageuse aux **François**?" (pp. 53, 55), verse *Credo satis licitè, donabit fœdera numen* (p. 55). With the modern spelling *Français* the last sum is 68, not 81, the key changes (…5, not …9) and the machine gives *Forte petis iuste promittit iubila tempus*.
- **The printed verses say "licitè", with a grave accent** (seen on both pages at native resolution), not *licitæ* as in the blog. The tables spell the letters l-i-c-i-**te** ("te" is a digram cell); the printer marks the adverb with an accent. The code outputs *licite*.
- The printer sets the ae and oe digrams as ligatures (*prædicit*, *fœdera*): `typeset_latin()` does the same in the printed form.

## 4. What Steps 5–6 turn out to do (found by running the code)

1. **The verse depends only on the six digits of column A.** Everything in Steps 5–6 except column A (the multiplying by 3, the offsets, the remainders) never changes the result. Reason: the three numbers in each part of the *Tabula prima* are exactly the three values (r, r+3, r+6) that a digit of column B–G can produce, so all of them lead to the same part. Verified on 20,000 random keys (no exception), and by a test that scrambles the B–G digits.
2. **Column A is the right edge of the triangle** read upward from the tip (rows 9 down to 4), so **line I depends on all nine words of the question, line II on the last eight, …, line VI on the last four.** The first word of the question can change only the first word of the verse; the last word can change all six. (Exact reason: the last entry of triangle row *r* depends on the last *r* key digits.)
3. **So each word of the verse is one of only nine**, chosen by its band digit: 6 lines × 9 bands = **54 words in all** (table below). Each of the 324 cells of the *Tabula secunda* is used exactly once, in one of those 54 words.
4. **The machine can say exactly 9⁶ = 531,441 different verses** (all distinct, since the nine words of a line differ), whatever the question. It has no other repertoire.

The 54 words, as the code spells them (`u` for v, `j` printed as `i`; ae, oe as printed in the pamphlet: *prædicit, fœdera, sœcula, prœmia, cœlum*):

| band | I | II | III | IV | V | VI |
|---|---|---|---|---|---|---|
| 1 | dico | **etensm** | fausto | rumpettibi | foedera | fatum |
| 2 | ista | petis | cupido | complebit | talia | casus |
| 3 | ecce | scias | licite | **nonindet** | prospera | numen |
| 4 | tanta | nimis | dubie | solvettibi | commoda | sydus |
| 5 | forte | lubens | uotis | promittit | gaudia | hicannus |
| 6 | iure | satis | certo | praedicit | iubila | thema |
| 7 | mille | magis | dominans | uovettibi | soecula | carmen |
| 8 | nonne | optas | iuste | nonreddet | proemia | tempus |
| 9 | credo | equidem | merito | donabit | debita | coelum |

Almost all read as Latin (*rumpet tibi, solvet tibi, vovet tibi, non reddet, hic annus*), which is good evidence that the letter table was transcribed correctly. Two are odd, both checked at high magnification against the plate: **etensm** (line II, band 1: the cells are e, te, n, +, ſ, m; probably a misprint for *etenim*) and **nonindet** (line IV, band 3: no, n, j, n, de, t). They are kept as printed.

## 5. Open questions (things the pamphlet may or may not say)

1. **W.** The table has no W. Currently an error ("The Oracle is puzzled by…"). Could W = VV? Not in the pages read.
2. **Ligatures and other characters.** *œ*/*æ* are treated as *oe*/*ae*; ç as c (this reproduces the p. 53 sum for *François*). Digits and symbols are rejected. My choices, not Migneret's.
3. **Other hyphens** (*peut-être*, *est-ce*): kept as one word with the letters summed. Migneret's rule is only known for *-t-*.
4. **etensm / nonindet:** misprints or intended? Cannot be settled from the plate alone.
5. **What did Migneret expect the reader to conclude?** Since only column A matters, the elaborate arithmetic of Steps 5–6 is decorative. Whether he knew it (it looks designed: three numbers per part) is a question for the article, not for the code.

## 6. Tests (`oracle-tests.R`, 40 checks)

Every expected value comes from the scan or from an independent hand computation, not from the code:
- pp. 20–21: the four example questions each give 9 words.
- p. 25: sums 48 41 36 97 20 51 37 39 75; key 3 5 9 7 2 6 1 3 3; the nine-row triangle.
- p. 53: sums, key and triangle as printed; p. 54: column A of the first grid.
- pp. 36, 44, 49–52: the marriage example's grid column B, the six numbers on each line, the parts, the cells of lines V–VI.
- p. 52 and p. 55: both verses. *Français* ≠ *François*.
- The Helpful Oracle's messages: word count too low / too high (with the words it counted), a W, digits.
- Structure of the transcribed tables: the 162 numbers of *Tabula prima* fit r + 9c + band in every band, every number the arithmetic can produce is in its band, and every cell of *Tabula secunda* is "+", a letter or a digram.
- What the verse depends on (section 4): scrambling B–G changes nothing; the first word reaches only line I; the last word reaches all six lines.

**Coverage, honestly:** the two printed examples confirm **60 of the 324 cells** of *Tabula secunda* directly. The other 264 rest on my reading of the plate (each region checked at 300–500 % magnification) and on the 54 words being Latin. The 162 numbers of *Tabula prima* are checked by structure alone, and by the two examples.

## 7. Ideas for the article (not in the text yet)

- **Describe the coding as part of the story.** Turning the pamphlet into working code is itself an argument: the machine is fully specified (tests from the scan pass), and writing it exposed things reading did not (the *François* spelling, *licitè*, the *-t-* rule, and above all that the elaborate arithmetic of Steps 5–6 is decoration around a 54-word table).
- **A more striking version of the argument.** The oracle looks like an arithmetic marvel, but it is a lookup of nine words per position, chosen by six digits: at most 531,441 verses, whatever the question. Compare the LLM: the mechanism *also* looks arithmetic, yet its behavior is not a lookup. (Careful with how far to push this.)
- **An AI helped write it.** "Slightly delicious": using an AI assistant to re-implement a 1759 pamphlet about machines that mimic oracles. **Done (20 Sept):** a short section, "Coding the Oracle", in the chronique (section 6, before the Conclusion), which names the assistant (Claude Sonnet 5, via Claude Code, September 2026) and so serves as the disclosure. The author is content with the disclosure; whether the journal has its own AI policy is still unchecked (ask Gilbert if it matters). The name "Annex 1" is confirmed.
- **The Meta-Oracle.** The author and the assistant each keep their own queue of tasks, parse the other's requests in their own way, and go back and forth. A question is put in, reformulated, and an answer comes back. That is the Oracle's own structure, one level up.
- **The Helpful versus the Mean Oracle.** The error messages are a small design statement about how a machine should meet a question it cannot take as asked.
- **The arithmetic is language-agnostic**: an English nine-word question works (unless it contains a W). Only the tables are Latin.
- **Sensitivity to spelling**: *François* versus *Français* gives two different verses (*Credo satis…* versus *Forte petis…*), a two-line demonstration that the machine reads letters, not meaning.

## 8. Next

- "fancy" output (design once we decide what it is for).
- The annex: **drafted** as `Annex.qmd` (a separate document; `oracle.R` stays a separate file and is not reprinted). It holds the 54-word table (Table A2), because that table is the readout of what the machine can say. Open: where the files will be made available, and whether the chronique should point to the annex (it currently does not, since the annex may not travel with it).
- Rewrite Steps 5–6 and the Section 4 comparisons in the chronique (a first version is in `chronique.qmd`; see `rewrite-notes.md` 1.6).
- The name OracleR anticipates a possible package or a Shiny app, far in the future. Not planned. Nothing in the design prevents it: pure step functions, an S3 result, and print methods separate from computation.

## 9. Log

- **2026-09-20 (morning)** Design agreed. `oracle.R` Steps 1–4 written; tests (22 checks) pass. Scan read (pp. 20–26, 53–55, plate). Found: *-t-* rule confirmed; p. 53 question is spelled *François*.
- **2026-09-20 (midday)** Steps 5–6. Read pp. 26–54 (OCR text of the scan) and worked out the rules; transcribed both tables from the plate at 300 % magnification. First run reproduced both printed verses and the marriage example's numbers, parts and cells (pp. 44, 52). Then found by exploration that only column A matters (section 4), so 54 possible words and 9⁶ possible verses. Two odd words checked at 500 %. Printed verse is *licitè* (both p. 52 and p. 55). Tests extended to 40.
