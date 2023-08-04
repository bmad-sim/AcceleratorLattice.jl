#-----------------------------------------------------------------------------------------
# str_split

"""
Function to split a string and return a vector of words. 
Included in the vector are elements of the delimiters.

delim is a string where each character is a delimiter.

If group_quotation = true, a quote block (with either single or double quotes), 
including the end quotes, will be a single item in the output vector.

If space is a delimiter, multiple spaces are condensed into one except within a quote block.

 * doubleup: If true (default), for all delimiters except for spaces, two like delimiters in a
row will be combined into one in the output vector. For example, 
  word_split("a>b>>c", ">", doubleup = true)
will return
  ["a", ">", "b", ">>", "c"]

   •  limit: the maximum size of the result. limit=0 implies no maximum (default)
"""
function str_split(str::AbstractString, delims::AbstractString; doubleup=false, group_quotation=true, limit::Integer=0)
  words = []
  this_word = ""
  quote_mark = ' '  # Blank means not in a quote block
  at_end = false

  for s in str
    if at_end
      this_word = this_word * s

    elseif group_quotation && quote_mark == ' ' && (s == '"' || s == '\'')
      if this_word != ""; push!(words, this_word); end
      if limit > 0 && size(words,1) == limit-1; at_end = true; continue; end
      this_word = s
      quote_mark = s

    elseif quote_mark != ' '  # Can only happen if group_quotation = true
      this_word = this_word * s
      if s == quote_mark 
        push!(words, this_word)
        this_word = ""
        quote_mark = ' '
        if limit > 0 && size(words,1) == limit-1; at_end = true; end
      end

    elseif s in delims
      if doubleup && this_word == "" && s != ' ' && size(words, 1) > 0 && words[end] == string(s)
        words[end] = s * s

      elseif s == ' ' && size(words, 1) > 0 && words[end] == " "
       continue

      else
        if this_word != ""
          push!(words, this_word)
          this_word = ""
        end

        if limit > 0 && size(words,1) == limit-1
          at_end = true
          this_word = s
        else
          push!(words, string(s))
        end
      end

    else
      this_word = this_word * s
    end
  end

  if this_word != ""; push!(words, this_word); end
  if quote_mark != ' '; throw(BmadParseError("Unbalanced quotation marks in: " * str)); end

  return words
end

#-----------------------------------------------------------------------------------------
# str_match

"""
Function to match a string against a regular expression using the Bmad standard wild cards. 
The whole string is matched to by inserting "^" and "\$" at the ends of the search pattern.

Wild card characters are:
 "*"  -- Match to any number of characters.
 "%"  -- Match to any single character.

To use literal "*" and "%" in a string 

Output:  true/false
"""

function str_match(pattern::AbstractString, who::AbstractString)
  if !occursin("*", pattern) && !occursin("%", pattern); return pattern == who; end

  pattern = replace(pattern, "." => "\\.", "\\*" => "sTaR", "\\%" => "pErCeNt")
  pattern = replace(pattern, "*" => ".*", "%" => ".")
  pattern = replace(pattern, "sTaR" => "\\*", "pErCeNt" => "\\%")
  re = Regex("^" * pattern * "\$")
  println(string(re))
  return !isnothing(match(re, who))
end

#-----------------------------------------------------------------------------------------
# str_unquote

"""
Returns string with end quote characters (if they are the same) removed.
"""
function str_unquote(str::AbstractString)
  if size(str,1) < 2; return str; end
  if str[1] == str[end] && str[1] in "\"'"
    return str[2:end-1]
  else
    return str
  end
end

#-----------------------------------------------------------------------------------------
# str_quote

"""
Returns string with end double-quote characters added
"""
str_quote(str::AbstractString) = '"' * str * '"'

#-----------------------------------------------------------------------------------------
# str_to_int

"""
Converts a string to an integer
"""
function str_to_int(str::AbstractString, default = nothing)
  try
    return parse(Int, str)
  catch
    if default == nothing
      throw(BmadParseError("Bad integer: " * str))
    else
      return default
    end
  end
end