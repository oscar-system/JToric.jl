#############################################################################
##
##  ExternalPolymakeCone.gi      JConvex package
##                               Martin Bies
##
##  Copyright 2021               University of Pennsylvania
##
##  A Gap package to do convex geometry by Polymake
##
##  Chapter Cones in Polymake
##
#############################################################################


##############################################################################################
##
##  Section GAP category of PolymakeCones
##
##############################################################################################

DeclareRepresentation( "IsPolymakeConeRep", IsPolymakeCone and IsAttributeStoringRep, [ ] );

BindGlobal( "TheFamilyOfPolymakeCones", NewFamily( "TheFamilyOfPolymakeCones" ) );

BindGlobal( "TheTypeOfPolymakeCone", NewType( TheFamilyOfPolymakeCones, IsPolymakeConeRep ) );

BindGlobal( "JuliaMatrixInt", JuliaEvalString("Matrix{BigInt}") );

BindGlobal( "PolymakeMatrixToGAP", function( mat )
    mat := _Polymake_jl.common.primitive( mat ); # ensure integer coeffs
    return JuliaToGAP( IsList, JuliaMatrixInt( mat ), true );
end );

BindGlobal( "MakePolymakeConeVRep", function( rays, lineality )
    local cone, kwargs;
    cone := Objectify( TheTypeOfPolymakeCone,
            rec( rays := Immutable( rays ),
                 lineality := Immutable( lineality ),
                 number_type := "rational",
                 rep_type := "V-rep" ) );

    kwargs := rec();

    # TODO: verify that kwargs is set correctly, also if one or both lists are empty

    # check for degenerate case
    if Length( rays ) > 0 then
        kwargs.INPUT_RAYS := JuliaMatrixInt( rays );

        # if we also have lineality, add them
        if Length( lineality ) > 0 then
            kwargs.INPUT_LINEALITY := JuliaMatrixInt( lineality );
        fi;
    elif Length( lineality ) > 0 then
        kwargs.INPUT_RAYS := JuliaMatrixInt( lineality );
        kwargs.INPUT_LINEALITY := kwargs.INPUT_RAYS;
    fi;

    cone!.pmobj := CallJuliaFunctionWithKeywordArguments( _Polymake_jl.polytope.Cone, [], kwargs );
    return cone;
end);

BindGlobal( "MakePolymakeConeHRep", function( inequalities, equalities )
    local cone, kwargs;
    cone := Objectify( TheTypeOfPolymakeCone,
            rec( inequalities := Immutable( inequalities ),
                 equalities := Immutable( equalities ),
                 number_type := "rational",
                 rep_type := "H-rep" ) );

    kwargs := rec();

    # TODO: verify that kwargs is set correctly, also if one or both lists are empty

    # check for degenerate case
    if Length( inequalities ) > 0 then
        kwargs.INEQUALITIES := JuliaMatrixInt( inequalities );

        # if we have non-zero equalities, add them
        if Length( equalities ) > 0 then
            kwargs.EQUATIONS := JuliaMatrixInt( equalities );
        fi;
    elif Length( equalities ) > 0 then
        kwargs.INEQUALITIES := JuliaMatrixInt( equalities );
        kwargs.EQUATIONS := kwargs.INEQUALITIES;
    fi;

    cone!.pmobj := CallJuliaFunctionWithKeywordArguments( _Polymake_jl.polytope.Cone, [], kwargs );
    return cone;
end);


##############################################################################################
##
##  Constructors for PolymakeCones
##
##############################################################################################

