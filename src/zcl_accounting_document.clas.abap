class zcl_accounting_document definition
  public
  create private .

  public section.

    types:
      ty_return_tab     type standard table of bapiret2,
      ty_extension1_tab type standard table of bapiacextc,
      ty_extension2_tab type standard table of bapiparex.

    data:
      obj_type        type bapiache09-obj_type,
      obj_key         type bapiache09-obj_key,
      obj_sys         type bapiache09-obj_sys,

      company_code    type bukrs,
      document_number type belnr_d,
      fiscal_year     type gjahr,

      return_tab      type ty_return_tab.

    class-methods:
      create importing i_obj_type type awtyp default 'BKPFF'
                       i_obj_sys  type awsys optional
                       i_bus_act  type glvor default 'RFBU'
                       i_username type usnam optional
             returning value(r_accounting_document) type ref to zcl_accounting_document ,

      commit_transaction importing i_wait type bapita-wait default 'X'
                         raising zcx_accounting_document_error,

      rollback_transaction raising zcx_accounting_document_error.

    methods:
      initialize_gl_line ,
      initialize_ap_line ,
      initialize_ar_line ,

      set_field importing i_name  type string
                          i_value type any
                raising zcx_accounting_document_error,

      set_extension1_tab importing i_extension1_tab type ty_extension1_tab,

      set_extension2_tab importing i_extension2_tab type ty_extension2_tab,

      check_before_post raising zcx_accounting_document_error,

      post raising zcx_accounting_document_error.


  private section.

    constants:
      co_header            type char3 value 'HDR',
      co_accountgl         type char3 value 'GL',
      co_accountreceivable type char3 value 'AR',
      co_accountpayable    type char3 value 'AP'.

    types:
      ty_accountgl_tab         type standard table of bapiacgl09,
      ty_accountreceivable_tab type standard table of bapiacar09,
      ty_accountpayable_tab    type standard table of bapiacap09,
      ty_currencyamount_tab    type standard table of bapiaccr09,
      ty_criteria_tab          type standard table of bapiackec9.



    data:
      document_creation_status       type char3,
      document_currency              type waers,
      current_line_item_number       type posnr_acc value '0000000000', "#EC NOTEXT

      documentheader                 type bapiache09,
      customercpd                    type bapiacpa09,
      contractheader                 type bapiaccahd,

      accountgl_tab                  type ty_accountgl_tab ,
      accountreceivable_tab          type ty_accountreceivable_tab,
      accountpayable_tab             type ty_accountpayable_tab,
      currencyamount_tab             type ty_currencyamount_tab,
      criteria_tab                   type ty_criteria_tab,
      extension1_tab                 type ty_extension1_tab,
      extension2_tab                 type ty_extension2_tab,

      current_line_accountgl         type bapiacgl09,
      current_line_accountreceivable type bapiacar09,
      current_line_accountpayable    type bapiacap09.

    methods:
      constructor importing i_obj_type type awtyp
                            i_obj_sys  type awsys
                            i_bus_act  type glvor
                            i_username type usnam ,

      initialize_new_line ,

      get_component importing i_alias type string
                    returning value(r_component) type string,

      get_variable  importing i_component type string
                    returning value(r_variable) type string,

      get_company_code_currency returning value(r_currency) type waers,

      get_group_currency returning value(r_currency) type waers.

endclass.



