%{

/* 
* TODO
*
* When an error occurs and we stop the parse process, 
* what happens to the partially build structres, the point
* arrays and whatever else is hanging around at different
* parts of the process?
*/

/* WKT Parser */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lwin_wkt.h"
#include "lwin_wkt_parse.h"


/* Prototypes to quiet the compiler */
int wkt_yyparse(void);
void wkt_yyerror(const char *str);
int wkt_yywrap(void);
int wkt_yylex(void);


/* Declare the global parser variable */
LWGEOM_PARSER_RESULT global_parser_result;

/* Turn on/off verbose parsing (turn off for production) */
int wkt_yydebug = 0;

/* 
* Error handler called by the bison parser. Mostly we will be 
* catching our own errors and filling out the message and errlocation
* from WKT_ERROR in the grammar, but we keep this one 
* around just in case.
*/
void wkt_yyerror(const char *str)
{
	/* If we haven't already set a message and location, let's set one now. */
	if ( ! global_parser_result.message ) 
	{
		global_parser_result.message = str;
		/* First column should be start of problematic token */
		global_parser_result.errlocation = wkt_yylloc.first_column;
	}
	LWDEBUGF(4,"%s", str);
}

int wkt_yywrap(void)
{
	return 1;
}

/**
* Parse a WKT geometry string into an LWGEOM structure. Note that this
* process uses globals and is not re-entrant, so don't call it within itself
* (eg, from within other functions in lwin_wkt.c) or from a threaded program.
* Note that parser_result.wkinput picks up a reference to wktstr.
*/
int lwgeom_from_wkt(LWGEOM_PARSER_RESULT *parser_result, char *wktstr, int parser_check_flags)
{
	int parse_rv = 0;

	/* Clean up our global parser result. */
	global_parser_result.geom = NULL;
	global_parser_result.message = NULL;
	global_parser_result.serialized_lwgeom = NULL;
	global_parser_result.errcode = 0;
	global_parser_result.errlocation = 0;
	global_parser_result.size = 0;

	/* Set the input text string, and parse checks. */
	global_parser_result.wkinput = wktstr;
	global_parser_result.parser_check_flags = parser_check_flags;
	
	/* Clean up the return value by copying onto it */
	
	wkt_lexer_init(wktstr); /* Lexer ready */
	parse_rv = wkt_yyparse(); /* Run the parse */
	LWDEBUGF(4,"wkt_yyparse returned %d", parse_rv);
	wkt_lexer_close(); /* Clean up lexer */
	
	/* A non-zero parser return is an error. */
	if ( parse_rv != 0 ) 
	{
		if( ! global_parser_result.message )
			global_parser_result.message = "syntax error";

		LWDEBUGF(5, "parser error: '%s'", global_parser_result.message);
		
		/* Copy the global values into the return pointer */
		*parser_result = global_parser_result;
		return LW_FALSE;
	}
	
	/* Copy the global value into the return pointer */
	*parser_result = global_parser_result;
	return LW_TRUE;
}

#define WKT_ERROR() { if ( global_parser_result.errcode != 0 ) { YYERROR; } }


%}

%locations
%error-verbose
%name-prefix="wkt_yy"

%union {
	int integervalue;
	double doublevalue;
	char *stringvalue;
	LWGEOM *geometryvalue;
	POINT coordinatevalue;
	POINTARRAY *ptarrayvalue;
}

%token POINT_TOK LINESTRING_TOK POLYGON_TOK 
%token MPOINT_TOK MLINESTRING_TOK MPOLYGON_TOK 
%token MSURFACE_TOK MCURVE_TOK CURVEPOLYGON_TOK COMPOUNDCURVE_TOK CIRCULARSTRING_TOK
%token COLLECTION_TOK 
%token RBRACKET_TOK LBRACKET_TOK COMMA_TOK EMPTY_TOK
%token SEMICOLON_TOK
%token TRIANGLE_TOK TIN_TOK
%token POLYHEDRALSURFACE_TOK

%token <doublevalue> DOUBLE_TOK
%token <stringvalue> DIMENSIONALITY_TOK
%token <integervalue> SRID_TOK