InstallGlobalFunction( Polymake_ConeByGenerators,
  function( arg )
    local given_rays, i, given_lineality, cone;
    
    if Length( arg ) = 0 then
        
        Error( "Wrong input: Please provide some input!" );
        
    elif Length( arg ) = 1 and IsList( arg[1] ) then
        
        given_rays := Filtered( arg[ 1 ], row -> not IsZero( row ) );
        if Length( given_rays ) > 0 then
            
            # non-trivial cone
            return Polymake_ConeByGenerators( arg[ 1 ], [ ] );
            
        else
            
            # received the trivial cone
            cone := MakePolymakeConeVRep( [ ], [ ] );
            return cone;
            
        fi;
        
    elif Length( arg ) = 2 and IsList( arg[ 1 ] ) and IsList( arg[ 2 ] ) then
        
        if ( not IsEmpty( arg[ 1 ] ) ) and not ( IsMatrix( arg[ 1 ] ) ) then
            Error( "Wrong input: The first argument should be a Gap matrix!" );
        fi;
        
        if ( not IsEmpty( arg[ 2 ] ) ) and not ( IsMatrix( arg[ 2 ] ) ) then
            Error( "Wrong input: The second argument should be a Gap matrix!" );
        fi;
        
        given_rays := Filtered( arg[ 1 ], row -> not IsZero( row ) );
        given_lineality := Filtered( arg[ 2 ], row -> not IsZero( row ) );
        cone := MakePolymakeConeVRep( given_rays, given_lineality );
        return Polymake_CanonicalConeByGenerators( cone );
        
    fi;
    
end );

InstallGlobalFunction( Polymake_ConeFromInequalities,
  function( arg )
    local given_ineqs, given_eqs, cone;
    
    if Length( arg ) = 0 or ForAll( arg, IsEmpty ) then
        
        Error( "Wrong input: Please provide some input!" );
        
    elif Length( arg ) = 1 and IsList( arg[ 1 ] ) then
        
        return Polymake_ConeFromInequalities( arg[ 1 ], [ ] );
        
    elif Length( arg ) = 2 and IsList( arg[ 1 ] ) and IsList( arg[ 2 ] ) then
        
        if ( not IsEmpty( arg[ 1 ] ) ) and not ( IsMatrix( arg[ 1 ] ) ) then
            Error( "Wrong input: The first argument should be a Gap matrix!" );
        fi;
        
        if ( not IsEmpty( arg[ 2 ] ) ) and not ( IsMatrix( arg[ 2 ] ) ) then
            Error( "Wrong input: The second argument should be a Gap matrix!" );
        fi;
        
        given_ineqs := Filtered( arg[ 1 ], row -> not IsZero( row ) );
        given_eqs := Filtered( arg[ 2 ], row -> not IsZero( row ) );
        cone := MakePolymakeConeHRep( given_ineqs, given_eqs );
        return Polymake_CanonicalConeFromInequalities( cone );
        
    fi;
    
end );


##############################################################################################
##
##  Canonicalize cones
##
##############################################################################################

InstallMethod( Polymake_CanonicalConeByGenerators,
               [ IsPolymakeCone ],
  function( cone )
    local rays, lineality;
    
    if cone!.rep_type = "H-rep" then
        
        return fail;
        
    else
        
        # compute rays
        rays := PolymakeMatrixToGAP( cone!.pmobj.RAYS );
        
        # extract lineality
        lineality := PolymakeMatrixToGAP( cone!.pmobj.LINEALITY_SPACE );
        
        # construct the new cone
        return MakePolymakeConeVRep( rays, lineality );
        
    fi;
    
end );

InstallMethod( Polymake_CanonicalConeFromInequalities,
               [ IsPolymakeCone ],
  function( cone )
    local ineqs, eqs;
    
    if cone!.rep_type = "V-rep" then
        
        return fail;
        
    else
        
        # compute facets
        ineqs := PolymakeMatrixToGAP( cone!.pmobj.FACETS );
        
        # compute linear span
        eqs := PolymakeMatrixToGAP( cone!.pmobj.LINEAR_SPAN );
        
        # construct the new cone
        return MakePolymakeConeHRep( ineqs, eqs );
        
    fi;
    
end );


