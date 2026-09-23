# OracleR: Migneret's 1759 "verse factory" as an R function.
#
#   Pierre-Jean Migneret, Invention d'une manufacture et fabrique de vers, au petit metier,
#   ou l'art de versifier par les seules regles du calcul numerique (Amsterdam, 1759).
#   Page numbers below are the pamphlet's printed pages.
#
# Steps 1-4: question -> nine words -> letter sums -> key -> triangle.
# Steps 5-6: triangle -> grid of six lines -> numbers -> the two tables -> a Latin hexameter.
# Base R only.  Design notes and history: OracleR-design.md.  Tests: oracle-tests.R.

# ---- Step 2: the "Table alphabeti-numerique" (p. 23) ---------------------------------------
# 23 values, one per letter of the 18th-century alphabet: I = J, U = V, and no W.
letter_values <- c(a = 1, b = 2, c = 3, d = 4, e = 5, f = 6, g = 7, h = 8, i = 9, j = 9,
                   k = 10, l = 11, m = 12, n = 13, o = 14, p = 15, q = 16, r = 17,
                   s = 18, t = 19, u = 20, v = 20, x = 21, y = 22, z = 23)

# Migneret's remainders: divide by 9 and keep the remainder, but a remainder of 0 counts as 9 (p. 26)
mod9 <- function(x) (x - 1) %% 9 + 1

# ---- A Helpful Oracle: errors that explain and encourage -----------------------------------
oracle_error <- function(class, ...) {
  stop(structure(class = c(class, "oracle_error", "error", "condition"),
                 list(message = paste0(...), call = NULL)))
}

# ---- Step 1: the question, in exactly nine words (pp. 20-21) -------------------------------
# `question` is one string or a character vector of words. As in the pamphlet's examples, a
# euphonic "-t-" stays with the word before it: "deviendra-t-il" -> "deviendra-t", "il".
normalize_question <- function(question) {
  if (length(question) == 1) {
    q <- gsub("-t-", "-t ", tolower(question), fixed = TRUE)
    words <- strsplit(q, "[[:space:]]+")[[1]]
  } else {
    words <- tolower(question)
  }
  words <- gsub("^[[:punct:][:space:]«»‘’“”…]+|[[:punct:][:space:]«»‘’“”…]+$", "", words)
  words[nzchar(words)]
}

check_nine <- function(words) {
  n <- length(words)
  if (n == 9) return(invisible(words))
  gap <- abs(9 - n)
  advice <- if (n < 9) {
    sprintf("Add %d more word%s (Migneret pads with words like \"bientôt\" or \"cette année\")",
            gap, if (gap == 1) "" else "s")
  } else {
    sprintf("Take away %d word%s", gap, if (gap == 1) "" else "s")
  }
  oracle_error("oracle_wordcount",
    "The Oracle listens gladly, but Migneret's machine weighs questions of exactly nine words, ",
    "and I count ", n, " in yours:\n  ", paste(words, collapse = " | "), "\n",
    advice, ", and I shall be happy to answer. Have no fear: as Migneret assures us, ",
    "\"il sera toujours facile d'en exprimer le sens dans ce nombre de termes\" (p. 20).\n",
    "(I count as he does: a euphonic \"-t-\" stays with the word before it, ",
    "so \"deviendra-t-il\" is two words, \"deviendra-t\" and \"il\".)")
}

# ---- Step 2: letters -> numbers -> one sum per word (pp. 22-25) ----------------------------
strip_accents <- function(x) {
  x <- gsub("œ", "oe", x, fixed = TRUE)   # oe ligature
  x <- gsub("æ", "ae", x, fixed = TRUE)   # ae ligature
  chartr("àâäéèêëîïôöùûüÿç",
         "aaaeeeeiioouuuyc", x)
}

# the letters of a word that count: no hyphens or apostrophes; accents are ignored
word_letters <- function(word) {
  ch <- strsplit(strip_accents(word), "")[[1]]
  ch[!ch %in% c("-", "'", "’")]
}

word_sums <- function(words) {
  vapply(words, function(w) {
    ch <- word_letters(w)
    bad <- setdiff(ch, names(letter_values))
    if (length(bad)) {
      oracle_error("oracle_letter",
        "The Oracle is puzzled by \"", paste(bad, collapse = "\", \""), "\" in \"", w, "\". ",
        "Migneret's alphabet has 23 letters (A to Z without W; I and J share a value, as do U and V) ",
        "and no digits or symbols. Might you spell that word another way, or choose another word?")
    }
    sum(letter_values[ch])
  }, numeric(1))
}

