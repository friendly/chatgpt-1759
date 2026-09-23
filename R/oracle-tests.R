# Tests for oracle.R.  Run from anywhere:  Rscript oracle-tests.R
# Expected values come from the pamphlet itself (seen on the scan), not from the code:
#   p. 20-21  four example questions, each reduced to nine words
#   p. 25     the worked example (nine sums), + the key and triangle (verified by hand)
#   p. 53     the "Autre question": sums, key and triangle as printed
#   p. 44, 48-52  the marriage example line by line: numbers, parts, cells, and the verse
#   p. 52, 55     the two printed verses
# Also: structural checks on the transcribed tables (they cannot be checked against the scan by code).

args <- commandArgs(FALSE)
here <- dirname(sub("^--file=", "", args[grep("^--file=", args)]))
if (length(here) == 0) here <- "."
source(file.path(here, "oracle.R"), encoding = "UTF-8")

n_fail <- 0
check <- function(desc, ok) {
  cat(if (isTRUE(ok)) "  ok    " else "  FAIL  ", desc, "\n", sep = "")
  if (!isTRUE(ok)) n_fail <<- n_fail + 1
}
caught <- function(expr) tryCatch({ expr; NULL }, error = function(e) e)

# ---- pp. 20-21: the four example questions have nine words ----------------------------------
cat("Step 1: nine words (pp. 20-21)\n")
q_p20 <- c("Celui que je désire deviendra-t-il bientôt mon mari ?",
           "L'himen cette année allumera-t-il son flambeau pour moi ?",
           "Cette année comblera-t-elle mes désirs par un mariage ?",
           "Celui que j'aime deviendra-t-il cette année mon époux ?")
for (q in q_p20) check(q, length(normalize_question(q)) == 9)
check("-t- stays with the word before it",
      identical(normalize_question("Celui que j'aime deviendra-t-il cette année mon époux ?"),
                c("celui", "que", "j'aime", "deviendra-t", "il", "cette", "année", "mon", "époux")))
check("a vector of words gives the same result as the string",
      identical(normalize_question(c("Celui", "que", "j'aime", "deviendra-t", "il", "cette", "année", "mon", "époux")),
                normalize_question("Celui que j'aime deviendra-t-il cette année mon époux ?")))
check("punctuation, guillemets and a stray '?' are dropped",
      identical(normalize_question("« Celui que j'aime deviendra-t-il cette année mon époux? »"),
                normalize_question("Celui que j'aime deviendra-t-il cette année mon époux ?")))

# ---- p. 25: the worked example ----------------------------------------------------------------
cat("Steps 2-4: the worked example (p. 25)\n")
o1 <- Oracle("Celui que j'aime deviendra-t-il cette année mon époux ?")
check("word sums 48 41 36 97 20 51 37 39 75", identical(unname(o1$sums), c(48, 41, 36, 97, 20, 51, 37, 39, 75)))
check("key 3 5 9 7 2 6 1 3 3",               identical(o1$key, c(3, 5, 9, 7, 2, 6, 1, 3, 3)))
tri1 <- list(c(3, 5, 9, 7, 2, 6, 1, 3, 3), c(8, 5, 7, 9, 8, 7, 4, 6), c(4, 3, 7, 8, 6, 2, 1),
             c(7, 1, 6, 5, 8, 3), c(8, 7, 2, 4, 2), c(6, 9, 6, 6), c(6, 6, 3), c(3, 9), 3)
check("triangle: 9 rows of length 9, 8, ..., 1, as computed by hand", identical(o1$triangle, tri1))

# ---- p. 53: the "Autre question" (printed with the 18th-century spelling "François") --------
cat("Steps 2-4: the second worked example (p. 53)\n")
o2 <- Oracle("La paix sera-t-elle prochaine et avantageuse aux François ?")
check("word sums 12 46 60 32 85 24 110 42 81", identical(unname(o2$sums), c(12, 46, 60, 32, 85, 24, 110, 42, 81)))
check("key 3 1 6 5 4 6 2 6 9",               identical(o2$key, c(3, 1, 6, 5, 4, 6, 2, 6, 9)))
tri2 <- list(c(3, 1, 6, 5, 4, 6, 2, 6, 9), c(4, 7, 2, 9, 1, 8, 8, 6), c(2, 9, 2, 1, 9, 7, 5),
             c(2, 2, 3, 1, 7, 3), c(4, 5, 4, 8, 1), c(9, 9, 3, 9), c(9, 3, 3), c(3, 6), 9)