%type <ptarrayvalue> ring
%type <ptarrayvalue> ptarray
%type <coordinatevalue> coordinate
%type <geometryvalue> circularstring
%type <geometryvalue> compoundcurve
%type <geometryvalue> curve_list
%type <geometryvalue> curvepolygon
%type <geometryvalue> curvering_list
%type <geometryvalue> geometry
%type <geometryvalue> geometry_no_srid
%type <geometryvalue> geometry_list
%type <geometryvalue> geometrycollection
%type <geometryvalue> linestring
%type <geometryvalue> linestring_list
%type <geometryvalue> linestring_untagged
%type <geometryvalue> multicurve
%type <geometryvalue> multilinestring
%type <geometryvalue> multipoint
%type <geometryvalue> multipolygon
%type <geometryvalue> multisurface
%type <geometryvalue> point
%type <geometryvalue> point_list
%type <geometryvalue> point_untagged
%type <geometryvalue> polygon
%type <geometryvalue> polygon_list
%type <geometryvalue> polygon_untagged
%type <geometryvalue> polyhedralsurface
%type <geometryvalue> ring_list
%type <geometryvalue> surface_list
%type <geometryvalue> tin
%type <geometryvalue> triangle
%type <geometryvalue> triangle_list
%type <geometryvalue> triangle_untagged

/* TODO: Turn this stuff on for memory cleanliness.
%destructor { ptarray_freeall($$); } ptarray
%destructor { ptarray_freeall($$); } ring
%destructor { lwgeom_free($$); } linestring
%destructor { lwgeom_free($$); } linestring_untagged
%destructor { lwgeom_free($$); } circularstring
%destructor { lwgeom_free($$); } linestring_list
%destructor { lwgeom_free($$); } point
%destructor { lwgeom_free($$); } multipoint
*/

%%

geometry:
	geometry_no_srid 
		{ wkt_parser_geometry_new($1, 0); WKT_ERROR(); } |
	SRID_TOK SEMICOLON_TOK geometry_no_srid 
		{ wkt_parser_geometry_new($3, $1); WKT_ERROR(); } ;

geometry_no_srid : 
	point { $$ = $1; } | 
	linestring { $$ = $1; } | 
	circularstring { $$ = $1; } | 
	compoundcurve {} | 
	polygon { $$ = $1; } | 
	curvepolygon {} | 
	multipoint { $$ = $1; } |
	multilinestring { $$ = $1; } | 
	multipolygon { $$ = $1; } |
	multisurface {} |
	multicurve {} |
	tin { $$ = $1; } |
	polyhedralsurface { $$ = $1; } |
	triangle { $$ = $1; } |
	geometrycollection {} ;
	
geometrycollection :
	COLLECTION_TOK LBRACKET_TOK geometry_list RBRACKET_TOK {} |
	COLLECTION_TOK DIMENSIONALITY_TOK LBRACKET_TOK geometry_list RBRACKET_TOK {} |
	COLLECTION_TOK DIMENSIONALITY_TOK EMPTY_TOK {} |
	COLLECTION_TOK EMPTY_TOK {} ;
	
geometry_list :
	geometry_list COMMA_TOK geometry_no_srid {} |
	geometry_no_srid {} ;

multisurface :
	MSURFACE_TOK LBRACKET_TOK surface_list RBRACKET_TOK {} |
	MSURFACE_TOK DIMENSIONALITY_TOK LBRACKET_TOK surface_list RBRACKET_TOK {} |
	MSURFACE_TOK DIMENSIONALITY_TOK EMPTY_TOK {} |
	MSURFACE_TOK EMPTY_TOK {} ;
	
surface_list :
	surface_list COMMA_TOK polygon {} |
	surface_list COMMA_TOK curvepolygon {} |
	surface_list COMMA_TOK polygon_untagged {} |
	polygon {} |
	curvepolygon {} |
	polygon_untagged {} ;

