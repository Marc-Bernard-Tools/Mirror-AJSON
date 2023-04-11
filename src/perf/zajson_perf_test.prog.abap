REPORT zajson_perf_test.

**********************************************************************
* CONTRIB from https://github.com/sbcgua/benchmarks
**********************************************************************

CLASS lcl_benchmark DEFINITION FINAL.
  PUBLIC SECTION.
    METHODS constructor
      IMPORTING
        io_object TYPE REF TO object
        iv_method TYPE string
        iv_times  TYPE i.
    METHODS run
      RAISING
        cx_static_check.
    METHODS print.

  PRIVATE SECTION.
    DATA mo_object TYPE REF TO object.
    DATA mv_method TYPE string.
    DATA mv_times TYPE i.
    DATA mv_diff TYPE tzntstmpl.
ENDCLASS.

CLASS lcl_benchmark IMPLEMENTATION.

  METHOD constructor.
    mo_object = io_object.
    mv_method = to_upper( iv_method ).
    mv_times = iv_times.
  ENDMETHOD.

  METHOD run.
    DATA lv_sta_time TYPE timestampl.
    DATA lv_end_time TYPE timestampl.

    GET TIME STAMP FIELD lv_sta_time.
    DO mv_times TIMES.
      CALL METHOD mo_object->(mv_method).
    ENDDO.
    GET TIME STAMP FIELD lv_end_time.

    mv_diff  = cl_abap_tstmp=>subtract(
      tstmp1 = lv_end_time
      tstmp2 = lv_sta_time ).

  ENDMETHOD.

  METHOD print.
    DATA lv_rounds TYPE string.
    DATA lv_result TYPE string.
    lv_rounds = |rounds: { mv_times }|.
    lv_result = |result: { mv_diff }|.
    WRITE: /(30) mv_method, (20) lv_rounds, lv_result.
    ULINE.
  ENDMETHOD.

ENDCLASS.

**********************************************************************
* RUNNER
**********************************************************************

CLASS lcl_runner_base DEFINITION.
  PUBLIC SECTION.

    METHODS run
      IMPORTING
        iv_method TYPE string
        iv_times TYPE i OPTIONAL
      RAISING
        cx_static_check.

  PROTECTED SECTION.
    DATA mv_num_rounds TYPE i.

ENDCLASS.

CLASS lcl_runner_base IMPLEMENTATION.

  METHOD run.

    DATA lo_benchmark TYPE REF TO lcl_benchmark.
    DATA lv_times TYPE i.

    IF iv_times > 0.
      lv_times = iv_times.
    ELSE.
      lv_times = mv_num_rounds.
    ENDIF.

    CREATE OBJECT lo_benchmark
      EXPORTING
        io_object = me
        iv_method = iv_method
        iv_times  = lv_times.

    lo_benchmark->run( ).
    lo_benchmark->print( ).

  ENDMETHOD.

ENDCLASS.

**********************************************************************
* END OF CONTRIB from https://github.com/sbcgua/benchmarks
**********************************************************************

