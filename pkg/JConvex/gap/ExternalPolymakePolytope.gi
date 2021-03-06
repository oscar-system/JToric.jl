#############################################################################
##
##  ExternalPolymakePolytope.gi  JConvex package
##                               Martin Bies
##
##  Copyright 2021               University of Pennsylvania
##
##  A Gap package to do convex geometry by Polymake, Cdd and Normaliz
##
##  Chapter Polytopes in Polymake
##
#############################################################################


##############################################################################################
##
##  Section GAP category of PolymakePolytopes
##
##############################################################################################

DeclareRepresentation( "IsPolymakePolytopeRep", IsPolymakePolytope and IsAttributeStoringRep, [ ] );

BindGlobal( "TheFamilyOfPolymakePolytopes", NewFamily( "TheFamilyOfPolymakePolytopes" ) );

BindGlobal( "TheTypeOfPolymakePolytope", NewType( TheFamilyOfPolymakePolytopes, IsPolymakePolytopeRep ) );

BindGlobal( "MakePolymakePolytopeVRep", function( vertices, lineality )
    local poly, kwargs, new_vertices, new_lin, v;
    poly := Objectify( TheTypeOfPolymakePolytope,
            rec( vertices := Immutable( vertices ),
                 lineality := Immutable( lineality ),
                 number_type := "rational",
                 rep_type := "V-rep" ) );

    # add 1s at the beginning, since Polymake always considers polytopes as intersections with the hyperplane x0 = 1
    new_vertices := [];
    for v in vertices do
        v := ShallowCopy( v );
        Add( v, 1, 1 );
        Add( new_vertices, v );
    od;
    new_lin := [];
    for v in lineality do
        v := ShallowCopy( v );
        Add( v, 1, 1 );
        Add( new_lin, v );
    od;

    kwargs := rec();

    # TODO: verify that kwargs is set correctly, also if one or both lists are empty

    # check for degenerate case
    if Length( new_vertices ) > 0 then
        kwargs.POINTS := JuliaMatrixInt( new_vertices );

        # if we also have lineality, add them
        if Length( new_lin ) > 0 then
            kwargs.INPUT_LINEALITY := JuliaMatrixInt( new_lin );
        fi;
    elif Length( new_lin ) > 0 then
        kwargs.POINTS := JuliaMatrixInt( new_lin );
        kwargs.INPUT_LINEALITY := kwargs.POINTS;
    fi;

    poly!.pmobj := CallJuliaFunctionWithKeywordArguments( _Polymake_jl.polytope.Polytope, [], kwargs );
    return poly;
end);

BindGlobal( "MakePolymakePolytopeHRep", function( inequalities, equalities )
    local poly, kwargs;
    poly := Objectify( TheTypeOfPolymakePolytope,
            rec( inequalities := Immutable( inequalities ),
                 equalities := Immutable( equalities ),
                 number_type := "rational",
                 rep_type := "H-rep" ) );

    kwargs := rec();

    # TODO: verify that kwargs is set correctly, also if one or both lists are empty

    # check for degenerate case
    if Length( inequalities ) > 0 then
        kwargs.INEQUALITIES := JuliaMatrixInt( inequalities );

        # check if we also need equalities
        if Length( equalities ) > 0 then
            kwargs.EQUATIONS := JuliaMatrixInt( equalities );
        fi;
    elif Length( equalities ) > 0 then
        kwargs.INEQUALITIES := JuliaMatrixInt( equalities );
        kwargs.EQUATIONS := kwargs.INEQUALITIES;
    fi;

    poly!.pmobj := CallJuliaFunctionWithKeywordArguments( _Polymake_jl.polytope.Polytope, [], kwargs );
    return poly;
end);


##############################################################################################
##
##  Constructors for PolymakePolytopes
##
##############################################################################################


InstallGlobalFunction( Polymake_PolytopeByGenerators,
  function( arg )
    local poly, i, matrix, temp, dim;
    
    if Length( arg )= 0 or ForAll( arg, IsEmpty ) then
        
        Error( "Wrong input: Please provide some input!" );
        
    elif Length( arg ) = 1 and IsList( arg[1] ) then
        
        return Polymake_PolytopeByGenerators( arg[ 1 ], [ ] );
        
    elif Length( arg ) = 2 and IsList( arg[ 1 ] ) and IsList( arg[ 2 ] ) then
        
        if ( not IsEmpty( arg[ 1 ] ) ) and not ( IsMatrix( arg[ 1 ] ) ) then
            Error( "Wrong input: The first argument should be a Gap matrix!" );
        fi;
        
        if ( not IsEmpty( arg[ 2 ] ) ) and not ( IsMatrix( arg[ 2 ] ) ) then
            Error( "Wrong input: The second argument should be a Gap matrix!" );
        fi;
        
        poly := MakePolymakePolytopeVRep( arg[ 1 ], arg[ 2 ] );
        return Polymake_CanonicalPolytopeByGenerators( poly );
        
    fi;
    
end );