##############################################################################################
##
##  Conversion of cones
##
##############################################################################################

InstallMethod( Polymake_V_Rep,
               [ IsPolymakeCone ],
  function( cone )
    local rays, lineality;
    
    if cone!.rep_type = "V-rep" then
        return cone;
    else
        
        # compute rays
        rays := PolymakeMatrixToGAP( cone!.pmobj.RAYS );
        
        # extract lineality
        lineality := PolymakeMatrixToGAP( cone!.pmobj.LINEALITY_SPACE );
        
        # construct the new cone
        return MakePolymakeConeVRep( rays, lineality );
        
    fi;
    
end );

InstallMethod( Polymake_H_Rep,
               [ IsPolymakeCone ],
  function( cone )
    local ineqs, eqs;
    
    if cone!.rep_type = "H-rep" then
        
        return cone;
        
    else
        
        if cone!.rep_type = "V-rep" and cone!.rays = [] then
            return Polymake_ConeFromInequalities( [ [ 0, 1 ], [ -1, -1 ] ] );
        fi;
        
        # compute facets
        ineqs := PolymakeMatrixToGAP( cone!.pmobj.FACETS );
        
        # compute linear span
        eqs := PolymakeMatrixToGAP( cone!.pmobj.LINEAR_SPAN );
        
        # construct the new cone
        return MakePolymakeConeHRep( ineqs, eqs );
        
    fi;
    
end );


##############################################################################################
##
##  Attributes of cones
##
##############################################################################################

InstallMethod( Polymake_AmbientSpaceDimension,
              "finding the dimension of the ambient space of the cone",
              [ IsPolymakeCone ],
  function( cone )
    
    return Length( Polymake_V_Rep( cone )!.rays[1] );
    
end );


InstallMethod( Polymake_Dimension,
              " returns the dimension of the cone",
            [ IsPolymakeCone ],
  function( cone )
    
    if Polymake_IsEmpty( cone ) then 
        return -1;
    fi;
    
    return cone!.pmobj.CONE_DIM;
    
end );


InstallMethod( Polymake_Rays,
              " return the list of generating vertices",
              [ IsPolymakeCone ],
  function( cone )
    
    return Set( Polymake_V_Rep( cone )!.rays );
    
end );


InstallMethod( Polymake_Lineality,
              " return the list of generating vertices",
              [ IsPolymakeCone ],
  function( cone )
    
    return Set( Polymake_V_Rep( cone )!.lineality );
    
end );


InstallMethod( Polymake_Equalities,
              " return the list of equalities of a cone",
              [ IsPolymakeCone ],
  function( cone )
    
    return Set( ( Polymake_H_Rep( cone ) )!.equalities );
    
end );


InstallMethod( Polymake_Inequalities,
              " return the list of inequalities of a cone",
              [ IsPolymakeCone ],
  function( cone )
    
    return Set( ( Polymake_H_Rep( cone ) )!.inequalities );
    
end );


InstallMethod( Polymake_RaysInFacets,
              " returns the incident matrix of the rays in the facets",
            [ IsPolymakeCone ],
  function( cone )
    local help_cone, s, res_string, number_rays, ray_list, i, dummy, j, helper;
    
    help_cone := Polymake_V_Rep( cone );
    number_rays := Length( help_cone!.rays );
    s := JuliaToGAP( IsString, Julia.string( help_cone!.pmobj.RAYS_IN_FACETS ) );
    
    # process the string
    res_string := SplitString( s, '\n' );
    res_string := List( [ 2 .. Length( res_string ) ], i -> EvalString( res_string[ i ] ) );
    
    # now construct list of rays -- each facets is a list number_rays entries: 0 indicates that the ray generator is not in the facet and a 1 that it is part of the facet
    ray_list := [];
    for i in [ 1 .. Length( res_string ) ] do
        dummy := List( [ 1 .. number_rays ], i -> 0 );
        for j in [ 1 .. Length( res_string[ i ] ) ] do
            dummy[ res_string[ i ][ j ] ] := 1;
        od;
        Append( ray_list, [ dummy ] );
    od;
    
    # return the result
    return ray_list;
    
end );

