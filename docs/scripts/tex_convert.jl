file = "design"

lines = readlines("../manual/" * file * ".tex", keep = true)
fout = open("src/" * file * ".md", "w")

#--------------------------------------------------

function sub_str(str, left, right)
  if !occursin(left, str); return ""; end
  str = split(str, left)[2]
  if !occursin(right, str); return str; end
  return split(str, right)[1]
end

#--------------------------------------------------

function str_replace(line, end_line = true)
  line = replace(line, "``" => "\"", "''" => "\"")   # ``abc'' -> "abc"  This must be before other replacements.
  line = replace(line, r"\\item\[(.*?)\]" => s"- **\1**")
  line = replace(line, r"\\begin{example}" => "```{code} yaml")
  line = replace(line, r"\\end{example}" => "```")
  line = replace(line, r"\\vn{(.*?)}" => s"`\1`")                # "\vn{XXX}" -> "`XXX`"
  line = replace(line, r"\\accellat" => "AcceleratorLattice")
  line = replace(line, r"\\scibmad" => "SciBmad")
  line = replace(line, r"\\bmad" => "Bmad")
  line = replace(line, r"\\julia" => "Julia")
  line = replace(line, r"\\sref{(.*?)}" => s"[](#\1)")
  line = replace(line, r"\\ref{(.*?)}" => s"[](#\1)")
  line = replace(line, r"\\fig{(.*?)}" => s"{numref}`\1`")
  line = replace(line, r"\\cite{([^}]*?),([^}]*?)}" => s"{footcite:p}`\1;\2`")
  line = replace(line, r"\\cite{(.*?)}" => s"{footcite:p}`\1`")
  line = replace(line, r"\\calO" => "\\cal O", r"\\bfr" => "{\\bf r}")
  line = replace(line, r"\\\\" => "")
  if occursin("\$", line)
    words = split(line, "\$")
    line = ""
    for n in 1:2:length(words)-1
      line *= words[n] * "{math}`" * words[n+1] * "`"
    end
    if isodd(length(words)); line *= words[end]; end
  end

  if end_line
    return line * "\n"
  else
    return line
  end
end

#--------------------------------------------------

nn = 0
while nn < length(lines)
  global nn += 1
  line = strip(lines[nn])

  #------------

  if startswith(line, "\\chapter")
    line = replace(line, "\\chapter{" => "# ", "}" => "")

    line2 = lines[nn+1]
    if startswith(line2, "\\label")
      line2 = replace(line2, "\\label{" => "(", "}" => ")=")
      write(fout, line2)
      write(fout, line)
      nn += 1
    else
      write(fout, "(c:X)=\n")
      write(fout, line)
    end

    continue
  end

  #------------

  if startswith(line, "\\section") ||startswith(line, "\\subsection")
    line = "## " * sub_str(line, "section{", "}")

    line2 = lines[nn+1]
    if startswith(line2, "\\label")
      line2 = replace(line2, "\\label{" => "(", "}" => ")=")
      write(fout, line2)
      write(fout, line)
      nn += 1
    else
      write(fout, "(s:X)=\n")
      write(fout, line)
    end

    continue
  end

  #------------

  if strip(line) == "\\item"
    lines[nn+1] = "- " * lines[nn+1]
    continue
  end

  #------------

  if startswith(line, "\\begin{tabular}")

    if occursin("indnt", lines[nn+2])
      nn += 1
      prefix = strip(split(lines[nn])[1])

      while true
        nn += 1
        line = strip(lines[nn])
        if startswith(line, "\\end{tabular}"); break; end
 
        suffix = strip(sub_str(line, "\\indnt", "&"))
        doc = strip(sub_str(line, "--", "\\"))
        write(fout, "- $prefix$suffix  - $doc\n")
      end

    elseif occursin("& --", lines[nn+1])
      while true
        nn += 1
        line = strip(lines[nn])
        if startswith(line, "\\end{tabular}"); break; end
        if startswith(line, "\\bottomrule"); break; end
        words = split(line, "&")
        who = words[1]
        doc = strip(sub_str(words[2], "--", "\\\\"))
        write(fout, "- $who  - $doc\n")
      end

    else
      write(fout, "Need custom handling!!!!\n")
    end

    continue
  end


  #------------

  if startswith(line, "\\begin{table}")
    write(fout, "```{csv-table}\n")
    write(fout, ":align: center\n")

    while true
      nn += 1
      line = strip(lines[nn])
      if startswith(line, "\\end{table}"); break; end

      if startswith(line, "{\\tt"); continue; end
      if startswith(line, "\\centering"); continue; end
      if startswith(line, "}"); continue; end
      if startswith(line, "\\end{tabular}"); continue; end
      if startswith(line, "\\caption"); continue; end
      if startswith(line, "\\label"); continue; end
      if startswith(line, "\\bottomrule"); continue; end
      if startswith(line, "\\midrule"); continue; end

      if startswith(line, "\\begin{tabular}")
        nn += 1
        line = lines[nn]
        write(fout, ":header: \"Element\", \"Element\"\n")
        continue
      end

      words = split(line, "&")
      lab1 = sub_str(words[2], "ref{", "}")
      lab2 = sub_str(words[4], "ref{", "}")
      write(fout, "[$(strip(words[1]))](#$lab1), [$(strip(words[3]))](#$lab2)\n")
    end

    write(fout, "```\n")
    continue
  end

  #------------
  # Figure

  if startswith(line, "\\begin{figure}")
    while true
      nn += 1
      line = strip(lines[nn])
      if startswith(line, "\\end{figure}"); break; end
      if startswith(line, "\\centering"); continue; end

      if startswith(line, "\\label")
        write(fout, ":name: $(sub_str(line, "\\label{", "}"))\n")
        continue
      end

      if startswith(line, "\\includegraphics")
        line = replace(line, r"\[.*?\]" => "")
        write(fout, "```{figure} figures/$(sub_str(line, "includegraphics{", ".pdf}")).svg\n")
        continue
      end

      write(fout, str_replace(line))
    end
    write(fout, "```\n")
    continue
  end

  #------------
  # Ele parameter groups in ele-types.tex

  if startswith(line, "\\TOPrule");
    nn += 1  # Skip "\begin{example}"

    while true
      nn += 1
      line = lines[nn]
      if startswith(line, "\\end"); break; end
      if startswith(line, "\\centering"); continue; end

      words = split(line, "->")
      ws2 = split(words[2], "\\sref{")
      w1 = strip(words[1])
      w2 = strip(split(ws2[2], "}")[1])
      w3 = strip(ws2[1])
      write(fout, "- [**$w1**](#$w2): $w3\n")
    end

    nn += 1
    continue
  end

  #------------

  if startswith(line, "\\newpage"); continue; end
  if startswith(line, "\\begin{description}"); continue; end
  if startswith(line, "\\end{description}"); continue; end
  if startswith(line, "\\vspace"); continue; end
  if startswith(line, "\\hfill"); continue; end
  if line == "{tt"; continue; end
  if line == "}"; continue; end
  if line == "\\end{tabular}"; continue; end

  line = str_replace(line)
  write(fout, line)
end

write(fout, "```{footbibliography}\n")
write(fout, "```\n")

close(fout)