InstallGlobalFunction( Polymake_PolytopeFromInequalities,
  function( arg )
    local poly, i, temp, matrix, dim;
    
    if Length( arg ) = 0 or ForAll( arg, IsEmpty ) then
        
        Error( "Wrong input: Please provide some input!" );
        
    elif Length( arg ) = 1 and IsList( arg[ 1 ] ) then
        
        return Polymake_PolytopeFromInequalities( arg[ 1 ], [ ] );
        
    elif Length( arg ) = 2 and IsList( arg[ 1 ] ) and IsList( arg[ 2 ] ) then
        
        if ( not IsEmpty( arg[ 1 ] ) ) and not ( IsMatrix( arg[ 1 ] ) ) then
            Error( "Wrong input: The first argument should be a Gap matrix!" );
        fi;
        
        if ( not IsEmpty( arg[ 2 ] ) ) and not ( IsMatrix( arg[ 2 ] ) ) then
            Error( "Wrong input: The second argument should be a Gap matrix!" );
        fi;
        
        poly := MakePolymakePolytopeHRep( arg[ 1 ], arg[ 2 ] );
        return Polymake_CanonicalPolytopeFromInequalities( poly );
        
    fi;
    
end );


##############################################################################################
##
##  Canonicalize polytopes
##
##############################################################################################

InstallMethod( Polymake_CanonicalPolytopeByGenerators,
               [ IsPolymakePolytope ],
  function( poly )
    local vertices, v_copy, scaled_vertices, i, scale, lineality, scaled_lineality;
    
    if poly!.rep_type = "H-rep" then
        
        return fail;
        
    else
        
        # compute vertices
        vertices := PolymakeMatrixToGAP( poly!.pmobj.VERTICES );
        
        # sometimes, Polymake returns rational vertices - we turn them into integral vectors
        # also, Polymake requires x0 = 1 in affine coordinates - we remove this 1
        scaled_vertices := [];
        for i in [ 1 .. Length( vertices ) ] do
            v_copy := ShallowCopy( vertices[ i ] );
            Remove( v_copy, 1 );
            Add( scaled_vertices, v_copy );
        od;
        
        # extract lineality
        lineality := PolymakeMatrixToGAP( poly!.pmobj.LINEALITY_SPACE );
        
        # sometimes, Polymake returns rational lineality - we turn them into integral vectors
        scaled_lineality := [];
        for i in [ 1 .. Length( lineality ) ] do
            v_copy := ShallowCopy( lineality[ i ] );
            Remove( v_copy, 1 );
            Add( scaled_lineality, v_copy );
        od;
        
        # construct the new poly
        return MakePolymakePolytopeVRep( scaled_vertices, scaled_lineality );
        
    fi;
    
end );

InstallMethod( Polymake_CanonicalPolytopeFromInequalities,
               [ IsPolymakePolytope ],
  function( poly )
    local ineqs, eqs;
    
    if poly!.rep_type = "V-rep" then
        
        return fail;
        
    else
        
        # compute facets
        ineqs := PolymakeMatrixToGAP( poly!.pmobj.FACETS );
        
        # compute affine hull
        eqs := PolymakeMatrixToGAP( poly!.pmobj.AFFINE_HULL );
        
        # construct the new poly
        return MakePolymakePolytopeHRep( ineqs, eqs );
        
    fi;
    
end );


##############################################################################################
##
##  Conversion of polytopes
##
##############################################################################################

InstallMethod( Polymake_V_Rep,
               [ IsPolymakePolytope ],
  function( poly )
    local vertices, v_copy, scaled_vertices, i, lineality, scaled_lineality;
    
    if poly!.rep_type = "V-rep" then
        
        return poly;
        
    else
        
        # compute vertices
        vertices := PolymakeMatrixToGAP( poly!.pmobj.VERTICES );
        
        # sometimes, Polymake returns rational vertices - we turn them into integral vectors
        scaled_vertices := [];
        for i in [ 1 .. Length( vertices ) ] do
            v_copy := ShallowCopy( vertices[ i ] );
            Remove( v_copy, 1 );
            Add( scaled_vertices, v_copy );
        od;
        
        # compute lineality
        lineality := PolymakeMatrixToGAP( poly!.pmobj.LINEALITY_SPACE );
        
        # sometimes, Polymake returns rational lineality - we turn them into integral vectors
        scaled_lineality := [];
        for i in [ 1 .. Length( lineality ) ] do
            v_copy := ShallowCopy( lineality[ i ] );
            Remove( v_copy, 1 );
            Add( scaled_lineality, v_copy );
        od;
        
        # construct the new poly
        return MakePolymakePolytopeVRep( scaled_vertices, scaled_lineality );
        
    fi;
    
end );


