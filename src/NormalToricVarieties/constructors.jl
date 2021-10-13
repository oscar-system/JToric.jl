######################
# 1: The Julia type for ToricVarieties
######################
abstract type AbstractNormalToricVariety end

struct NormalToricVariety <: AbstractNormalToricVariety
           polymakeNTV::Polymake.BigObject
end
export NormalToricVariety

struct AffineNormalToricVariety <: AbstractNormalToricVariety
           polymakeNTV::Polymake.BigObject
end
export AffineNormalToricVariety


function pm_ntv(v::AbstractNormalToricVariety)
    return v.polymakeNTV
end

######################
# 2: Generic constructors
######################
@doc Markdown.doc"""
    NormalToricVariety(PF::PolyhedralFan)

Construct the normal toric variety $X_{PF}$ corresponding to a polyhedral fan `PF`.

# Examples
Take `PF` to be the normal fan of the square.
```jldoctest
julia> square = Oscar.cube(2)
A polyhedron in ambient dimension 2

julia> nf = Oscar.normal_fan(square)
A polyhedral fan in ambient dimension 2

julia> ntv = NormalToricVariety(nf)
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2
```
"""    
function NormalToricVariety(PF::PolyhedralFan)
    pmntv = Polymake.fulton.NormalToricVariety(Oscar.pm_fan(PF))
    return NormalToricVariety(pmntv)
end


@doc Markdown.doc"""
    AffineNormalToricVariety(C::Cone)

Construct the affine normal toric variety $U_{C}$ corresponding to a polyhedral
cone `C`.

# Examples
Set `C` to be the positive orthant in two dimensions.
```jldoctest
julia> C = Oscar.positive_hull([1 0; 0 1])
A polyhedral cone in ambient dimension 2

julia> antv = AffineNormalToricVariety(C)
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2
```
"""
function AffineNormalToricVariety(C::Cone)
    pmc = Oscar.pm_cone(C)
    fan = Polymake.fan.check_fan_objects(pmc)
    pmntv = Polymake.fulton.NormalToricVariety(fan)
    return AffineNormalToricVariety(pmntv)
end


@doc Markdown.doc"""
    NormalToricVariety(P::Polyhedron)

Construct the normal toric variety $X_{\Sigma_P}$ corresponding to the normal
fan $\Sigma_P$ of the given polyhedron `P`.

Note that this only coincides with the projective variety associated to `P`, if
`P` is normal.

# Examples
Set `P` to be a square.
```jldoctest
julia> square = Oscar.cube(2)
A polyhedron in ambient dimension 2

julia> ntv = NormalToricVariety(square)
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2
```
"""    
function NormalToricVariety(P::Polyhedron)
    fan = normal_fan(P)
    return NormalToricVariety(fan)
end


@doc Markdown.doc"""
    NormalToricVariety(C::Cone)

Construct the (affine) normal toric variety $X_{\Sigma}$ corresponding to a
polyhedral fan $\Sigma = C$ consisting only of the cone `C`.

# Examples
Set `C` to be the positive orthant in two dimensions.
```jldoctest
julia> C = Oscar.positive_hull([1 0; 0 1])
A polyhedral cone in ambient dimension 2

julia> ntv = NormalToricVariety(C)
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2
```
"""
function NormalToricVariety(C::Cone)
    pmc = Oscar.pm_cone(C)
    fan = Oscar.Polymake.fan.check_fan_objects(pmc)
    pmntv = Oscar.Polymake.fulton.NormalToricVariety(fan)
    return NormalToricVariety(pmntv)
end





######################
# 3: Standard constructions
######################

@doc Markdown.doc"""
    projective_space( d::Int )

Construct the projective space of dimension `d`.

# Examples
```jldoctest
julia> projective_space( 2 )
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2
```
"""
function projective_space( d::Int )
    return NormalToricVariety(Polymake.fulton.projective_space(d))
end
export projective_space


@doc Markdown.doc"""
    hirzebruch_surface( r::Int )

Constructs the r-th Hirzebruch surface.

# Examples
```jldoctest
julia> hirzebruch_surface( 5 )
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2
```
"""
function hirzebruch_surface( r::Int )
    return NormalToricVariety(Polymake.fulton.hirzebruch_surface(r))
end
export hirzebruch_surface


@doc Markdown.doc"""
    delPezzo( b::Int )

Constructs the delPezzo surface with b blowups for b at most 3.

# Examples
```jldoctest
julia> del_pezzo( 3 )
A normal toric variety corresponding to a polyhedral fan in ambient dimension 2
```
"""
function del_pezzo( b::Int )
    if b < 0
        throw(ArgumentError("Number of blowups for construction of delPezzo surfaces must be non-negative."))
        return 0
    end
    if b == 0 
        return projective_space( 2 )
    end
    if b == 1
        Rays = [ 1 0; 0 1; -1 0; -1 -1 ]
        Cones = IncidenceMatrix([ [1,2],[2,3],[3,4],[4,1] ])
        return NormalToricVariety(Oscar.PolyhedralFan(Rays, Cones))
    end
    if b == 2
        Rays = [ 1 0; 0 1; -1 0; -1 -1; 0 -1 ]
        Cones = IncidenceMatrix([ [1,2],[2,3],[3,4],[4,5],[5,1] ])
        return NormalToricVariety(Oscar.PolyhedralFan(Rays, Cones))
    end
    if b == 3
        Rays = [ 1 0; 1 1; 0 1; -1 0; -1 -1; 0 -1 ]
        Cones = IncidenceMatrix([ [1,2],[2,3],[3,4],[4,5],[5,6],[6,1] ])
        return NormalToricVariety(Oscar.PolyhedralFan(Rays, Cones))
    end
    if b > 3
        throw(ArgumentError("delPezzo surfaces with more than 3 blowups are realized as subvarieties of toric ambient spaces. This is currently not supported."))
        return 0
    end
end
export del_pezzo


###############################################################################
###############################################################################
### Display
###############################################################################
###############################################################################
function Base.show(io::IO, ntv::AbstractNormalToricVariety)
    # fan = get_polyhedral_fan(ntv)
    pmntv = pm_ntv(ntv)
    ambdim = pmntv.FAN_AMBIENT_DIM
    print(io, "A normal toric variety corresponding to a polyhedral fan in ambient dimension $(ambdim)")
end