tin :
	TIN_TOK LBRACKET_TOK triangle_list RBRACKET_TOK
		{ $$ = wkt_parser_collection_finalize(TINTYPE, $3, NULL); WKT_ERROR(); } |
	TIN_TOK DIMENSIONALITY_TOK LBRACKET_TOK triangle_list RBRACKET_TOK
		{ $$ = wkt_parser_collection_finalize(TINTYPE, $4, $2); WKT_ERROR(); } |
	TIN_TOK DIMENSIONALITY_TOK EMPTY_TOK
		{ $$ = wkt_parser_collection_finalize(TINTYPE, NULL, $2); WKT_ERROR(); } |
	TIN_TOK EMPTY_TOK
		{ $$ = wkt_parser_collection_finalize(TINTYPE, NULL, NULL); WKT_ERROR(); } ;

polyhedralsurface :
	POLYHEDRALSURFACE_TOK LBRACKET_TOK polygon_list RBRACKET_TOK
		{ $$ = wkt_parser_collection_finalize(POLYHEDRALSURFACETYPE, $3, NULL); WKT_ERROR(); } |
	POLYHEDRALSURFACE_TOK DIMENSIONALITY_TOK LBRACKET_TOK polygon_list RBRACKET_TOK
		{ $$ = wkt_parser_collection_finalize(POLYHEDRALSURFACETYPE, $4, $2); WKT_ERROR(); } |
	POLYHEDRALSURFACE_TOK DIMENSIONALITY_TOK EMPTY_TOK
		{ $$ = wkt_parser_collection_finalize(POLYHEDRALSURFACETYPE, NULL, $2); WKT_ERROR(); } |
	POLYHEDRALSURFACE_TOK EMPTY_TOK
		{ $$ = wkt_parser_collection_finalize(POLYHEDRALSURFACETYPE, NULL, NULL); WKT_ERROR(); } ;

multipolygon :
	MPOLYGON_TOK LBRACKET_TOK polygon_list RBRACKET_TOK
		{ $$ = wkt_parser_collection_finalize(MULTIPOLYGONTYPE, $3, NULL); WKT_ERROR(); } |
	MPOLYGON_TOK DIMENSIONALITY_TOK LBRACKET_TOK polygon_list RBRACKET_TOK
		{ $$ = wkt_parser_collection_finalize(MULTIPOLYGONTYPE, $4, $2); WKT_ERROR(); } |
	MPOLYGON_TOK DIMENSIONALITY_TOK EMPTY_TOK
		{ $$ = wkt_parser_collection_finalize(MULTIPOLYGONTYPE, NULL, $2); WKT_ERROR(); } |
	MPOLYGON_TOK EMPTY_TOK
		{ $$ = wkt_parser_collection_finalize(MULTIPOLYGONTYPE, NULL, NULL); WKT_ERROR(); } ;

polygon_list :
	polygon_list COMMA_TOK polygon_untagged 
		{ wkt_parser_collection_add_geom($$,$3); WKT_ERROR(); } |
	polygon_untagged 
		{ $$ = wkt_parser_collection_new($1); WKT_ERROR(); } ;

polygon : 
	POLYGON_TOK LBRACKET_TOK ring_list RBRACKET_TOK 
		{ $$ = wkt_parser_polygon_finalize($3, NULL); WKT_ERROR(); } |
	POLYGON_TOK DIMENSIONALITY_TOK LBRACKET_TOK ring_list RBRACKET_TOK 
		{ $$ = wkt_parser_polygon_finalize($4, $2); WKT_ERROR(); } |
	POLYGON_TOK DIMENSIONALITY_TOK EMPTY_TOK 
		{ $$ = wkt_parser_polygon_finalize(NULL, $2); WKT_ERROR(); } |
	POLYGON_TOK EMPTY_TOK 
		{ $$ = wkt_parser_polygon_finalize(NULL, NULL); WKT_ERROR(); } ;

polygon_untagged : 
	LBRACKET_TOK ring_list RBRACKET_TOK 
		{ $$ = $2; } ;

curvepolygon :
	CURVEPOLYGON_TOK LBRACKET_TOK curvering_list RBRACKET_TOK {} |
	CURVEPOLYGON_TOK DIMENSIONALITY_TOK LBRACKET_TOK curvering_list RBRACKET_TOK {} |
	CURVEPOLYGON_TOK DIMENSIONALITY_TOK EMPTY_TOK {} |
	CURVEPOLYGON_TOK EMPTY_TOK {} ;