CLASS lcl_app DEFINITION FINAL INHERITING FROM lcl_runner_base.
  PUBLIC SECTION.

    METHODS parse_plain_obj RAISING cx_static_check.
    METHODS parse_deep_obj RAISING cx_static_check.
    METHODS parse_array RAISING cx_static_check.
    METHODS parse_long_array RAISING cx_static_check.
    METHODS parse_complex RAISING cx_static_check.

    METHODS to_abap_plain_obj RAISING cx_static_check.
    METHODS to_abap_deep_obj RAISING cx_static_check.
    METHODS to_abap_array RAISING cx_static_check.
    METHODS to_abap_long_array RAISING cx_static_check.
    METHODS to_abap_complex RAISING cx_static_check.

    METHODS set_same_level RAISING cx_static_check.
    METHODS set_deep RAISING cx_static_check.
    METHODS set_overwrite RAISING cx_static_check.
    METHODS delete_tree RAISING cx_static_check.

    METHODS slice RAISING cx_static_check.

    CLASS-METHODS main.
    METHODS prepare.
    METHODS prepare_parsed RAISING cx_static_check.
    METHODS prepare_complex.
    METHODS prepare_slice RAISING cx_static_check.

    METHODS prepare_components
      IMPORTING
        iv_fields TYPE i
      RETURNING
        VALUE(rt_components) TYPE cl_abap_structdescr=>component_table.
    METHODS prepare_json_object
      IMPORTING
        iv_fields     TYPE i
        iv_start_data TYPE i DEFAULT 0
      RETURNING
        VALUE(rv_str) TYPE string.

    METHODS prepare_long_array.
    METHODS prepare_long_array_container
      IMPORTING
        iv_fields TYPE i.
    METHODS prepare_long_array_str
      IMPORTING
        iv_fields TYPE i
        iv_lines TYPE i.

    DATA mv_json_plain_obj TYPE string.
    DATA mv_json_deep TYPE string.
    DATA mv_json_array TYPE string.
    DATA mv_json_long_array TYPE string.
    DATA mv_json_complex TYPE string.

    DATA mr_complex_data TYPE REF TO data.
    DATA mr_long_array TYPE REF TO data.

    DATA mo_plain_obj TYPE REF TO /mbtools/if_ajson.
    DATA mo_deep TYPE REF TO /mbtools/if_ajson.
    DATA mo_array TYPE REF TO /mbtools/if_ajson.
    DATA mo_long_array TYPE REF TO /mbtools/if_ajson.
    DATA mo_complex TYPE REF TO /mbtools/if_ajson.
    DATA mo_for_slice TYPE REF TO /mbtools/if_ajson.

    DATA mv_deep_path TYPE string.

    TYPES:
      BEGIN OF ty_fragment,
        string TYPE string,
        number TYPE i,
        float TYPE f,
      END OF ty_fragment,
      ty_fragment_tab TYPE STANDARD TABLE OF ty_fragment WITH KEY string,
      BEGIN OF ty_plain.
        INCLUDE TYPE ty_fragment.
    TYPES:
          boolean TYPE abap_bool,
          false TYPE abap_bool,
          null TYPE string,
          date TYPE string, " ??? TODO
          str1 TYPE string,
          str2 TYPE string,
          END OF ty_plain,
          BEGIN OF ty_deep1.
        INCLUDE TYPE ty_fragment.
    TYPES: deep TYPE ty_fragment,
          END OF ty_deep1,
          BEGIN OF ty_deep2.
        INCLUDE TYPE ty_fragment.
    TYPES: deep TYPE ty_deep1,
          END OF ty_deep2,
          BEGIN OF ty_deep3.
        INCLUDE TYPE ty_fragment.
    TYPES: deep TYPE ty_deep2,
          END OF ty_deep3.

ENDCLASS.

