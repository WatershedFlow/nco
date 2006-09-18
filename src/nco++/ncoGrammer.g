header {
    #include <math.h>
    #include <malloc.h>
    #include <assert.h>
    #include <ctype.h>
    #include <iostream>
    #include <sstream>
    #include <string>
    #include "ncap2.hh"
    #include "NcapVar.hh"
    #include "NcapVarVector.hh"
    #include "sdo_utl.hh" // SDO stand-alone utilities: dbg/err/wrn_prn()
    ANTLR_USING_NAMESPACE(std);
    ANTLR_USING_NAMESPACE(antlr);
    
}
options {
	language="Cpp";
}




class ncoParser extends Parser;
options {
    k=3;
	genHashLines = true;		// include line number information
	buildAST = true;			// uses CommonAST by default
    defaultErrorHandler=false;
    //analyzerDebug = true;
    //codeGenDebug= true;
}

tokens {
    NULL_NODE;
    BLOCK;
    ARG_LIST;
    DMN_LIST;
    LMT_LIST;
    LMT;
    EXPR;
    POST_INC;
    POST_DEC;
}

program:
        (statement)*
    ;

statement:
        block
        | if_stmt
        | assign_statement
        | def_dim
        //deal with empty statement
        | SEMI! { #statement = #([ NULL_NODE, "null_stmt"]); } 
   ;        


// a bracketed block
block:
    LCURL! (statement)* RCURL!
    { #block = #( [BLOCK, "block"], #block ); }
    ;

if_stmt:
    IF^ LPAREN! expr RPAREN! statement 
    ( (ELSE) => else_part
     )?
     ;

else_part:
    ELSE^ statement
     ;


assign_statement:
         expr SEMI!
       {#assign_statement = #(#[EXPR,"EXPR"],#assign_statement); }

     ; 

hyper_slb: (VAR_ID^|ATT_ID^) (lmt_list)?
     ;

cast_slb:  (VAR_ID^|ATT_ID^) dmn_list
     ;

def_dim:   DEFDIM^ LPAREN! NSTRING COMMA! expr RPAREN! SEMI! 
     ;        


// left association
func_exp: primary_exp | ( FUNC^ LPAREN!  expr RPAREN! )
    ;

// unary left association   
unaryleft_exp: func_exp (
                          in:INC^ {#in->setType(POST_INC);
                                   #in->setText("POST_INC");}
                        | de:DEC^ {#de->setType(POST_DEC);
                                   #de->setText("POST_DEC");}
                          )?
    ;

// unary right association   
unary_exp:  ( LNOT^| PLUS^| MINUS^ |INC^ | DEC^ ) unary_exp
            | unaryleft_exp
	;


// right association
pow_exp: unary_exp (CARET^ pow_exp )? 
    ;

mexpr:
		 pow_exp ( (TIMES^ | DIVIDE^ | MOD^) pow_exp)*
	;

add_expr:
		 mexpr ( (PLUS^ | MINUS^ ) mexpr)* 
	;

rel_expr:
        add_expr (( LTHAN^ | GTHAN^ | GEQ^ | LEQ^ ) add_expr)*
    ;

eq_expr:
        rel_expr (( EQ^ | NEQ^ ) rel_expr)*
    ;

lmul_expr:
        eq_expr ( LAND^ eq_expr )*
    ;

lor_expr:
        lmul_expr (LOR^ lmul_expr)*
    ;

cond_expr: lor_expr ( QUESTION^ ass_expr COLON! cond_expr)?
    ;


ass_expr: cond_expr ( ( ASSIGN^   
                    | PLUS_ASSIGN^
                    | MINUS_ASSIGN^ 
                    | TIMES_ASSIGN^ 
                    | DIVIDE_ASSIGN^
                    ) ass_expr)?
    ;

expr:   ass_expr
    ;    


lmt:    (expr)? (COLON (expr)?)*
        { #lmt = #( [LMT, "lmt"], #lmt ); }
   ;
        

lmt_list: LPAREN! lmt (COMMA! lmt)*  RPAREN!
          { #lmt_list = #( [LMT_LIST, "lmt_list"], #lmt_list ); }
  ;
// Use vars in dimension list so dims in [] can
// be used with or with out $ prefix. ie "$lon" or "lon" 
// So parser is compatible with ncap1
dmn_list
   :LSQUARE! (VAR_ID|DIM_ID) (COMMA! (VAR_ID|DIM_ID))* RSQUARE!
      { #dmn_list = #( [DMN_LIST, "dmn_list"], #dmn_list ); }
    ;
    
primary_exp
    : (LPAREN! expr RPAREN! ) 
    | BYTE
    | SHORT
    | INT
    | FLOAT    
    | DOUBLE
    | NSTRING    
    | DIM_ID_SIZE
    | ATT_ID_SIZE
    | hyper_slb  //remember this includes VAR_ID & ATT_ID
    | cast_slb
  ;


	  
imaginary_token
	: NRootAST
    ;

class ncoLexer extends Lexer;
options {
    k = 4;
    defaultErrorHandler=false;
    filter=BLASTOUT;
}


tokens {
// token keywords
    IF ="if";
    ELSE="else";
    DEFDIM="defdim";
    SHIFTL="<<";
    SHIFTR=">>";
}
{

private:
    prs_sct *prs_arg;
public:
    // Customized constructor !!
   ncoLexer(ANTLR_USE_NAMESPACE(std)istream& in, prs_sct *prs_in )
   : ANTLR_USE_NAMESPACE(antlr)CharScanner(new ANTLR_USE_NAMESPACE(antlr)CharBuffer(in),true)
   {
        prs_arg=prs_in;
        // This shouldn't really be here 
        // fxm:: should call default constructor
	    initLiterals();
   }



}


ASSIGN: '=';

PLUS_ASSIGN: "+=";

MINUS_ASSIGN: "-=";

TIMES_ASSIGN: "*=";

DIVIDE_ASSIGN: "/=";

INC: "++";

DEC: "--";

QUESTION: '?';

LPAREN:	'(' ;

RPAREN:	')' ;

LCURL : '{' ;

RCURL : '}' ;

LSQUARE: '[';

RSQUARE: ']';

COMMA: ',' ;

QUOTE: '"';

SEMI:	';' ;

COLON: ':' ;

// Operators

CARET: '^' ;

TIMES:	'*' ;

DIVIDE:	'/';

MOD:	'%' ;

PLUS:	'+' ;

MINUS:	'-' ;

EQ: "==" ;

NEQ: "!=" ;


LTHAN:  '<' ;

GTHAN:  '>' ;

LEQ:  "<=" ;

GEQ:  ">=" ;

LAND: "&&" ;

LNOT: '!' ;

LOR: "||" ;


protected DGT:     ('0'..'9');
protected LPH:     ( 'a'..'z' | 'A'..'Z' | '_' );
protected LPHDGT:  ( 'a'..'z' | 'A'..'Z' | '_' | '0'..'9');
protected XPN:     ( 'e' | 'E' ) ( '+' | '-' )? ('0'..'9')+ ;


protected BLASTOUT: .
         {
          // blast out of lexer & parser
          // Can't use RecognitionException() as 
          // this is caught in lexer -- use TokenStreamRecognitionException()
          // instead -- This takes us back to try block in Invoke          

          ostringstream os;
          char ch=LA(0);
          os << getFilename() << " line " << getLine() << ", column "<< getColumn() 
             << ": unexpected character '" << ch << "'" << endl;

          ANTLR_USE_NAMESPACE(antlr)RecognitionException re(os.str());
          throw  ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException(re);
         }  
    ;     


UNUSED_OPS: ( "%=" | "^=" | "&=" | "|=" ) {
  
          ostringstream os;
          os << getFilename() << " line " << getLine() << ", column "<< getColumn() 
             << ": unused operator '" << getText() << "'" << endl;

          ANTLR_USE_NAMESPACE(antlr)RecognitionException re(os.str());
          throw  ANTLR_USE_NAMESPACE(antlr)TokenStreamRecognitionException(re);
         }  
    ;    


// Whitespace -- ignored
Whitespace	
	: ( ' ' |'\t' { tab(); } | '\f' |'\n' { newline(); })
		{ $setType(antlr::Token::SKIP);}
	;

CPP_COMMENT: "//" (~'\n')* '\n'
    { $setType(antlr::Token::SKIP); newline(); }
    ;

C_COMMENT:       
		"/*"
 		( { LA(2) != '/' }? '*'
		        | ( '\r' | '\n' )		{newline();}
                | ~( '*'| '\r' | '\n' )			
                )*
                "*/"                    
        { $setType(antlr::Token::SKIP);}
        ;

// Numbers like .123, .2e3 ,.123f, 0.23d
// csz: Treat "l" or "L" following decimal point as "long double" as per C++
NUMBER_DOT:
      '.' (DGT)+ (XPN)? { $setType(DOUBLE); }  
      ( ('D'|'d')!     {  $setType(DOUBLE);}
       |('F'|'f')!     {  $setType(FLOAT);}
       |('L'|'l')!     {  $setType(DOUBLE);}
      )?        
    ;

NUMBER:
	(DGT)+	{ $setType(INT); }
	( ( '.'  (DGT)* ((XPN)? | ('L'|'l')! )) { $setType(DOUBLE); } // 3.14e0, 3.14L, 3.14l
       | (XPN)         { $setType(DOUBLE);} // 3e0
       | ('L'|'l')!    { $setType(INT);   } // 3l, 3L
       | ('S'|'s')!    { $setType(SHORT); } // 3s, 3S
       | ('B'|'b')!    { $setType(BYTE);  } // 3b, 3B
    )?
    (    ('F'|'f')!    { $setType(FLOAT); } // 3F, 3f
       | ('D'|'d')!    { $setType(DOUBLE);} // 3D, 3d
    )?        
;

// Return var or attribute (var_nm@att_nm)
VAR_ATT:  (LPH)(LPH|DGT)*   
            {// check function table
            if( prs_arg->ptr_sym_vtr->find($getText) !=NULL )
               $setType(FUNC);             
             else $setType(VAR_ID); 
           }   
         (  ('@'(LPH)(LPH|DGT)*  {$setType(ATT_ID); } )
            ( ".size"! { $setType(ATT_ID_SIZE); })?
         )?
;

DIM_VAL: '$'! (LPH)(LPH|DGT)* 
            {$setType(DIM_ID);}
         ( ".size"!  
            { $setType(DIM_ID_SIZE);}
         )? 
   ;  

NSTRING: '"'! ( ~('"'|'\n'))* '"'! {$setType(NSTRING);}
   ;

class ncoTree extends TreeParser;
{

private:
    prs_sct *prs_arg;
    bool bcst;
    var_sct* var_cst;
public:
    void setTable(prs_sct *prs_in){
        prs_arg=prs_in;
    }
    // Customized Constructor
    ncoTree(prs_sct *prs_in){
        prs_arg=prs_in;
        // default is NO. Casting variable set to true 
        // causes casting in function out(). var_cst must 
        // then be defined 
        bcst=false;  
        ncoTree();
    }

public:
    void run(RefAST tr){
        while(tr) {
          (void)statements(tr);   
          tr=tr->getNextSibling();   
        }
    }


int 
lmt_init(
RefAST aRef, 
vector<ast_lmt_sct> &ast_lmt_vtr) 
{
      const std::string fnc_nm("lmt_init"); // [sng] Function name   

      int idx;
      int nbr_dmn;   
      int nbr_cln; // Number of colons in limit
      RefAST lRef;
      RefAST eRef;
      RefAST cRef;
      ast_lmt_sct hyp;

      if(aRef->getType() != LMT_LIST)
         return 0;
    
      lRef=aRef->getFirstChild();

      nbr_dmn=lmt_peek(aRef);      
      //nbr_dmn=lRef->getNumberOfChildren();

      for(idx=0 ; idx < nbr_dmn ; idx++){
         hyp.ind[0]=ANTLR_USE_NAMESPACE(antlr)nullAST;
         hyp.ind[1]=ANTLR_USE_NAMESPACE(antlr)nullAST;
         hyp.ind[2]=ANTLR_USE_NAMESPACE(antlr)nullAST;

             
       if(lRef->getType()!=LMT) 
            return 0;
       
        eRef=lRef->getFirstChild();
        nbr_cln=0;
        
       while(eRef) {
          if(eRef->getType() == COLON){
            cRef=eRef;        
            nbr_cln++;
          }
           eRef=eRef->getNextSibling();
        }
      
      // Initialise  to default markers
       switch(nbr_cln) {
          case 0: 
             break;
                
         case 1: hyp.ind[0]=cRef;
                 hyp.ind[1]=cRef;
                 break;

         case 2: hyp.ind[0]=cRef;
                 hyp.ind[1]=cRef;
                 hyp.ind[2]=cRef;
                 break;

         default: err_prn(fnc_nm,"Too many hyperslab indices");
                  break;  
        }

       eRef=lRef->getFirstChild();
       // point inidices to any expressions that exist
        nbr_cln=0;
       while(eRef) {
          if(eRef->getType() == COLON) 
             nbr_cln++; 
           else   
             hyp.ind[nbr_cln]=eRef;
           
           eRef=eRef->getNextSibling();
       }
       // save indices 
       ast_lmt_vtr.push_back(hyp);

       lRef=lRef->getNextSibling();
     }
     return nbr_dmn;

} 

int 
lmt_mk(
RefAST lmt,
NcapVector<lmt_sct*> &lmt_vtr ) 
{   
int nbr_dmn;
int idx;
int jdx;
long lcl_ind[3];
char *buff;

var_sct *var_out;
lmt_sct *lmt_ptr;
RefAST aRef;

vector<ast_lmt_sct> ast_lmt_vtr;


// populate ast_lmt_vtr
nbr_dmn=lmt_init(lmt,ast_lmt_vtr);

  for(idx=0 ; idx <nbr_dmn ; idx++){


     lcl_ind[0]=-2; lcl_ind[1]=-2; lcl_ind[2]=0; 

    for(jdx=0 ; jdx <3 ; jdx++){

     aRef=ast_lmt_vtr[idx].ind[jdx];

     if(!aRef)
        continue; //do nothing - use default lcl_ind values     
     else if( aRef->getType() == COLON){
       if(jdx <2) lcl_ind[jdx]=-1;
     }else{
         // Calculate number using out()
         var_out=out(aRef);

         // convert result to type int
          var_out=nco_var_cnf_typ(NC_INT,var_out);    
         (void)cast_void_nctype(NC_INT,&var_out->val);

          // only interested in the first value.
         lcl_ind[jdx]=var_out->val.lp[0];

         var_out=nco_var_free(var_out);
        }
     }// end jdx
         
     // fill out lmt structure
     // use same logic as nco_lmt_prs 
     lmt_ptr=(lmt_sct*)nco_calloc((size_t)1,sizeof(lmt_sct));

     lmt_ptr->nm=NULL;
     //lmt_ptr->lmt_typ=-1;
     lmt_ptr->is_usr_spc_lmt=True; /* True if any part of limit is user-specified, else False */
     lmt_ptr->min_sng=NULL;
     lmt_ptr->max_sng=NULL;
     lmt_ptr->srd_sng=NULL;
     /* rec_skp_nsh_spf is used for record dimension in multi-file operators */
     lmt_ptr->rec_skp_nsh_spf=0L; /* Number of records skipped in initial superfluous files */
    
    
    /* Fill in structure */
    if( lcl_ind[0] >= 0) {
          buff=(char*)nco_malloc(20*sizeof(char));
          (void)sprintf(buff, "%ld",lcl_ind[0]);
           lmt_ptr->min_sng=buff; 
    }    

    /* Fill in structure */
    if( lcl_ind[1] >= 0) {
          buff=(char*)nco_malloc(20*sizeof(char));
          (void)sprintf(buff, "%ld",lcl_ind[1]);
           lmt_ptr->max_sng=buff;
    }    

    /* Fill in structure */
    if( lcl_ind[2] > 0) {
          buff=(char*)nco_malloc(20*sizeof(char));
          (void)sprintf(buff, "%ld",lcl_ind[2]);
           lmt_ptr->srd_sng=buff;
    }    

    /* need to deal with situation where only start is defined -- ie picking only a single value */
    if(lcl_ind[0] >=0 && lcl_ind[1]==-2){
          buff=(char*)nco_malloc(20*sizeof(char));
          (void)sprintf(buff, "%ld",lcl_ind[0]);
          lmt_ptr->max_sng=buff; 
    }    


    if(lmt_ptr->max_sng == NULL) lmt_ptr->is_usr_spc_max=False; else lmt_ptr->is_usr_spc_max=True;
    if(lmt_ptr->min_sng == NULL) lmt_ptr->is_usr_spc_min=False; else lmt_ptr->is_usr_spc_min=True;

    lmt_vtr.push(lmt_ptr);


   } // end idx

   return nbr_dmn;

} /* end lmt_mk */



} // end native block




// Return the number of dimensions in lmt subscript
lmt_peek returns [int nbr_dmn=0]

  : lmt:LMT_LIST{
    RefAST aRef;     
    aRef=lmt->getFirstChild();
    nbr_dmn=0;
    while(aRef) {
      if(aRef->getType() == LMT) nbr_dmn++;    
        aRef=aRef->getNextSibling();     
    }   
  }
  ;



statements 
{
var_sct *var;

}
    : blk:BLOCK { 
       run(blk->getFirstChild());
            
                }

    | exp:EXPR {
        
       if(exp->getFirstChild()->getType() == ASSIGN){
          if(dbg_lvl_get() > 0){
             dbg_prn("Type ASSIGN "+exp->getFirstChild()->getFirstChild()->getText());
          }
       }
       var=out(exp->getFirstChild());
       var=nco_var_free(var);
      }
              

    | iff:IF {
      bool br;
      var_sct *var1;
      RefAST ex;      
	  //Calculate logical expression
	  var1= out( iff->getFirstChild());
	  br=ncap_var_lgcl(var1);
	  var1=nco_var_free(var1);

      if(br) { 
         run(iff->getFirstChild()->getNextSibling() );    
	     }else{ 
           // See if else exists 
         ex=iff->getFirstChild()->getNextSibling()->getNextSibling(); 
         if(ex && ex->getType()==ELSE ) run(ex->getFirstChild());
       }
 
      var=(var_sct*)NULL;
      
      }


    | ELSE {

      }
    
    | def:DEFDIM {
            
        const char *dmn_nm;
        long sz;
            
        dmn_nm=def->getFirstChild()->getText().c_str();
            
        var=out(def->getFirstChild()->getNextSibling());    
        var=nco_var_cnf_typ(NC_INT,var);

        (void)cast_void_nctype(NC_INT,&var->val);
        sz=*var->val.lp;
        var=(var_sct*)nco_var_free(var);
        (void)ncap_def_dim(dmn_nm,sz,prs_arg);
     }
             

    | NULL_NODE {
            }
    ;


assign returns [var_sct *var]

   :   (#(ASSIGN  VAR_ID ))=> #(ASSIGN  vid:VAR_ID ){

          const std::string fnc_nm("assign_var"); 

          if(vid->getFirstChild()) {

          switch( vid->getFirstChild()->getType()){
            

            // Deal with LHS hyperslab
            case LMT_LIST:{
               int idx;
               int jdx;
               int rcd;
               int nbr_dmn;
               int var_id; 
               char *var_nm;
               
               RefAST lmt_Ref;
               lmt_sct *lmt_ptr;
               var_sct *var_lhs;
               var_sct *var_rhs;
               NcapVector<lmt_sct*> lmt_vtr;          
               
               lmt_Ref=vid->getFirstChild();

               bcst=false;
               var_cst=(var_sct*)NULL;
               var=(var_sct*)NULL;

              
               var_nm=strdup(vid->getText().c_str());


 
               // if var isn't in ouptut then copy it there
               rcd=nco_inq_varid_flg(prs_arg->out_id,var_nm,&var_id);
               if(rcd != NC_NOERR) {
                 var_lhs=ncap_var_init(var_nm,prs_arg,true);
                 // copy atts to output
                 (void)ncap_att_cpy(vid->getText(),vid->getText(),prs_arg);
                 (void)ncap_var_write(var_lhs,prs_arg);
                 // Get "new" var_id 
                 (void)nco_inq_varid(prs_arg->out_id,var_nm,&var_id);
               } 


               var_lhs=ncap_var_init(var_nm,prs_arg,false);

               nbr_dmn=var_lhs->nbr_dim;

               // Now populate lmt_vtr;
               if( lmt_mk(lmt_Ref,lmt_vtr) == 0){
                  err_prn(fnc_nm,"Invalid hyperslab limits for variable "+ vid->getText());
               }

               if( lmt_vtr.size() != nbr_dmn){
                  err_prn(fnc_nm,"Number of hyperslab limits for variable "+ vid->getText()+" doesn't match number of dimensions");
               }

                // add dim names to dimension list 
               for(idx=0 ; idx < nbr_dmn;idx++) 
                   lmt_vtr[idx]->nm=strdup(var_lhs->dim[idx]->nm);   
        
                
                var_lhs->sz=1;        
                // fill out limit structure
                for(idx=0 ; idx < nbr_dmn ;idx++){
                   (void)nco_lmt_evl(prs_arg->out_id,lmt_vtr[idx],0L,prs_arg->FORTRAN_IDX_CNV);
                    // Calculate size
                   var_lhs->sz *= lmt_vtr[idx]->cnt;
                }
               // Calculate RHS variable                  
               var_rhs=out(vid->getNextSibling());         
               // Convert to LHS type
               var_rhs=nco_var_cnf_typ(var_lhs->type,var_rhs);             
               
               // deal with scalar on RHS first         
               if(var_rhs->sz == 1){
                 // stretch variable to var_lhs->sz                 
                 (void)ncap_att_stretch(var_rhs,var_lhs->sz);
                }

               // make sure var_lhs and var_rhs are the same size
               // and that they are the same shape (ie they conform!!)          
               if(var_rhs->sz != var_lhs->sz){
                 err_prn(fnc_nm, "Hyperslab for "+vid->getText()+" - number of elements on LHS(" +nbr2sng(var_lhs->sz) +  ") doesn't equal number of elements on RHS(" +nbr2sng(var_rhs->sz) +  ")");                                       
                 }

          
              // Now ready to put values 
              {
               long mult_srd=1L;
               long *dmn_srt;
               long *dmn_cnt;
               long *dmn_srd;
    
               dmn_srt=(long *)nco_malloc(nbr_dmn*sizeof(long));
               dmn_cnt=(long *)nco_malloc(nbr_dmn*sizeof(long));
               dmn_srd=(long *)nco_malloc(nbr_dmn*sizeof(long));
    
               for(idx=0;idx<nbr_dmn;idx++){
                 dmn_srt[idx]=lmt_vtr[idx]->srt;
                 dmn_cnt[idx]=lmt_vtr[idx]->cnt;
                 dmn_srd[idx]=lmt_vtr[idx]->srd;
                    mult_srd*=lmt_vtr[idx]->srd;
               } /* end loop over idx */
    
               /* Check for stride */
               if(mult_srd == 1L)
	            (void)nco_put_vara(prs_arg->out_id,var_id,dmn_srt,dmn_cnt,var_rhs->val.vp,var_rhs->type);
               else
	            (void)nco_put_vars(prs_arg->out_id,var_id,dmn_srt,dmn_cnt,dmn_srd,var_rhs->val.vp,var_rhs->type);
    
               dmn_srt=(long *)nco_free(dmn_srt);
               dmn_cnt=(long *)nco_free(dmn_cnt);
               dmn_srd=(long *)nco_free(dmn_srd);
              } // end put block !!

              var_lhs=nco_var_free(var_lhs);
              var_rhs=nco_var_free(var_rhs);

              //get variable again from disk!! for return value
              var=ncap_var_init(var_nm,prs_arg,true);

               
              var_nm=(char*)nco_free(var_nm);

               // Empty and free vector 
              for(idx=0 ; idx < nbr_dmn ; idx++)
                (void)nco_lmt_free(lmt_vtr[idx]);

                } break;

              // Deal with LHS casting 
            case DMN_LIST:{

              var_sct *var1;
              NcapVector<std::string> str_vtr;
              RefAST  aRef;
              

              if(dbg_lvl_get() > 0)
                dbg_prn(fnc_nm,"In ASSIGN/DMN");


              // set class wide variables
              bcst=true;  
              var_cst=(var_sct*)NULL;

              aRef=vid->getFirstChild()->getFirstChild();
         
              // pPut dimension names in vector       
              while(aRef) {
                str_vtr.push(aRef->getText());
                aRef=aRef->getNextSibling();      
              }
              // Cast is applied in VAR_ID action in function out()
              var_cst=ncap_cst_mk(str_vtr,prs_arg);     
              var1=out(vid->getNextSibling());
              
              // Cast isn't applied to naked numbers,
              // or variables of size 1, or attributes
              // so apply it here
              if(var1->sz ==1 )
                  var1=ncap_cst_do(var1,var_cst,prs_arg->ntl_scn);
     
              var1->nm=(char*)nco_free(var1->nm);

              var1->nm =strdup(vid->getText().c_str());

              //Copy return variable
              var=nco_var_dpl(var1);
              
              (void)ncap_var_write(var1,prs_arg);

              bcst=false;
              var_cst=nco_var_free(var_cst); 

             } break;

             }

             
             } else {
               // Set class wide variables
               int var_id;
               int rcd;
               var_sct *var1;
               
               bcst=false;
               var_cst=(var_sct*)NULL; 
               
               var1=out(vid->getNextSibling());
               // Save name 
               std::string s_var_rhs(var1->nm);
               (void)nco_free(var1->nm);                
               var1->nm =strdup(vid->getText().c_str());

               // Do attribute propagation only if
               // var doesn't already exist
               rcd=nco_inq_varid_flg(prs_arg->out_id,var1->nm ,&var_id);

               if(rcd !=NC_NOERR)
                 (void)ncap_att_cpy(vid->getText(),s_var_rhs,prs_arg);

               //Copy return variable
               var=nco_var_dpl(var1);
                
               // Write var to disk
               (void)ncap_var_write(var1,prs_arg);
        
             } // end else 
         
       } // end action
 
   |   (#(ASSIGN  ATT_ID ))=> #(ASSIGN  att:ATT_ID ){

          const std::string fnc_nm("assign_att");
     
          switch( att->getNextSibling()->getType()){
            
            case LMT_LIST:{
                ;
                } break;

            case DMN_LIST:{
                    ;
                }break;

             default: {
                var_sct *var1;
                string sa=att->getText();

                if(dbg_lvl_get() > 0)
                  dbg_prn(fnc_nm,"Saving attribute " +sa);
 
                var1=out(att->getNextSibling());
                (void)nco_free(var1->nm);
                var1->nm=strdup(sa.c_str());

                //var_nw=nco_var_dpl(var);
                NcapVar *Nvar=new NcapVar(sa,var1);
                prs_arg->ptr_var_vtr->push_ow(Nvar);       

                // Copy return variable
                var=nco_var_dpl(var1);    
                  
             } break; 
         } // end switch 
         
       } // end action
   ;
               

out returns [var_sct *var]
{
    const std::string fnc_nm("out"); 
	var_sct *var1;
    var_sct *var2;
}  
    // arithmetic operators 

    :  (#(PLUS out out)) =>  #( PLUS  var1=out var2=out)  
           { var=ncap_var_var_op(var1,var2, PLUS );}
	|  (#(MINUS out out)) => #( MINUS var1=out var2=out)
            { var=ncap_var_var_op(var1,var2, MINUS );}
	|	#(TIMES var1=out var2=out)
            { var=ncap_var_var_op(var1,var2, TIMES );}	
	|	#(DIVIDE var1=out var2=out)	
            { var=ncap_var_var_op(var1,var2, DIVIDE );}
	|	#(MOD var1=out var2=out)
	         {var=ncap_var_var_op(var1,var2, MOD);}
    |   #(CARET var1=out var2=out)
            {var=ncap_var_var_op(var1,var2, CARET);}

    //unary Operators
    |   #(LNOT var1=out )      
            { var=ncap_var_var_op(var1,(var_sct*)NULL, LNOT );}
	|   #(MINUS var1=out )   
            { var=ncap_var_var_op(var1,(var_sct*)NULL, MINUS );}
    |   #(PLUS var1=out ) // do nothing   

    |   #(INC var1=out_asn )      
            { var=ncap_var_var_inc(var1,(var_sct*)NULL, INC,prs_arg);}
    |   #(DEC var1=out_asn )      
            { var=ncap_var_var_inc(var1,(var_sct*)NULL, DEC,prs_arg );}
    
    |   #(POST_INC var1=out_asn )      
            { var=ncap_var_var_inc(var1,(var_sct*)NULL, POST_INC,prs_arg);}
    |   #(POST_DEC var1=out_asn )      
            { var=ncap_var_var_inc(var1,(var_sct*)NULL, POST_DEC,prs_arg );}

    //ternary Operator
    |   #( qus:QUESTION var1=out) {
           bool br;
           br=ncap_var_lgcl(var1);
           var1=nco_var_free(var1);
           if(br) 
             var=out(qus->getFirstChild()->getNextSibling());
           else
             var=out(qus->getFirstChild()->getNextSibling()->getNextSibling());      
         }   
    

    // math functions 
    |  #(m:FUNC var1=out)       
         { 
          sym_sct * sym_ptr;
            
          sym_ptr= prs_arg->ptr_sym_vtr->find(m->getText());
          if(sym_ptr !=NULL)   var=ncap_var_fnc(var1,sym_ptr); 
            else{
              cout << "Function  " << m->getText() << " not found" << endl;
              exit(1);
               } 
          }


    // Logical Operators
    | #(LAND var1=out var2=out)  
            { var=ncap_var_var_op(var1,var2, LAND );}        
    | #(LOR  var1=out var2=out)  
            { var=ncap_var_var_op(var1,var2, LOR );}
    // Comparison Operators
    | #(LTHAN  var1=out var2=out) 
            { var=ncap_var_var_op(var1,var2, LTHAN );}
    | #(GTHAN  var1=out var2=out) 
            { var=ncap_var_var_op(var1,var2, GTHAN );}
    | #(GEQ  var1=out var2=out)   
            { var=ncap_var_var_op(var1,var2, GEQ );}
    | #(LEQ  var1=out var2=out)   
            { var=ncap_var_var_op(var1,var2, LEQ );}
    | #(EQ  var1=out var2=out)    
            { var=ncap_var_var_op(var1,var2, EQ );}
    | #(NEQ  var1=out var2=out)   
            { var=ncap_var_var_op(var1,var2, NEQ );}

    // Assign Operators 
    | #(pls_asn:PLUS_ASSIGN  var1=out_asn var2=out)  
            { var=ncap_var_var_inc(var1,var2, PLUS_ASSIGN , prs_arg);}
	| #(min_asn:MINUS_ASSIGN var1=out_asn var2=out)
            { var=ncap_var_var_inc(var1,var2, MINUS_ASSIGN, prs_arg );}
	| #(tim_asn:TIMES_ASSIGN var1=out_asn var2=out)
            { var=ncap_var_var_inc(var1,var2, TIMES_ASSIGN, prs_arg );}	
	| #(div_asn:DIVIDE_ASSIGN var1=out_asn var2=out)	
            { var=ncap_var_var_inc(var1,var2, DIVIDE_ASSIGN,prs_arg );}	
    | asn:ASSIGN 
            { var=assign(asn); }

    // Naked numbers 
    // nb Cast is not applied to these numbers
	|	c:BYTE		
          {  
            int ival;
            nc_type type=NC_BYTE;
            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_byte");
            var->nbr_dim=0;
            var->sz=1;
            // Get nco type
            ival=atoi(c->getText().c_str());
            var->type=type;
            
            var->val.vp=(void*)nco_malloc(nco_typ_lng(type));
            (void)cast_void_nctype(type,&var->val);
            *var->val.bp = (signed char)ival;
            (void)cast_nctype_void(type,&var->val);
           }

	|	s:SHORT			
          {  
            int ival;
            nc_type type=NC_SHORT;
            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_short");
            var->nbr_dim=0;
            var->sz=1;
            var->type=type;

            ival=atoi(s->getText().c_str());
            var->val.vp=(void*)nco_malloc(nco_typ_lng(type));
            (void)cast_void_nctype(type,&var->val);
            *var->val.sp = ival;
            (void)cast_nctype_void(type,&var->val);

           }
	|	i:INT			
          {  
            int ival;
            nc_type type=NC_INT;
            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_int");
            var->nbr_dim=0;
            var->sz=1;
            // Get nco type
            ival=atoi(i->getText().c_str());
            var->type=type;
            var->val.vp=(void*)nco_malloc(nco_typ_lng(type));
            (void)cast_void_nctype(type,&var->val);
            *var->val.lp = ival;
            (void)cast_nctype_void(type,&var->val);
         }

    |   f:FLOAT        
          {  
            float  fval;
            nc_type type=NC_FLOAT;
            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_float");
            var->nbr_dim=0;
            var->sz=1;
            // Get nco type
            fval=atof(f->getText().c_str());
            var->type=type;
            var->val.vp=(void*)nco_malloc(nco_typ_lng(type));
            (void)cast_void_nctype(type,&var->val);
            *var->val.fp = fval;
            (void)cast_nctype_void(type,&var->val);
           }

    |   d:DOUBLE        
        {  
            double r;
            nc_type type=NC_DOUBLE;
            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_double");
            var->nbr_dim=0;
            var->sz=1;
            // Get nco type
            r=strtod(d->getText().c_str(),(char**)NULL);
            var->type=type;
            var->val.vp=(void*)nco_malloc(nco_typ_lng(type));
            (void)cast_void_nctype(type,&var->val);
            *var->val.dp = r;
            (void)cast_nctype_void(type,&var->val);
         }

     |   str:NSTRING
         {
            char *tsng;
              
            tsng=strdup(str->getText().c_str());
            (void)sng_ascii_trn(tsng);            
            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_zz@string");
            var->nbr_dim=0;
            var->sz=strlen(tsng);
            var->type=NC_CHAR;
            var->val.vp=(void*)nco_malloc(var->sz*nco_typ_lng(NC_CHAR));
            (void)cast_void_nctype(NC_CHAR,&var->val);
            strncpy(var->val.cp,tsng,(size_t)var->sz);  
            (void)cast_nctype_void(NC_CHAR,&var->val);

            tsng=(char*)nco_free(tsng);      

          }

    |   dval:DIM_ID_SIZE
        {
            string sDim=dval->getText();
            dmn_sct *dmn_fd;
            nc_type type=NC_INT;
           
            // check output
            dmn_fd=prs_arg->ptr_dmn_out_vtr->find(sDim);
            
            // Check input
            if(dmn_fd==NULL)
               dmn_fd=prs_arg->ptr_dmn_in_vtr->find(sDim);


            if( dmn_fd==NULL ){
                err_prn(fnc_nm,"Unable to locate dimension " +dval->getText()+ " in input or output files ");
            }

            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_dmn");
            var->nbr_dim=0;
            var->sz=1;
            // Get nco type

            var->type=type;
            var->val.vp=(void*)nco_malloc(nco_typ_lng(type));
            (void)cast_void_nctype(type,&var->val);
            *var->val.lp = dmn_fd->sz;
            (void)cast_nctype_void(type,&var->val);


        }

    |   aval:ATT_ID_SIZE
        {
            long att_sz;
            nc_type type=NC_INT;
            NcapVar *Nvar;

            Nvar=prs_arg->ptr_var_vtr->find(aval->getText());
            if(Nvar !=NULL){
                att_sz=Nvar->var->sz;
            }else{
                var_sct *var_tmp;    
                var_tmp=ncap_att_init(aval->getText(),prs_arg);
                if(var_tmp== (var_sct*)NULL)
                   err_prn(fnc_nm,"Unable to locate attribute " +aval->getText()+ " in input or output files.");
                att_sz=var_tmp->sz;
                var_tmp=nco_var_free(var_tmp);
            }

            var=(var_sct *)nco_malloc(sizeof(var_sct));
            /* Set defaults */
            (void)var_dfl_set(var); 
            /* Overwrite with attribute expression information */
            var->nm=strdup("_att");
            var->nbr_dim=0;
            var->sz=1;
            // Get nco type

            var->type=type;
            var->val.vp=(void*)nco_malloc(nco_typ_lng(type));
            (void)cast_void_nctype(type,&var->val);
            *var->val.lp = att_sz;
            (void)cast_nctype_void(type,&var->val);
        }

    // Variable with argument list 
    |  (#( VAR_ID LMT_LIST)) => #( vid:VAR_ID lmt:LMT_LIST) {

          int idx;
          int nbr_dmn;
          char *var_nm;
          var_sct *var_rhs;
          var_sct *var_nw;
          var_sct *var1;
          dmn_sct *dmn_nw;
         
          NcapVector<lmt_sct*> lmt_vtr;
          NcapVector<dmn_sct*> dmn_vtr;
   
          var_nm=strdup(vid->getText().c_str()); 
          var_rhs=ncap_var_init(var_nm,prs_arg,false);            
          nbr_dmn=var_rhs->nbr_dim;          

          // Now populate lmt_vtr                  
          if( lmt_mk(lmt,lmt_vtr) == 0){
            printf("zero return for lmt_vtr\n");
            nco_exit(EXIT_FAILURE);
          }

         if( lmt_vtr.size() != nbr_dmn){
            err_prn(fnc_nm,"Number of hyperslab limits for variable "+ vid->getText()+" doesn't match number of dimensions");
         }

          // add dim names to dimension list 
          for(idx=0 ; idx < nbr_dmn;idx++)
            lmt_vtr[idx]->nm=strdup(var_rhs->dim[idx]->nm);   
                        
          // fill out limit structure
           for(idx=0 ; idx < nbr_dmn ;idx++)
            (void)nco_lmt_evl(var_rhs->nc_id,lmt_vtr[idx],0L,prs_arg->FORTRAN_IDX_CNV);
           
           // copy lmt_sct to dmn_sct;
           for(idx=0 ;idx <nbr_dmn ; idx++){
              dmn_nw=(dmn_sct*)nco_malloc(sizeof(dmn_sct));
              dmn_nw->nm=strdup(lmt_vtr[idx]->nm);

              // Fudge -if the variable is from input then nco_lmt_evl
              // overwrites the dim id's with their input file values
              // we want the dim ids from output  
              dmn_nw->id=var_rhs->dim[idx]->id;
              //dmn_nw->id=lmt_vtr[idx]->id;
              dmn_nw->cnt=lmt_vtr[idx]->cnt;  
              dmn_nw->srt=lmt_vtr[idx]->srt;  
              dmn_nw->end=lmt_vtr[idx]->end;  
              dmn_nw->srd=lmt_vtr[idx]->srd;  
              dmn_vtr.push(dmn_nw);
           }  
 
          // Fudge -- fill out var again -but using dims defined in dmn_vtr
          // We need data in var so that LHS logic in assign can access var shape 
          var_nw=nco_var_fll(var_rhs->nc_id,var_rhs->id,var_nm, dmn_vtr.ptr(0),dmn_vtr.size());

          // Now get data from disk - use nco_var_get() 
          (void)nco_var_get(var_nw->nc_id,var_nw); 
           
          /* a hack - we set var->has_dpl_dmn=-1 so we know we are dealing with 
             a hyperslabed var and not a regular var  -- It shouldn't cause 
             any abberant behaviour!! */ 

           var_nw->has_dpl_dmn=-1;  

           //if variable is scalar -- re-organize in a  new var - loose extraneous material
           if(var_nw->sz ==1) {
             var1=(var_sct *)nco_malloc(sizeof(var_sct));
             /* Set defaults */
             (void)var_dfl_set(var1); 
             var1->nm=strdup(var_nw->nm);
             var1->nbr_dim=0;
             var1->sz=1;
             var1->type=var_nw->type;

             var1->val.vp=(void*)nco_malloc(nco_typ_lng(var1->type));
             (void)memcpy( (void*)var1->val.vp,var_nw->val.vp,nco_typ_lng(var1->type));
             var_nw=nco_var_free(var_nw);
             var=var1;
            }else{
             var=var_nw;
            }   
            

          if(bcst && var->sz >1)
            var=ncap_cst_do(var,var_cst,prs_arg->ntl_scn);
          
          var_rhs=nco_var_free(var_rhs);

          //free vectors
          for(idx=0 ; idx < nbr_dmn ; idx++){
            (void)nco_lmt_free(lmt_vtr[idx]);
            (void)nco_dmn_free(dmn_vtr[idx]);
          }    
          var_nm=(char*)nco_free(var_nm);

    }
    // plain Variable
	|   v:VAR_ID       
        { 

          char *nm;
          nm =strdup(v->getText().c_str());
          var=ncap_var_init(nm, prs_arg,true);
          if(var== (var_sct*)NULL){
               nco_exit(EXIT_FAILURE);
          }

          var->undefined=False;
          // apply cast only if sz >1 
          if(bcst && var->sz >1)
            var=ncap_cst_do(var,var_cst,prs_arg->ntl_scn);

          // free nm (It is copied in nco_var_fll())
          nm=(char*)nco_free(nm);

        } /* end action */
    // PLain attribute
    |   att:ATT_ID { 
            // check "output"
            NcapVar *Nvar;
            Nvar=prs_arg->ptr_var_vtr->find(att->getText());
            var=(var_sct*)NULL;    
            if(Nvar !=NULL)
                var=nco_var_dpl(Nvar->var);
            else    
                // Check input file for attribute
                var=ncap_att_init(att->getText(),prs_arg);

            if(var== (var_sct*)NULL){
                err_prn(fnc_nm,"Unable to locate attribute " +att->getText()+ " in input or output files.");
            }
             
        }    
;


// Return a var or att WITHOUT applying a cast 
// and checks that the operand is a valid Lvalue
// ie that the var or att has NO children!!
out_asn returns [var_sct *var]
{
const std::string fnc_nm("assign_asn"); 
}

	:   vid:VAR_ID       
        { 
          var=ncap_var_init(vid->getText().c_str(),prs_arg,true);
          if(var== (var_sct*)NULL){
               nco_exit(EXIT_FAILURE);
          }
          var->undefined=False;
         
          if(vid->getFirstChild() !=NULL) {
                err_prn(fnc_nm,"Invalid Lvalue defintion of variable " +vid->getText() );
          }
        } /* end action */
    // Plain attribute
    |   att:ATT_ID { 
            // check "output"
            NcapVar *Nvar;
            Nvar=prs_arg->ptr_var_vtr->find(att->getText());
            var=(var_sct*)NULL;    

            var = (Nvar !=NULL) ?
                  nco_var_dpl(Nvar->var):
                  ncap_att_init(att->getText(),prs_arg);

            if(var== (var_sct*)NULL)
                err_prn(fnc_nm,"Unable to locate attribute " +att->getText()+ " in input or output files");
            
            if(att->getFirstChild() !=NULL) 
                err_prn(fnc_nm,"Invalid Lvalue defintion of attribute " +att->getText() );
            
        }    
;
