report ztest_zcl_accounting_document.

data:
  acc_doc type ref to zcl_accounting_document,
  acc_doc_error type ref to zcx_accounting_document_error.


try.

    acc_doc = zcl_accounting_document=>create( ).

    "First specify the header fields
    acc_doc->set_field( i_name = 'BLDAT' i_value = '20200222' ).
    acc_doc->set_field( i_name = 'BLART' i_value = 'VD' ).
    acc_doc->set_field( i_name = 'BUKRS' i_value = '1000' ).
    acc_doc->set_field( i_name = 'BUDAT' i_value = '20190215' ).
    acc_doc->set_field( i_name = 'WAERS' i_value = 'USD' ).
    acc_doc->set_field( i_name = 'XBLNR' i_value = 'Invoice #123' ).
    acc_doc->set_field( i_name = 'BKTXT' i_value = 'XYZ, Inc.' ).

    acc_doc->initialize_ap_line( ).
    acc_doc->set_field( i_name = 'LIFNR' i_value = 'ABJ01' ).
    acc_doc->set_field( i_name = 'WRBTR' i_value = '-250.00' ).
    acc_doc->set_field( i_name = 'SGTXT' i_value = 'Bla, bla, bla' ).

    acc_doc->initialize_gl_line( ).
    acc_doc->set_field( i_name = 'HKONT' i_value = '0000401100' ).
    acc_doc->set_field( i_name = 'WRBTR' i_value = '250.00' ).
    acc_doc->set_field( i_name = 'PRCTR' i_value = '0000100010' ).
    acc_doc->set_field( i_name = 'SGTXT' i_value = 'Bla, bla, bla' ).

    "acc_doc->simulate( ).  "If you just want to simulate the posting.

    acc_doc->post( ).

    acc_doc->commit_transaction( ).

    write: / 'Document posted successfully in company code',
             acc_doc->company_code,
             'with document',
             acc_doc->document_number.


  catch zcx_accounting_document_error into acc_doc_error.

    data:
      error_message type string,
      return_wa type bapiret2.

    error_message = acc_doc_error->get_text( ).
    write: / error_message.

    loop at acc_doc->return_tab into return_wa.
      write return_wa-message.
    endloop.

    acc_doc->rollback_transaction( ).

endtry.