# ---- Step 4: the triangle of remainders (pp. 26-30) ----------------------------------------
# Each row is the mod-9 sum of adjacent pairs of the row above: 9 digits, then 8, ..., then 1.
mix_triangle <- function(key) {
  Reduce(function(row, i) mod9(head(row, -1) + tail(row, -1)),
         seq_len(length(key) - 1), key, accumulate = TRUE)
}

# ---- Step 5: from the triangle to a grid of six lines (pp. 33-41) ---------------------------
# The triangle is read in columns: column 1 is its right edge (nine digits, read upward from the
# tip), column 2 the next one to its left (eight digits), and so on. Columns 8 and 9 (three digits)
# are barred and never used (p. 36); the other 42 digits are cut into seven groups of six, which
# become columns A to G of a grid with six lines, I to VI (pp. 34-35).
triangle_columns <- function(triangle) {
  n <- length(triangle[[1]])
  lapply(seq_len(n), function(k)
    vapply(rev(seq_len(n + 1 - k)), function(r) {
      row <- triangle[[r]]
      row[length(row) - k + 1]
    }, numeric(1)))
}

grid_from_triangle <- function(triangle) {
  stream <- unlist(triangle_columns(triangle)[1:7])
  matrix(stream, nrow = 6, dimnames = list(c("I", "II", "III", "IV", "V", "VI"), LETTERS[1:7]))
}

# Each digit x in columns B-G becomes (3 x + the digit of column A on its line) mod 9 (pp. 36-41);
# then the number 9, 18, ..., 54 (for B, C, ..., G) and the digit of column A are added (pp. 42-43).
grid_numbers <- function(grid) {
  band <- grid[, "A"]
  offset <- matrix(9 * (1:6), nrow = 6, ncol = 6, byrow = TRUE)
  mod9(3 * grid[, -1] + band) + offset + band
}