class zcl_accounting_document implementation.


  method create.

    data:
      username type usnam.

    if i_username is initial.
      username = sy-uname.
    else.
      username = i_username.
    endif.

    create object r_accounting_document
      exporting
        i_obj_type = i_obj_type
        i_obj_sys  = i_obj_sys
        i_bus_act  = i_bus_act
        i_username = username.

  endmethod.


  method constructor.

    documentheader-obj_type = i_obj_type.
    documentheader-obj_sys  = i_obj_sys.
    documentheader-bus_act  = i_bus_act.
    documentheader-username = i_username.

    document_creation_status = co_header.

  endmethod.


  method initialize_gl_line.

    initialize_new_line( ).

    current_line_item_number = current_line_item_number + 1.

    current_line_accountgl-itemno_acc = current_line_item_number.

    document_creation_status = co_accountgl.

  endmethod.


  method initialize_ar_line.

    initialize_new_line( ).

    current_line_item_number = current_line_item_number + 1.

    current_line_accountreceivable-itemno_acc = current_line_item_number.

    document_creation_status = co_accountreceivable.

  endmethod.


  method initialize_ap_line.

    initialize_new_line( ).

    current_line_item_number = current_line_item_number + 1.

    current_line_accountpayable-itemno_acc = current_line_item_number.

    document_creation_status = co_accountpayable.

  endmethod.


  method set_field.

    data:
      component                   type string,
      variable                    type string,
      field                       type string,
      current_line_currencyamount type bapiaccr09,
      current_line_criteria       type bapiackec9.

    field-symbols:
      <any> type any.


    if i_name = 'WAERS' or i_name = 'DOC_CUR'.
      document_currency = i_value.
      return.
    endif.

    if i_name = 'WRBTR'.
      current_line_currencyamount-itemno_acc = current_line_item_number.
      current_line_currencyamount-curr_type  = '00'.
      current_line_currencyamount-currency   = document_currency.
      current_line_currencyamount-amt_doccur = i_value.
      append current_line_currencyamount to currencyamount_tab.
      return.

    elseif i_name = 'DMBTR'.
      current_line_currencyamount-itemno_acc = current_line_item_number.
      current_line_currencyamount-curr_type  = '10'.
      current_line_currencyamount-currency   = get_company_code_currency( ).
      current_line_currencyamount = i_value.
      append current_line_currencyamount to currencyamount_tab.
      return.

    elseif i_name = 'DMBE2'.
      current_line_currencyamount-itemno_acc = current_line_item_number.
      current_line_currencyamount-curr_type  = '30'.
      current_line_currencyamount-currency   = get_group_currency( ).
      current_line_currencyamount-amt_doccur = i_value.
      append current_line_currencyamount to currencyamount_tab.
      return.

    endif.

    if i_name+0(3) = 'RKE'.  "CO-PA characteristic
      data: fieldname type c length 30.
      fieldname = i_name.
      replace 'RKE_' in fieldname with ''.
      current_line_criteria-itemno_acc = current_line_item_number.
      current_line_criteria-fieldname  = fieldname.
      current_line_criteria-character  = i_value.
      append current_line_criteria to criteria_tab.
      return.

    endif.

    component = get_component( i_name ).

    case document_creation_status.

      when co_header.
        variable  = get_variable( component ).
        field = |{ variable }-{ component }|.

      when co_accountgl.
        variable  = 'CURRENT_LINE_ACCOUNTGL'.
        field = |{ variable }-{ component }|.

      when co_accountreceivable.
        variable  = 'CURRENT_LINE_ACCOUNTRECEIVABLE'.
        field = |{ variable }-{ component }|.

      when co_accountpayable.
        variable  = 'CURRENT_LINE_ACCOUNTPAYABLE'.
        field = |{ variable }-{ component }|.

    endcase.

    assign (field) to <any>.
    if <any> is assigned.
      <any> = i_value.
    else.
      raise exception type zcx_accounting_document_error
        exporting
          textid         = zcx_accounting_document_error=>zcx_100  "Field name &COMPONENT_NAME& is invalid.
          component_name = i_name.
    endif.

  endmethod.


  method set_extension1_tab.

     extension1_tab = i_extension1_tab.

  endmethod.


  method set_extension2_tab.

     extension2_tab = i_extension2_tab.

  endmethod.


  method check_before_post.

    data:
      return_wa type bapiret2.


    if current_line_accountgl-itemno_acc is not initial.
      append current_line_accountgl to accountgl_tab.
    endif.
    if current_line_accountreceivable-itemno_acc is not initial.
      append current_line_accountreceivable to accountreceivable_tab.
    endif.
    if current_line_accountpayable-itemno_acc is not initial.
      append current_line_accountpayable to accountpayable_tab.
    endif.

    call function 'BAPI_ACC_DOCUMENT_CHECK'
      exporting
        documentheader    = documentheader
        customercpd       = customercpd
        contractheader    = contractheader
      tables
        accountgl         = accountgl_tab
        accountreceivable = accountreceivable_tab
        accountpayable    = accountpayable_tab
        currencyamount    = currencyamount_tab
        criteria          = criteria_tab
        extension1        = extension1_tab
        return            = return_tab
        extension2        = extension2_tab.

    if lines( return_tab ) > 0.

      read table return_tab index 1 into return_wa.

      if return_wa-id = 'RW' and return_wa-number <> '614'.  "RW614 = Document check - no errors
        raise exception type zcx_accounting_document_error
          exporting textid = zcx_accounting_document_error=>zcx_101.  "An error occurred whiling calling 'BAPI_ACC_DOCUMENT_CHECK'
      endif.

    endif.

  endmethod.


  method post.

    data:
      return_wa type bapiret2.


    if current_line_accountgl-itemno_acc is not initial.
      append current_line_accountgl to accountgl_tab.
    endif.
    if current_line_accountreceivable-itemno_acc is not initial.
      append current_line_accountreceivable to accountreceivable_tab.
    endif.
    if current_line_accountpayable-itemno_acc is not initial.
      append current_line_accountpayable to accountpayable_tab.
    endif.

    call function 'BAPI_ACC_DOCUMENT_POST'
      exporting
        documentheader    = documentheader
        customercpd       = customercpd
        contractheader    = contractheader
      importing
        obj_type          = obj_type
        obj_key           = obj_key
        obj_sys           = obj_sys
      tables
        accountgl         = accountgl_tab
        accountreceivable = accountreceivable_tab
        accountpayable    = accountpayable_tab
        currencyamount    = currencyamount_tab
        criteria          = criteria_tab
        extension1        = extension1_tab
        return            = return_tab
        extension2        = extension2_tab.

    if lines( return_tab ) > 0.

      read table return_tab index 1 into return_wa.

      if return_wa-id = 'RW' and return_wa-number = '605'.  "RW505 = Document posted successfully!
        company_code    = obj_key+10(4).
        document_number = obj_key+0(10).
        fiscal_year     = obj_key+14(4).
      else.
        raise exception type zcx_accounting_document_error
          exporting textid = zcx_accounting_document_error=>zcx_102.  "An error occurred whiling calling 'BAPI_ACC_DOCUMENT_POST'
      endif.

    endif.

  endmethod.


  method commit_transaction.

    data:
       return_wa type bapiret2.


    call function 'BAPI_TRANSACTION_COMMIT'
      exporting
        wait   = i_wait
      importing
        return = return_wa.

    if return_wa is not initial.
      raise exception type zcx_accounting_document_error
        exporting
          textid         = zcx_accounting_document_error=>zcx_103  "An error occurred while calling 'BAPI_TRANSACTION_COMMIT'
          return_message = return_wa.
    endif.

  endmethod.


  method rollback_transaction.

    data:
       return_wa type bapiret2.


    call function 'BAPI_TRANSACTION_ROLLBACK'
      importing
        return = return_wa.

    if return_wa is not initial.
      raise exception type zcx_accounting_document_error
        exporting
          textid         = zcx_accounting_document_error=>zcx_104  "An error occurred while calling 'BAPI_TRANSACTION_ROLLBACK'
          return_message = return_wa.
    endif.

  endmethod.


  method get_component.

    case i_alias.

      when 'BKTXT'.  r_component = 'HEADER_TXT'.
      when 'BUKRS'.  r_component = 'COMP_CODE'.
      when 'BLDAT'.  r_component = 'DOC_DATE'.
      when 'BUDAT'.  r_component = 'PSTNG_DATE'.
      when 'WWERT'.  r_component = 'TRANS_DATE'.
      when 'BLART'.  r_component = 'DOC_TYPE'.
      when 'XBLNR'.  r_component = 'REF_DOC_NO'.
      when 'HKONT'.  r_component = 'GL_ACCOUNT'.
      when 'SGTXT'.  r_component = 'ITEM_TEXT'.
      when 'XREF1'.  r_component = 'REF_KEY_1'.
      when 'XREF2'.  r_component = 'REF_KEY_2'.
      when 'XREF3'.  r_component = 'REF_KEY_3'.
      when 'KUNNR'.  r_component = 'CUSTOMER'.
      when 'LIFNR'.  r_component = 'VENDOR_NO'.
      when 'ZUONR'.  r_component = 'ALLOC_NMBR'.
      when 'MWSKZ'.  r_component = 'TAX_CODE'.
      when 'KOSTL'.  r_component = 'COSTCENTER'.
      when 'PRCTR'.  r_component = 'PROFIT_CTR'.
      when 'ZTERM'.  r_component = 'PMNTTRMS'.
      when 'UMSKZ'.  r_component = 'SP_GL_IND'.
      when 'ZFBDT'.  r_component = 'BLINE_DATE'.

      when others.   r_component = i_alias.

    endcase.

  endmethod.


  method get_variable.

    data:
      tabname type dd03l-tabname.


    select tabname
           from dd03l
           into tabname
           up to 1 rows
           where fieldname = i_component
             and ( tabname = 'BAPIACHE09' or
                   tabname = 'BAPIACPA09' or
                   tabname = 'BAPIACCAHD' ) .
    endselect.

    case tabname.

      when 'BAPIACHE09'.  r_variable = 'DOCUMENTHEADER'.
      when 'BAPIACPA09'.  r_variable = 'CUSTOMERCPD'.
      when 'BAPIACCAHD'.  r_variable = 'CONTRACTHEADER'.

      when others.
        r_variable = space.

    endcase.

  endmethod.


  method get_company_code_currency.

    data:
      company_code type bukrs.


    if current_line_accountgl-comp_code is not initial.
      company_code = current_line_accountgl-comp_code.
    elseif documentheader-comp_code is not initial.
      company_code = documentheader-comp_code.
    endif.

    select single waers
       from t001
       into r_currency
       where bukrs = company_code.

  endmethod.


  method get_group_currency.

    select single mwaer
       from t000
       into r_currency
       where mandt = sy-mandt.

  endmethod.


  method  initialize_new_line.

    case document_creation_status.

      when co_accountgl.
        append current_line_accountgl to accountgl_tab.
        clear current_line_accountgl.

      when co_accountreceivable.
        append current_line_accountreceivable to accountreceivable_tab.
        clear current_line_accountreceivable.

      when co_accountpayable.
        append current_line_accountpayable to accountpayable_tab.
        clear current_line_accountpayable.

    endcase.

  endmethod.


endclass.