check("triangle as printed on p. 53", identical(o2$triangle, tri2))
# p. 54, first grid, column A (lines I-VI) = 9 6 3 9 1 3: the right edge of the triangle, read upward from the tip
edge <- rev(vapply(o2$triangle, function(r) r[length(r)], numeric(1)))
check("right edge of the triangle from its tip = column A of the p. 54 grid (9 6 3 9 1 3)",
      identical(edge[1:6], c(9, 6, 3, 9, 1, 3)))

cat("The modern spelling changes the key\n")
o2m <- Oracle("La paix sera-t-elle prochaine et avantageuse aux Français ?")
check("'Français' (sum 68) is not 'François' (sum 81): last key digit 5, not 9",
      o2m$sums[[9]] == 68 && o2m$key[9] == 5)

# ---- a Helpful Oracle ---------------------------------------------------------------------------
cat("Helpful errors\n")
e7 <- caught(Oracle("Celui que j'aime deviendra-t-il mon époux ?"))
check("7 words: class oracle_wordcount",   inherits(e7, "oracle_wordcount"))
check("7 words: says how many to add",     grepl("Add 2 more words", conditionMessage(e7), fixed = TRUE))
check("7 words: shows the words counted",  grepl("celui | que | j'aime | deviendra-t | il | mon | époux", conditionMessage(e7), fixed = TRUE))
e10 <- caught(Oracle("Celui que j'aime deviendra-t-il bientôt cette année mon époux ?"))
check("10 words: says how many to take away", grepl("Take away 1 word,", conditionMessage(e10), fixed = TRUE))
ew <- caught(Oracle(c("wagon", rep("a", 8))))
check("a W is met kindly: class oracle_letter", inherits(ew, "oracle_letter") && grepl("no W|without W", conditionMessage(ew)))
check("digits are met kindly", inherits(caught(Oracle(c("1759", rep("a", 8)))), "oracle_letter"))

# ---- Steps 5-6: the marriage example, line by line (pp. 44, 48-52) -------------------------------
cat("Step 5: the grid and its numbers (p. 44, pp. 49-52)\n")
check("column A = 3 9 3 6 2 3 (the bands)", identical(unname(o1$grid[, "A"]), c(3, 9, 3, 6, 2, 3)))
check("column B = 1 6 3 3 6 6 (the grid on p. 36)", identical(unname(o1$grid[, "B"]), c(1, 6, 3, 3, 6, 6)))
nums1 <- matrix(c(18, 27, 33, 42, 57, 60,
                  27, 33, 42, 48, 57, 66,
                  15, 30, 39, 42, 54, 63,
                  21, 33, 39, 45, 57, 69,
                  13, 22, 34, 46, 55, 64,
                  15, 24, 36, 42, 54, 60), nrow = 6, byrow = TRUE)
check("the six numbers on each line, as printed on p. 44 and pp. 49-52", identical(unname(o1$numbers), nums1))

cat("Step 6: parts, cells, words (pp. 49-52, 55)\n")
GFEDCB <- c("G", "F", "E", "D", "C", "B")
check("parts where the numbers are found: G F E D C B on lines I-IV and VI, C B D E F G on line V (p. 52)",
      identical(unname(o1$parts), rbind(GFEDCB, GFEDCB, GFEDCB, GFEDCB, c("C", "B", "D", "E", "F", "G"), GFEDCB) |> unname()))
check("cells on lines V and VI as printed on p. 52 (the pamphlet prints j as i)",
      identical(unname(chartr("j", "i", o1$cells[5, ])), c("t", "+", "a", "l", "i", "a")) &&
      identical(unname(o1$cells[6, ]), c("n", "+", "u", "m", "e", "n")))
check("marriage verse: Ecce equidem licite praedicit talia numen (p. 52)",
      identical(o1$verse, c("ecce", "equidem", "licite", "praedicit", "talia", "numen")))
check("peace verse: Credo satis licite donabit foedera numen (p. 55)",
      identical(o2$verse, c("credo", "satis", "licite", "donabit", "foedera", "numen")))
check("printed form: ligatures, capital, full stop",
      identical(format_verse(o2), "Credo satis licite donabit fœdera numen."))
check("the modern spelling 'Français' gives another verse (computed, not in the pamphlet)",
      identical(Oracle("La paix sera-t-elle prochaine et avantageuse aux Français ?")$verse,
                c("forte", "petis", "iuste", "promittit", "iubila", "tempus")))