curvering_list :
	curvering_list COMMA_TOK ring {} |
	curvering_list COMMA_TOK circularstring {} |
	ring {} |
	circularstring {} ;

ring_list :
	ring_list COMMA_TOK ring 
		{ wkt_parser_polygon_add_ring($$,$3); WKT_ERROR(); } |
	ring 
		{ $$ = wkt_parser_polygon_new($1); WKT_ERROR(); } ;

ring :
	LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = $2; } ;

compoundcurve :
	COMPOUNDCURVE_TOK LBRACKET_TOK curve_list RBRACKET_TOK {} |
	COMPOUNDCURVE_TOK DIMENSIONALITY_TOK LBRACKET_TOK curve_list RBRACKET_TOK {} |
	COMPOUNDCURVE_TOK DIMENSIONALITY_TOK EMPTY_TOK {} |
	COMPOUNDCURVE_TOK EMPTY_TOK {} ;
	
multicurve :
	MCURVE_TOK LBRACKET_TOK curve_list RBRACKET_TOK {} |
	MCURVE_TOK DIMENSIONALITY_TOK LBRACKET_TOK curve_list RBRACKET_TOK {} |
	MCURVE_TOK DIMENSIONALITY_TOK EMPTY_TOK {} |
	MCURVE_TOK EMPTY_TOK {} ;

curve_list :
	curve_list COMMA_TOK circularstring {} |
	curve_list COMMA_TOK linestring {} |
	curve_list COMMA_TOK linestring_untagged {} |
	circularstring {} |
	linestring {} |
	linestring_untagged {} ;

multilinestring :
	MLINESTRING_TOK LBRACKET_TOK linestring_list RBRACKET_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTILINETYPE, $3, NULL); WKT_ERROR(); } |
	MLINESTRING_TOK DIMENSIONALITY_TOK LBRACKET_TOK linestring_list RBRACKET_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTILINETYPE, $4, $2); WKT_ERROR(); } |
	MLINESTRING_TOK DIMENSIONALITY_TOK EMPTY_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTILINETYPE, NULL, $2); WKT_ERROR(); } |
	MLINESTRING_TOK EMPTY_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTILINETYPE, NULL, NULL); WKT_ERROR(); } ;

linestring_list :
	linestring_list COMMA_TOK linestring_untagged 
		{ wkt_parser_collection_add_geom($$,$3); WKT_ERROR(); } |
	linestring_untagged 
		{ $$ = wkt_parser_collection_new($1); WKT_ERROR(); } ;

circularstring : 
	CIRCULARSTRING_TOK LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = wkt_parser_circularstring_new($3, NULL); WKT_ERROR(); } |
	CIRCULARSTRING_TOK DIMENSIONALITY_TOK LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = wkt_parser_circularstring_new($4, $2); WKT_ERROR(); } |
	CIRCULARSTRING_TOK DIMENSIONALITY_TOK EMPTY_TOK
		{ $$ = wkt_parser_circularstring_new(NULL, $2); WKT_ERROR(); } |
	CIRCULARSTRING_TOK EMPTY_TOK 
		{ $$ = wkt_parser_circularstring_new(NULL, NULL); WKT_ERROR(); } ;

linestring : 
	LINESTRING_TOK LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = wkt_parser_linestring_new($3, NULL); WKT_ERROR(); } | 
	LINESTRING_TOK DIMENSIONALITY_TOK LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = wkt_parser_linestring_new($4, $2); WKT_ERROR(); } |
	LINESTRING_TOK DIMENSIONALITY_TOK EMPTY_TOK 
		{ $$ = wkt_parser_linestring_new(NULL, $2); WKT_ERROR(); } |
	LINESTRING_TOK EMPTY_TOK 
		{ $$ = wkt_parser_linestring_new(NULL, NULL); WKT_ERROR(); } ;

linestring_untagged :
	LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = wkt_parser_linestring_new($2, NULL); WKT_ERROR(); } ;