InstallMethod( Polymake_H_Rep,
               [ IsPolymakePolytope ],
  function( poly )
    local ineqs, eqs;
    
    if poly!.rep_type = "H-rep" then
        
        return poly;
        
    else
        
        if poly!.rep_type = "V-rep" and poly!.vertices = [] then
            return Polymake_PolytopeFromInequalities( [ [ 0, 1 ], [ -1, -1 ] ] );
        fi;
        
        # compute inequalities
        ineqs := PolymakeMatrixToGAP( poly!.pmobj.FACETS );
        
        # compute equalities
        eqs := PolymakeMatrixToGAP( poly!.pmobj.AFFINE_HULL );
        
        # construct the new poly
        return MakePolymakePolytopeHRep( ineqs, eqs );
        
    fi;
    
end );


##############################################################################################
##
##  Attributes of PolymakeCones
##
##############################################################################################

InstallMethod( Polymake_AmbientSpaceDimension,
              "finding the dimension of the ambient space of the poly",
              [ IsPolymakePolytope ],
  function( poly )
    
    return Length( Polymake_V_Rep( poly )!.vertices[0] );
    
end );


InstallMethod( Polymake_Dimension,
              " returns the dimension of the poly",
            [ IsPolymakePolytope ],
  function( poly )
    
    if Polymake_IsEmpty( poly ) then
        return -1;
    fi;
    
    return poly!.pmobj.CONE_DIM - 1;
    
end );


InstallMethod( Polymake_Vertices,
              " return the list of generating vertices",
              [ IsPolymakePolytope ],
  function( poly )
    
    return Set( Polymake_V_Rep( poly )!.vertices );
    
end );


InstallMethod( Polymake_Linealities,
              " return the list of linealities",
              [ IsPolymakePolytope ],
  function( poly )
    
    return Set( Polymake_V_Rep( poly )!.linealities );
    
end );


InstallMethod( Polymake_Equalities,
              " return the list of equalities of a poly",
              [ IsPolymakePolytope ],
  function( poly )
    
    return Set( ( Polymake_H_Rep( poly ) )!.equalities );
    
end );


InstallMethod( Polymake_Inequalities,
              " return the list of inequalities of a poly",
              [ IsPolymakePolytope ],
  function( poly )
    
    return Set( ( Polymake_H_Rep( poly ) )!.inequalities );
    
end );


InstallMethod( Polymake_LatticePoints,
              " return the list of the lattice points of poly",
              [ IsPolymakePolytope ],
  function( poly )
    local point_list, lattice_points, i, copy;
    
    point_list := JuliaToGAP( IsList, JuliaMatrixInt( poly!.pmobj.LATTICE_POINTS_GENERATORS[1] ), true );

    # the point list is in affine coordinate, that is we have a 1 at position one, which should be removed
    lattice_points := [];
    for i in [ 1 .. Length( point_list ) ] do
        copy := ShallowCopy( point_list[ i ] );
        Remove( copy, 1 );
        Add( lattice_points, copy );
    od;
    
    # return result
    return lattice_points;
    
end );


InstallMethod( Polymake_Intersection,
               [ IsPolymakePolytope, IsPolymakePolytope ],
  function( poly1, poly2 )
    local poly1_h, poly2_h, new_ineqs, new_equ;
    
    # compute H-reps
    poly1_h := Polymake_H_Rep( poly1 );
    poly2_h := Polymake_H_Rep( poly2 );
    
    # add the inequalities and equalities
    new_ineqs := Concatenation( poly1_h!.inequalities, poly2_h!.inequalities );
    new_equ := Concatenation( poly1_h!.equalities, poly2_h!.equalities );
    
    # return result
    return Polymake_PolytopeFromInequalities( new_ineqs, new_equ );
    
end );


##############################################################################################
##
##  Properties of PolymakeCones
##
##############################################################################################

InstallMethod( Polymake_IsEmpty,
               "finding if the poly empty is or not",
               [ IsPolymakePolytope ],
  function( poly )
    
    return Length( Polymake_V_Rep( poly )!.vertices ) = 0;
    
end );


InstallMethod( Polymake_IsPointed,
               "finding if the poly is pointed or not",
               [ IsPolymakePolytope ],
  function( poly )
    return poly!.pmobj.POINTED;
    
end );


InstallMethod( Polymake_IsBounded,
              " returns if the polytope is bounded or not",
              [ IsPolymakePolytope ],
  function( poly )
    return poly!.pmobj.BOUNDED;
    
end );
