-- Footnotes variant: a narrative citation such as "Buehler [-@Buehler2026]" would suppress the
-- author inside the footnote; keep the author there (the name stays in the running text).
function Cite(c)
  for _, cit in ipairs(c.citations) do
    if cit.mode == "SuppressAuthor" then cit.mode = "NormalCitation" end
  end
  return c
end
