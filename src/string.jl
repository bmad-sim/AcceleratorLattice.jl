#---------------------------------------------------------------------------------------------------
# str_split

"""
    str_split(str::AbstractString, delims::AbstractString; skip_quoted=true, limit::Integer=0) 
    str_split(str::AbstractString, delims::Vector{T}; 
                                     skip_quoted=true, limit::Integer=0) where T <: AbstractString

Function to split a string and return a vector of words. 
Unlike the standard `split` function, the output vector with `str_split` will includ delimiter terms.

## Arguments

- `delims`   This is either a vector of strings with each element being a delimiter or
  a string where each character is taken to be a delimiter. Notice that with the vector form, 
  any given delimiter may contain multiple characters. 
  In terms of matching, If there is ambiguity, the first delim in the list that is a match is used. 
  For example, if `delims` is `["<<", "<"]`, the output with `str` = `"a<<b<c"` will be `["a", "<<", "b", "<", "c"]` 
  while if `delims` is `["<", "<<"]`, the output will be `["a", "<", "", "<", "b", "<", "c"]`. 
  Notice that in the second example the fist delim `"<"` shadows the second
  delim `"<<"` so the second case is equivalent to `delims` being simply `["<"]` or `"<"`
- `skip_quoted` If `true`, delimiters within a quote block (with either single, quotes, double quotes, 
  or back ticks), will be be ignored. Quote marks themselves may be delimiters. So if `skip_quoted`
  is `true` and the quote marks around a quote block are listed as delimiters the output vector
  will have three elements for this: A quote string, the quote block without quote marks, and then
  another quote mark element.
- `limit` The maximum vector length of the output vector. `limit = 0` implies no maximum (default)
  If `limit` is non-zero, the last element in the output vector can contain a mix of delimiters
  and not-delimiters

## Notes
- A tab character is considered to be the same as a space character.
- If space is a delimiter, multiple spaces are condensed into one except within a quote block.
  Also a space is considered a "minor" delimiter and will be removed if next to another delimiter.
  For example, if `delims` is `", "`, the output vector for `str = "a, b"` will be `["a", ",", "b"]`.
- Except for blank characters, if there are two delimiters in a row, the output vector will have
  two elements representing the two delimiters with an empty string element in between.
- If the first character(s) of `str` is a non-blank delimiter, the first element of the output 
  vector will be an empty string (string of zero length). 
  If the last character(s) of `str` is a non-blank delimiter, the
  last element of the output vector will be an empty string.
""" str_split


function str_split(str::AbstractString, delims::Vector{T}; 
                               skip_quoted=true, limit::Integer=0) where T <: AbstractString

  function this_word(a_word, has_blank_delim)
    if has_blank_delim
      return strip(a_word)
    else
      return a_word
    end
  end

  #

  if limit == 1; return [str]; end
  if limit < 0; error("`limit` argument cannot be negative: $limit"); end

  has_blank_delim = (" " in delims)
  if has_blank_delim; str = strip(str); end

  words = []
  ix1_word = 1      # Start index of current word
  quote_mark = ' '  # Blank means not in a quote block
  n_skip = 0        # Characters to skip for a multi-character delim.
  n_str = length(str)

  #

  for (indx, c) in enumerate(str)

    if n_skip > 0
      n_skip -= 1
      continue
    end

    

    #

    if skip_quoted
      if c == '"' || c == '\'' || c == '`'
        if quote_mark == ' '
          quote_mark = c
        elseif c == quote_mark
         quote_mark = ' '
        end
      end  
    end

    #

    if has_blank_delim && c == ' ' && quote_mark == ' ' && length(words) > 0  && words[end] == " " && str[ix1_word] == ' '
      ix1_word += 1

    elseif !skip_quoted || quote_mark == ' ' || quote_mark == c
      for delim in delims
        if c != delim[1]; continue; end

        n = length(delim)
        if n > 1 && (indx+n-1 > n_str || delim[2:end] != str[indx+1:indx+n-1]) continue; end

        push!(words, this_word(str[ix1_word:indx-1], has_blank_delim))

        if limit > 0 && length(words) == limit - 1
          push!(words, this_word(str[indx:end], has_blank_delim))
          return words
        end

        ix1_word = indx + n
        push!(words, delim)
        n_skip = n - 1

        if limit > 0 && length(words) == limit - 1
          push!(words, this_word(str[ix1_word:end], has_blank_delim))
          return words
        end

        if indx+n-1 == n_str
          push!(words, "")
          return words
        end

        break
      end
    end

  end

  if ix1_word <= n_str && (limit == 0 || length(words) < limit)
    push!(words, this_word(str[ix1_word:n_str], has_blank_delim))
  end

  return words
end

#

function str_split(str::AbstractString, delims::AbstractString; skip_quoted=true, limit::Integer=0)
  str_split(str, [string(z) for z in delims], skip_quoted = skip_quoted, limit = limit)
end

#---------------------------------------------------------------------------------------------------
# str_match

"""
    str_match(pattern::AbstractString, who::AbstractString)::Bool

Function to match a string against a regular expression using the Bmad standard wild cards. 
The whole string is matched to by inserting `"^"` and `"\$"` at the ends of the search pattern.

## Wild card characters are:
- `"*"`  -- Match to any number of characters.
- `"%"`  -- Match to any single character.

To search for a literal `"*"` or `"%"` in a string prefix in `pattern` using a double backslash `"\\\\"`.

Output:  true/false
""" str_match

function str_match(pattern::AbstractString, who::AbstractString)
  if !occursin("*", pattern) && !occursin("%", pattern); return pattern == who; end

  pattern = replace(pattern, "." => "\\.", "\\*" => "sTaR", "\\%" => "pErCeNt")
  pattern = replace(pattern, "*" => ".*", "%" => ".")
  pattern = replace(pattern, "sTaR" => "\\*", "pErCeNt" => "\\%")
  re = Regex("^" * pattern * "\$")
  return !isnothing(match(re, who))
end

#---------------------------------------------------------------------------------------------------
# str_unquote

"""
    str_unquote(str::AbstractString)

Returns string with end quote characters (if they are the same) removed.
""" str_unquote

function str_unquote(str::AbstractString)
  if size(str,1) < 2; return str; end
  if str[1] == str[end] && str[1] in "\"'"
    return str[2:end-1]
  else
    return str
  end
end

#---------------------------------------------------------------------------------------------------
# str_quote

"""
    str_quote(str::AbstractString) 

Returns string with end double-quote characters added
""" str_quote

str_quote(str::AbstractString) = '"' * str * '"'

#---------------------------------------------------------------------------------------------------
# integer

"""
    integer(str::AbstractString, default = nothing)
    integer(str::AbstractString)

Converts a string to an integer. Throws an error if `default` is `nothing`.
""" integer

function integer(str::AbstractString, default)
  try
    return parse(Int, str)
  catch
    if isnothing(default)
      error(f"ParseError: Bad integer: {str}")
    else
      return default
    end
  end
end

#

integer(str::AbstractString) = integer(str, nothing)
