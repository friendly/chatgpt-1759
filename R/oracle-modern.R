# Ask Migneret's Oracle a modern question. Run from anywhere: Rscript oracle-modern.R
#
# The Oracle only accepts Migneret's 23-letter 18th-century alphabet (no W), so an English
# question about a "war" cannot even be typed in; French, like Antoine's own two examples,
# sidesteps the problem. Each question below is exactly nine words (Migneret's own rule; a
# euphonic "-t-" stays with the word before it) and was chosen, then run, not the reverse.

args <- commandArgs(FALSE)
here <- dirname(sub("^--file=", "", args[grep("^--file=", args)]))
if (length(here) == 0) here <- "."
source(file.path(here, "oracle.R"), encoding = "UTF-8")

ask <- function(question, gloss) {
  cat("Q: ", question, "\n", sep = "")
  cat("A: ", format_verse(Oracle(question)), "\n", sep = "")
  cat("   ", gloss, "\n\n", sep = "")
}

ask("Cette intelligence artificielle deviendra-t-elle vraiment un jour consciente ?",
    "Will artificial intelligence ever truly become conscious?")

ask("Cette guerre cruelle en Ukraine prendra-t-elle bientôt fin ?",
    "Will this cruel war in Ukraine soon come to an end?")

ask("Ce réchauffement climatique menacera-t-il gravement notre avenir commun ?",
    "Will global warming seriously threaten our common future?")

ask("Ce prochain scrutin présidentiel changera-t-il notre avenir commun ?",
    "Will the next presidential election change our common future?")
