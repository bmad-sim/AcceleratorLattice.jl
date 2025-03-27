(c:new.ele)=
# Defining New Lattice Elements
%---------------------------------------------------------------------------------------------------
(s:X)=
## Defining new Element Parameters
* Bookkeeping

%---------------------------------------------------------------------------------------------------
(s:new.ele)=
## Defining a New Element
To construct a new element type:

* Define a new element type. Example:
```{code} yaml
@construct_ele_type NewEleType
```

* Extend EleGeometry Holy trait group ([](#s:holy)) if a new geometry is needed. Example:
```{code} yaml
abstract type CORKSCREW <: EleGeometry end
```

* If the geometry is not `STRAIGHT`, Extend the `ele_geometry()` function to return the
correct geometry for the new type of element. Example:
```{code} yaml
ele_geometry(ele::NewEleType) = CORKSCREW
```

* If the element has a new type of geometry, extend the `propagate_ele_geometry()` function
to handle the new type of geometry. Example:
```{code} yaml
function propagate_ele_geometry(::Type{CORKSCREW}, fstart::FloorParams, ele::Ele)
...
return floor_end  # FloorParams at the downstream end of the element.
end
```


%---------------------------------------------------------------------------------------------------

```{footbibliography}
```