triangle_list :
	triangle_list COMMA_TOK triangle_untagged 
		{ wkt_parser_collection_add_geom($$,$3); WKT_ERROR(); } |
	triangle_untagged 
		{ $$ = wkt_parser_collection_new($1); WKT_ERROR(); } ;

triangle :
	TRIANGLE_TOK LBRACKET_TOK LBRACKET_TOK ptarray RBRACKET_TOK RBRACKET_TOK 
		{ $$ = wkt_parser_triangle_new($4, NULL); WKT_ERROR(); } | 
	TRIANGLE_TOK DIMENSIONALITY_TOK LBRACKET_TOK LBRACKET_TOK ptarray RBRACKET_TOK RBRACKET_TOK 
		{ $$ = wkt_parser_triangle_new($5, $2); WKT_ERROR(); } |
	TRIANGLE_TOK DIMENSIONALITY_TOK EMPTY_TOK
		{ $$ = wkt_parser_triangle_new(NULL, $2); WKT_ERROR(); } | 
	TRIANGLE_TOK EMPTY_TOK
		{ $$ = wkt_parser_triangle_new(NULL, NULL); WKT_ERROR(); } ;

triangle_untagged :
	LBRACKET_TOK LBRACKET_TOK ptarray RBRACKET_TOK RBRACKET_TOK
		{ $$ = wkt_parser_triangle_new($3, NULL); WKT_ERROR(); } ;

multipoint :
	MPOINT_TOK LBRACKET_TOK point_list RBRACKET_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTIPOINTTYPE, $3, NULL); WKT_ERROR(); } |
	MPOINT_TOK DIMENSIONALITY_TOK LBRACKET_TOK point_list RBRACKET_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTIPOINTTYPE, $4, $2); WKT_ERROR(); } |
	MPOINT_TOK DIMENSIONALITY_TOK EMPTY_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTIPOINTTYPE, NULL, $2); WKT_ERROR(); } |
	MPOINT_TOK EMPTY_TOK 
		{ $$ = wkt_parser_collection_finalize(MULTIPOINTTYPE, NULL, NULL); WKT_ERROR(); } ;

point_list :
	point_list COMMA_TOK point_untagged 
		{ wkt_parser_collection_add_geom($$,$3); WKT_ERROR(); } |
	point_untagged 
		{ $$ = wkt_parser_collection_new($1); WKT_ERROR(); } ;

point_untagged :
	coordinate 
		{ $$ = wkt_parser_point_new(wkt_parser_ptarray_new($1),NULL); WKT_ERROR(); } |
	LBRACKET_TOK coordinate RBRACKET_TOK
		{ $$ = wkt_parser_point_new(wkt_parser_ptarray_new($2),NULL); WKT_ERROR(); } ;

point : 
	POINT_TOK LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = wkt_parser_point_new($3, NULL); WKT_ERROR(); } |
	POINT_TOK DIMENSIONALITY_TOK LBRACKET_TOK ptarray RBRACKET_TOK 
		{ $$ = wkt_parser_point_new($4, $2); WKT_ERROR(); } |
	POINT_TOK DIMENSIONALITY_TOK EMPTY_TOK 
		{ $$ = wkt_parser_point_new(NULL, $2); WKT_ERROR(); } |
	POINT_TOK EMPTY_TOK 
		{ $$ = wkt_parser_point_new(NULL,NULL); WKT_ERROR(); } ;

ptarray : 
	ptarray COMMA_TOK coordinate 
		{ wkt_parser_ptarray_add_coord($$, $3); WKT_ERROR(); } |
	coordinate 
		{ $$ = wkt_parser_ptarray_new($1); WKT_ERROR(); } ;

coordinate : 
	DOUBLE_TOK DOUBLE_TOK 
		{ $$ = wkt_parser_coord_2($1, $2); WKT_ERROR(); } | 
	DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK 
		{ $$ = wkt_parser_coord_3($1, $2, $3); WKT_ERROR(); } | 
	DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK DOUBLE_TOK 
		{ $$ = wkt_parser_coord_4($1, $2, $3, $4); WKT_ERROR(); } ;

%%