# ---- the transcribed tables ---------------------------------------------------------------------
cat("The tables (transcribed from the plate)\n")
check("Tabula prima is 9 x 18 and Tabula secunda 9 x 36, no missing cells",
      identical(dim(tabula_prima), c(9L, 18L)) && identical(dim(tabula_secunda), c(9L, 36L)) &&
      !anyNA(tabula_prima) && !anyNA(tabula_secunda))
# Every number is r + 9c + band, with c = 1..6 the column whose offset (9, 18, ..., 54) went into it and
# r in 1..9 with r = band (mod 3). Each part holds three numbers, r, r+3, r+6, of one and the same c,
# and each band uses every c exactly once.
prima_ok <- vapply(1:9, function(a) {
  v <- tabula_prima[a, ]; cc <- (v - a - 1) %/% 9; r <- (v - a - 1) %% 9 + 1
  ix <- split(seq_along(v), (seq_along(v) - 1) %/% 3)
  all((r - a) %% 3 == 0) &&
    all(vapply(ix, function(i) length(unique(cc[i])) == 1 && all(diff(r[i]) == 3), TRUE)) &&
    identical(sort(cc[c(1, 4, 7, 10, 13, 16)]), 1:6 + 0)
}, TRUE)
check("Tabula prima: 162 numbers fit the pattern r + 9c + band in every band", all(prima_ok))
reach <- vapply(1:9, function(a) all(outer(1:9, 1:6, function(x, k) mod9(3 * x + a) + 9 * k + a) %in% tabula_prima[a, ]), TRUE)
check("every number the arithmetic can produce is in its band of Tabula prima", all(reach))
check("every cell of Tabula secunda is '+', a letter or a digram", all(grepl("^([a-z]{1,2}|\\+)$", tabula_secunda)))

# Which cells do the two printed examples confirm?
used <- unique(do.call(rbind, lapply(list(o1, o2), function(o) {
  do.call(rbind, lapply(1:6, function(line) data.frame(
    band = o$grid[line, "A"], part = match(o$parts[line, ], LETTERS[2:7]), case = line)))
})))
cat(sprintf("  info  the two printed examples exercise %d of the 324 cells of Tabula secunda\n", nrow(used)))

# ---- what the verse depends on ----------------------------------------------------------------
cat("What the verse depends on\n")
set.seed(1759)
random_key <- function() sample(1:9, 9, replace = TRUE)
same_bands <- vapply(1:300, function(i) {
  g <- grid_from_triangle(mix_triangle(random_key()))
  g2 <- g; g2[, -1] <- sample(1:9, 36, replace = TRUE)          # scramble the digits of columns B-G
  identical(look_up(g, grid_numbers(g))$verse, look_up(g2, grid_numbers(g2))$verse)
}, TRUE)
check("the verse depends only on the six digits of column A: scrambling B-G changes nothing", all(same_bands))
# The edge digit of the triangle for line L is the last entry of row 10 - L, and depends on the last
# 10 - L digits of the key: the first word's key digit reaches only line I, the last one all six.
bands_of <- function(k) unname(grid_from_triangle(mix_triangle(k))[, "A"])
changed_lines <- function(pos) lapply(1:300, function(i) {
  k <- random_key(); k2 <- k; k2[pos] <- k[pos] %% 9 + 1        # change one word's key digit
  which(bands_of(k) != bands_of(k2))
})
check("changing the key digit of the first word changes line I only",
      all(vapply(changed_lines(1), identical, TRUE, 1L)))
check("changing the key digit of the sixth word can change all six lines",
      all(vapply(changed_lines(6), identical, TRUE, 1:6)))
check("changing the key digit of the last word changes all six lines",
      all(vapply(changed_lines(9), identical, TRUE, 1:6)))

# ---- the object -------------------------------------------------------------------------------
cat("The object\n")
check("Oracle() returns class 'oracle'", inherits(o1, "oracle"))
check("show.steps output shows Step 4", any(grepl("Step 4", capture.output(print(Oracle("Celui que j'aime deviendra-t-il cette année mon époux ?", show.steps = TRUE))))))

cat(if (n_fail == 0) "\nAll tests passed.\n" else sprintf("\n%d test(s) FAILED.\n", n_fail))
if (n_fail > 0) quit(status = 1)