# ---- Step 6: the two tables (plate between pp. 54 and 55; instructions pp. 46-52) -------------
# Tabula prima numerica: for each band 1-9 (row), the three numbers found in each of the parts B-G.
tabula_prima <- matrix(scan(quiet = TRUE, text = "
  11 14 17  56 59 62  20 23 26  47 50 53  29 32 35  38 41 44
  22 25 28  13 16 19  31 34 37  40 43 46  49 52 55  58 61 64
  60 63 66  51 54 57  42 45 48  33 36 39  24 27 30  15 18 21
  14 17 20  59 62 65  23 26 29  50 53 56  32 35 38  41 44 47
  25 28 31  16 19 22  34 37 40  43 46 49  52 55 58  61 64 67
  63 66 69  54 57 60  45 48 51  36 39 42  27 30 33  18 21 24
  17 20 23  62 65 68  26 29 32  53 56 59  35 38 41  44 47 50
  28 31 34  19 22 25  37 40 43  46 49 52  55 58 61  64 67 70
  66 69 72  57 60 63  48 51 54  39 42 45  30 33 36  21 24 27"), nrow = 9, byrow = TRUE)

# Tabula secunda litteralis: for each band, six cells (cases I-VI) in each of the parts B-G.
# "+" is an empty cell. As printed there, "s" is the long s and "j" stands for i.
tabula_secunda <- matrix(scan(what = "", quiet = TRUE, text = "
  d e f ru + f    o m o bi ra m   j te a m f a    + s t ti de u   + n u pe oe t   c + s t + +
  s e u m + a      j p c co t c    + + p p a +     t t j le l s    + j d bi j u    a s o t a s
  e s te t + n     + a j de ra e   c + + n pe m    c j c j s u     + c j n ro +    e s l no p n
  t n d so c sy    a s e bi da s   + j u l o +     t + j ti o u    a m + ve m d    n j b t m +
  o u o ro a c     f l u p g hi    r b + mi u a    + e t t d n     t n j ti j nu   e s s t a s
  + s o t a a      e j t ci l m    + t + di j +    r + r e b e     u a e ra u h    j s c p j t
  m + do u s c     e s s bi a n    j m mi o o a    l j n ti l e    + a n ve e r    l g a t cu m
  o p u n ro e     n o j no p t    n + s re e m    + t t d m p     n a + de j u    e s e t a s
  o m o t a m      d e t + t u     + d j j j l     e j r b b e     r qu e na e o   c e m do d c"),
  nrow = 9, byrow = TRUE)

# The digit of column A on a line is the band; the line's six numbers are looked up in that band of
# the Tabula prima; the part (B-G) where a number is found gives the cell of the Tabula secunda,
# in the same band and part, whose case is the number of the line (I for the first word, ..., VI).
# Cells with "+" give nothing; the other cells, read in order, spell the word (pp. 46-52).
look_up <- function(grid, numbers) {
  parts <- cells <- matrix(NA_character_, 6, 6, dimnames = list(rownames(grid), LETTERS[2:7]))
  for (line in 1:6) {
    band <- grid[line, "A"]
    for (k in 1:6) {
      pos <- match(numbers[line, k], tabula_prima[band, ])
      if (is.na(pos)) stop("The Oracle has lost its way: the number ", numbers[line, k],
                           " is not in band ", band, " of the Tabula prima.")
      part <- (pos - 1) %/% 3 + 1
      parts[line, k] <- LETTERS[part + 1]
      cells[line, k] <- tabula_secunda[band, (part - 1) * 6 + line]
    }
  }
  words <- apply(cells, 1, function(x) paste(x[x != "+"], collapse = ""))
  list(parts = parts, cells = cells, verse = unname(chartr("j", "i", words)))
}

# Latin as printed: "ae" and "oe" as ligatures
typeset_latin <- function(x) gsub("oe", "œ", gsub("ae", "æ", x))

# ---- The Oracle ------------------------------------------------------------------------------
Oracle <- function(question, output = c("plain", "fancy"), show.steps = FALSE) {
  output <- match.arg(output)          # "fancy" is accepted but is not yet different from "plain"
  words <- check_nine(normalize_question(question))
  sums <- word_sums(words)
  key <- unname(mod9(sums))
  triangle <- mix_triangle(key)
  grid <- grid_from_triangle(triangle)
  numbers <- grid_numbers(grid)
  found <- look_up(grid, numbers)
  structure(list(words = words, sums = sums, key = key, triangle = triangle,
                 grid = grid, numbers = numbers, parts = found$parts, cells = found$cells,
                 verse = found$verse, output = output, show.steps = show.steps),
            class = "oracle")
}

# ---- Printing ---------------------------------------------------------------------------------
format_steps <- function(x) {
  w <- pmax(nchar(x$words), nchar(x$sums)) + 2
  line <- function(v) paste0(strrep(" ", w - nchar(v)), v, collapse = "")
  tri <- vapply(seq_along(x$triangle), function(i)
    paste0("  ", strrep(" ", i - 1), paste(x$triangle[[i]], collapse = " ")), "")
  c("Step 1. Nine words", line(x$words), "",
    "Step 2. Letter sums", line(x$sums), "",
    "Step 3. Sums mod 9 (a remainder of 0 counts as 9): the nine-digit key", line(x$key), "",
    "Step 4. The triangle", tri, "",
    "Step 5. Six lines: column A is the band; digits of B-G become numbers",
    sprintf("  %-3s  band %d   digits %s   numbers %s", rownames(x$grid), x$grid[, "A"],
            apply(x$grid[, -1], 1, paste, collapse = " "),
            apply(x$numbers, 1, function(v) paste(sprintf("%2d", v), collapse = " "))), "",
    "Step 6. Each number is looked up in its band: part -> cell -> word",
    sprintf("  %-3s  parts %s   cells %s   word %s", rownames(x$grid),
            apply(x$parts, 1, paste, collapse = " "),
            apply(x$cells, 1, function(v) paste(sprintf("%-2s", v), collapse = " ")),
            typeset_latin(x$verse)))
}

# the verse as printed: capital first letter, full stop at the end
format_verse <- function(x) {
  v <- paste(typeset_latin(x$verse), collapse = " ")
  paste0(toupper(substring(v, 1, 1)), substring(v, 2), ".")
}

print.oracle <- function(x, ...) {
  if (x$show.steps) cat(format_steps(x), "", sep = "\n")
  cat(format_verse(x), "\n", sep = "")
  invisible(x)
}