InstallMethod( Polymake_RaysInFaces,
              " returns the incident matrix of the rays in the faces",
            [ IsPolymakeCone ],
  function( cone )
    local dim, help_cone, rays, rays_in_faces, i, generators, additional_rays, j, converted_additional_rays, pos, pos2, k, help_list;
    
    # check degenerate case
    dim := Polymake_Dimension( cone );
    if ( dim = 2 ) then
        
        rays_in_faces := Polymake_RaysInFacets( cone );
        
    else
        
        # compute a V-representation of the cone
        help_cone := Polymake_V_Rep( cone );
        
        # read-off the rays and the list of rays in the facets
        rays := help_cone!.rays;
        rays_in_faces := Polymake_RaysInFacets( help_cone );
        
        # construct the facets as cones, compute their facets and add them
        # this is thus a recursive function, with (presumably) low performance
        for i in [ 1 .. Length( rays_in_faces ) ] do
            
            # construct the i-th facet and compute the rays in its facets
            generators := List( Filtered( [ 1 .. Length( rays ) ], j -> not IsZero( rays_in_faces[ i ][ j ] ) ), k -> rays[ k ] );
            additional_rays := RaysInFaces( Cone( generators ) );
            
            # convert these lists into a list with the rays above
            converted_additional_rays := [];
            for j in [ 1 .. Length( additional_rays ) ] do
                pos := Positions( additional_rays[ j ], 1 );
                pos2 := List( [ 1 .. Length( pos ) ], k -> Position( rays, generators[ pos[ k ] ] ) );
                help_list := List( [ 1 .. Length( rays ) ], k -> 0 );
                for k in pos2 do
                    help_list[ k ] := 1;
                od;
                converted_additional_rays := Concatenation( converted_additional_rays, [ help_list ] );
            od;
            
            # add this list of rays in the faces of the i-th facet to the above-computed list of rays_in_facets
            rays_in_faces := Concatenation( rays_in_faces, converted_additional_rays  );
            
        od;
        
    fi;
    
    # all all rays, since the overall cone is also a face
    rays_in_faces := Concatenation( rays_in_faces, [ ListWithIdenticalEntries( Length( Polymake_Rays( cone ) ), 1 ) ] );
    
    # return the result
    return DuplicateFreeList( rays_in_faces );
    
end );


##############################################################################################
##
##  Properties of PolymakeCones
##
##############################################################################################

InstallMethod( Polymake_IsEmpty,
               "finding if the cone empty is or not",
               [ IsPolymakeCone ],
  function( cone )
    
    return Length( Polymake_V_Rep( cone )!.rays ) = 0;
    
end );


InstallMethod( Polymake_IsPointed,
               "finding if the cone is pointed or not",
               [ IsPolymakeCone ],
  function( cone )
    local help_cone;
    
    help_cone := Polymake_V_Rep( cone );
    
    return help_cone!.pmobj.POINTED;
    
end );


##############################################################################################
##
##  Operations with cones
##
##############################################################################################

InstallMethod( Polymake_Intersection,
               "construct intersection of two cones",
               [ IsPolymakeCone, IsPolymakeCone ],
  function( cone1, cone2 )
    local cone1_h, cone2_h, new_ineqs, new_equ;
    
    cone1_h := Polymake_H_Rep( cone1 );
    cone2_h := Polymake_H_Rep( cone2 );
    
    new_ineqs := Concatenation( cone1_h!.inequalities, cone2_h!.inequalities );
    new_equ := Concatenation( cone1_h!.equalities, cone2_h!.equalities );
    
    return Polymake_ConeFromInequalities( new_ineqs, new_equ );
    
end );