CLASS lcl_app IMPLEMENTATION.

  METHOD prepare_slice.

    DATA lv_branch TYPE string.

    mo_for_slice = /mbtools/cl_ajson=>new( ).

    DO 10 TIMES.
      lv_branch = |/branch{ sy-index }|.
      DO 100 TIMES.
        mo_for_slice->set_integer(
          iv_path = |{ lv_branch }/item{ sy-index }|
          iv_val  = sy-index ).
      ENDDO.
    ENDDO.

  ENDMETHOD.

  METHOD prepare.
    mv_json_plain_obj =
      '{' &&
      '  "string": "abc",' &&
      '  "number": 123,' &&
      '  "float": 123.45,' &&
      '  "boolean": true,' &&
      '  "false": false,' &&
      '  "null": null,' &&
      '  "date": "2020-03-15",' &&
      '  "str1": "hello",' &&
      '  "str2": "world"' &&
      '}'.

    mv_json_deep =
      '{' &&
      '    "string": "abc",' &&
      '    "number": 123,' &&
      '    "float": 123.45,' &&
      '    "deep" : {' &&
      '        "string": "abc",' &&
      '        "number": 223,' &&
      '        "float": 123.45,' &&
      '        "deep" : {' &&
      '            "string": "abc",' &&
      '            "number": 323,' &&
      '            "float": 123.45,' &&
      '            "deep" : {' &&
      '                "string": "abc",' &&
      '                "number": 423,  ' &&
      '                "float": 123.45 ' &&
      '            }' &&
      '        }' &&
      '    }' &&
      '}'.

    mv_json_array = '['.
    DO 10 TIMES.
      IF sy-index <> 1.
        mv_json_array = mv_json_array && `, `.
      ENDIF.
      mv_json_array = mv_json_array &&
        '{' &&
        '    "string": "abc", ' &&
        '    "number": 123,   ' &&
        '    "float": 123.45  ' &&
        '}'.
    ENDDO.
    mv_json_array = mv_json_array && ']'.

    prepare_complex( ).
    prepare_long_array( ).

    DO 50 TIMES.
      mv_deep_path = mv_deep_path && |/a{ sy-index }|.
    ENDDO.

  ENDMETHOD.

  METHOD prepare_complex.

    CONSTANTS lc_fields  TYPE i VALUE 256.
    CONSTANTS lc_tabrows TYPE i VALUE 256.

    DATA lo_long_struc TYPE REF TO cl_abap_structdescr.
    DATA lo_long_table TYPE REF TO cl_abap_tabledescr.
    DATA lt_components TYPE cl_abap_structdescr=>component_table.
    DATA lv_data TYPE i.
    DATA lo_complex_type TYPE REF TO cl_abap_structdescr.
    DATA ls_comp LIKE LINE OF lt_components.

    lt_components = prepare_components( lc_fields ).

    lo_long_struc = cl_abap_structdescr=>create( lt_components ).
    lo_long_table = cl_abap_tabledescr=>create( lo_long_struc ).
    ls_comp-type ?= lo_long_table.
    ls_comp-name  = 'TAB'.
    APPEND ls_comp TO lt_components.

    lo_complex_type = cl_abap_structdescr=>create( lt_components ).
    CREATE DATA mr_complex_data TYPE HANDLE lo_complex_type.

    " Data
    mv_json_complex = prepare_json_object(
      iv_fields     = lc_fields
      iv_start_data = lv_data ).
    lv_data = lv_data + lc_fields.

    mv_json_complex = replace( val = mv_json_complex
                               sub = '}'
                               with = `, "TAB": [` ).

    DATA lt_tab TYPE string_table.

    DO lc_tabrows TIMES.
      APPEND prepare_json_object(
        iv_fields = lc_fields
        iv_start_data = lv_data ) TO lt_tab.
      lv_data = lv_data + lc_fields.
    ENDDO.

    mv_json_complex = mv_json_complex && concat_lines_of( table = lt_tab
                                                          sep = `, ` ) && `]}`.

  ENDMETHOD.

  METHOD prepare_long_array.

    CONSTANTS lc_fields  TYPE i VALUE 20.
    CONSTANTS lc_tabrows TYPE i VALUE 5000.

    prepare_long_array_container( iv_fields = lc_fields ).
    prepare_long_array_str(
      iv_fields = lc_fields
      iv_lines  = lc_tabrows ).

  ENDMETHOD.

  METHOD prepare_components.

    DATA lo_field_type TYPE REF TO cl_abap_datadescr.
    DATA ls_comp LIKE LINE OF rt_components.

    lo_field_type ?= cl_abap_typedescr=>describe_by_name( 'CHAR10' ).
    ls_comp-type = lo_field_type.
    DO iv_fields TIMES.
      ls_comp-name = |C{ sy-index }|.
      APPEND ls_comp TO rt_components.
    ENDDO.

  ENDMETHOD.

  METHOD prepare_long_array_container.

    DATA lo_long_struc TYPE REF TO cl_abap_structdescr.
    DATA lo_long_table TYPE REF TO cl_abap_tabledescr.
    DATA lt_components TYPE cl_abap_structdescr=>component_table.

    lt_components = prepare_components( iv_fields ).
    lo_long_struc = cl_abap_structdescr=>create( lt_components ).
    lo_long_table = cl_abap_tabledescr=>create( lo_long_struc ).

    CREATE DATA mr_long_array TYPE HANDLE lo_long_table.

  ENDMETHOD.

  METHOD prepare_json_object.

    DATA lv_data TYPE i.
    DATA lt_tab TYPE string_table.
    DATA lv_tmp TYPE string.

    lv_data = iv_start_data.

    DO iv_fields TIMES.
      lv_data = lv_data + 1.
      lv_tmp = |"C{ sy-index }": "{ lv_data }"|.
      APPEND lv_tmp TO lt_tab.
    ENDDO.

    rv_str = `{` && concat_lines_of( table = lt_tab
                                     sep = `, ` ) && `}`.

  ENDMETHOD.

  METHOD prepare_long_array_str.

    DATA lt_tab TYPE string_table.
    DATA lv_data TYPE i.

    DO iv_lines TIMES.
      APPEND prepare_json_object(
        iv_fields = iv_fields
        iv_start_data = lv_data ) TO lt_tab.
      lv_data = lv_data + iv_fields.
    ENDDO.

    mv_json_long_array = `[` && concat_lines_of( table = lt_tab
                                                 sep = `, ` ) && `]`.

  ENDMETHOD.

  METHOD prepare_parsed.

    mo_plain_obj  = /mbtools/cl_ajson=>parse( mv_json_plain_obj ).
    mo_deep       = /mbtools/cl_ajson=>parse( mv_json_deep ).
    mo_array      = /mbtools/cl_ajson=>parse( mv_json_array ).
    mo_complex    = /mbtools/cl_ajson=>parse( mv_json_complex ).
    mo_long_array = /mbtools/cl_ajson=>parse( mv_json_long_array ).

  ENDMETHOD.

  METHOD parse_plain_obj.

    DATA lo_json TYPE REF TO /mbtools/if_ajson.
    lo_json = /mbtools/cl_ajson=>parse( mv_json_plain_obj ).

  ENDMETHOD.

  METHOD parse_deep_obj.

    DATA lo_json TYPE REF TO /mbtools/if_ajson.
    lo_json = /mbtools/cl_ajson=>parse( mv_json_deep ).

  ENDMETHOD.

  METHOD parse_array.

    DATA lo_json TYPE REF TO /mbtools/if_ajson.
    lo_json = /mbtools/cl_ajson=>parse( mv_json_array ).

  ENDMETHOD.

  METHOD parse_long_array.

    DATA lo_json TYPE REF TO /mbtools/if_ajson.
    lo_json = /mbtools/cl_ajson=>parse( mv_json_long_array ).

  ENDMETHOD.

  METHOD parse_complex.

    DATA lo_json TYPE REF TO /mbtools/if_ajson.
    lo_json = /mbtools/cl_ajson=>parse( mv_json_complex ).

  ENDMETHOD.

  METHOD to_abap_plain_obj.

    DATA ls_target TYPE ty_plain.
    mo_plain_obj->to_abap( IMPORTING ev_container = ls_target ).

  ENDMETHOD.

  METHOD to_abap_deep_obj.

    DATA ls_target TYPE ty_deep3.
    mo_deep->to_abap( IMPORTING ev_container = ls_target ).

  ENDMETHOD.

  METHOD to_abap_array.

    DATA ls_target TYPE ty_fragment_tab.
    mo_array->to_abap( IMPORTING ev_container = ls_target ).

  ENDMETHOD.

  METHOD to_abap_long_array.

    FIELD-SYMBOLS <data> TYPE any.
    ASSIGN mr_long_array->* TO <data>.
    mo_long_array->to_abap( IMPORTING ev_container = <data> ).

  ENDMETHOD.

  METHOD to_abap_complex.

    FIELD-SYMBOLS <data> TYPE any.
    ASSIGN mr_complex_data->* TO <data>.
    mo_complex->to_abap( IMPORTING ev_container = <data> ).

  ENDMETHOD.

  METHOD set_same_level.

    DATA li_json TYPE REF TO /mbtools/if_ajson.
    li_json = /mbtools/cl_ajson=>create_empty( ).

    DO 10 TIMES.
      li_json->set(
        iv_path = |/a{ sy-index }|
        iv_val  = sy-index ).
    ENDDO.

  ENDMETHOD.

  METHOD set_deep.

    DATA li_json TYPE REF TO /mbtools/if_ajson.
    DATA lv_path TYPE string.
    li_json = /mbtools/cl_ajson=>create_empty( ).

    DO 10 TIMES.
      lv_path = lv_path && |/a{ sy-index }|.
      li_json->set(
        iv_path = |{ lv_path }/x|
        iv_val  = sy-index ).
    ENDDO.

  ENDMETHOD.

  METHOD set_overwrite.

    DATA li_json TYPE REF TO /mbtools/if_ajson.
    DATA lv_path TYPE string.

    li_json = /mbtools/cl_ajson=>create_empty( ).

    DO 10 TIMES.
      lv_path = lv_path && |/a{ sy-index }|.
    ENDDO.

    li_json->set(
      iv_path = lv_path
      iv_val  = 'x' ).

    DO 10 TIMES.
      li_json->set(
        iv_path = lv_path
        iv_val  = sy-index ).
    ENDDO.

  ENDMETHOD.

  METHOD delete_tree.

    DATA li_json TYPE REF TO /mbtools/if_ajson.
    li_json = /mbtools/cl_ajson=>create_empty( ).

    li_json->set(
      iv_path = |/x{ mv_deep_path }|
      iv_val  = '1' ).
    li_json->set(
      iv_path = |/y{ mv_deep_path }|
      iv_val  = '1' ).

    li_json->delete( '/x' ).

  ENDMETHOD.

  METHOD slice.

    DATA li_json TYPE REF TO /mbtools/if_ajson.

    li_json = mo_for_slice->slice( iv_path = 'branch9' ).

  ENDMETHOD.

  METHOD main.

    DATA lo_app TYPE REF TO lcl_app.
    DATA lx TYPE REF TO cx_root.
    DATA lv_tmp TYPE string.

    CREATE OBJECT lo_app.

    lo_app->mv_num_rounds = 1000.

    lv_tmp = |{ sy-datum+0(4) }-{ sy-datum+4(2) }-{ sy-datum+6(2) }|.
    WRITE: / 'Date', lv_tmp.

    TRY.

        lo_app->prepare( ).

        lo_app->run( 'parse_plain_obj' ).
        lo_app->run( 'parse_deep_obj' ).
        lo_app->run( 'parse_array' ).
        lo_app->run(
          iv_method = 'parse_long_array'
          iv_times  = 5 ).
        lo_app->run(
          iv_method = 'parse_complex'
          iv_times  = 5 ).

        lo_app->prepare_parsed( ).

        lo_app->run( 'to_abap_plain_obj' ).
        lo_app->run( 'to_abap_deep_obj' ).
        lo_app->run( 'to_abap_array' ).
        lo_app->run(
          iv_method = 'to_abap_long_array'
          iv_times  = 5 ).
        lo_app->run(
          iv_method = 'to_abap_complex'
          iv_times  = 5 ).

        lo_app->run( 'set_same_level' ).
        lo_app->run( 'set_deep' ).
        lo_app->run( 'set_overwrite' ).
        lo_app->run( 'delete_tree' ).

        lo_app->prepare_slice( ).

        lo_app->run( 'slice' ).

      CATCH cx_root INTO lx.
        lv_tmp = lx->get_text( ).
        WRITE: / 'Exception raised:', lv_tmp.
    ENDTRY.

  ENDMETHOD.

ENDCLASS.

START-OF-SELECTION.

  lcl_app=>main( ).
