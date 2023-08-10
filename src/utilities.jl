#-------------------------------------------------------------------------------------

"""
Returns the length in characters of the string representation of a Symbol.
Here the string representation includes the leading colon.
Example: length(:abc) => 4
"""

Base.length(sym::Symbol) = length(repr(sym))