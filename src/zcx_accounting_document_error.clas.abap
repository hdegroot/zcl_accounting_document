class zcx_accounting_document_error definition
  public
  inheriting from cx_static_check
  final
  create public .

  public section.

    constants:
      zcx_100 type sotr_conc value '005056B93C541EDB9FBF7CCFC7958129', "#EC NOTEXT
      zcx_101 type sotr_conc value '005056B93C541EDB9FBFB3B06CC36129', "#EC NOTEXT
      zcx_102 type sotr_conc value '005056B93C541EDB9FBFB3B06CC38129', "#EC NOTEXT
      zcx_103 type sotr_conc value '005056B93C541EDB9FBFB7C7289E0129', "#EC NOTEXT
      zcx_104 type sotr_conc value '005056B93C541EDB9FBFB7C7289E2129'. "#EC NOTEXT

    data:
      component_name type string ,
      return_message type bapiret2 .

    methods constructor
      importing
        !textid like textid optional
        !previous like previous optional
        !component_name type string optional
        !return_message type bapiret2 optional .

endclass.


class zcx_accounting_document_error implementation.

  method constructor.

    call method super->constructor
      exporting
        textid   = textid
        previous = previous.
    me->component_name = component_name .
    me->return_message = return_message .

  endmethod.

endclass.
